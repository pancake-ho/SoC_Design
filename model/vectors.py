"""Generate v9 vectors independently of RTL. Python 3.6+, no numpy."""
import argparse
import hashlib
import json
from pathlib import Path
import random
import sys
from golden import INT32_MAX, INT32_MIN, dot_products, raw_sums, narrow_int32, requant
from workload import X_COUNT, W_COUNT, BIAS_COUNT, OUT_COUNT, X_BASE, W_BASE, BIAS_BASE, NPU_TIMEOUT, FRAME_WORDS
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'sw'))
from programs import isa_program, integration_program, interpret
LANES={'word32':1}
INPUT_BASES={'xq_base':X_BASE,'wq_base':W_BASE,'bias_base':BIAS_BASE}
F07_FRAMES=12
F07_OVERFLOW_RATE=5
F07_MIN_PER_SIGN=2

def random_f07(seed, overflow_rate):
    if type(overflow_rate) is not int or not 0 <= overflow_rate <= 100:
        raise ValueError('overflow rate must be an integer percentage in 0..100')
    schedule=random.Random(seed); payload=random.Random(seed ^ 0xEE470)
    required=dict(zip(schedule.sample(range(F07_FRAMES),4),((1,True),(-1,True),(1,False),(-1,False))))
    frames=[]
    for frame in range(F07_FRAMES):
        if frame in required: direction,satfinite=required[frame]
        else:
            direction=schedule.choice((1,-1)) if schedule.randrange(100)<overflow_rate else 0
            satfinite=bool(schedule.getrandbits(1))
        while True:
            x=[payload.randint(-128,127) for unused in range(X_COUNT)]
            w=[payload.randint(-128,127) for unused in range(W_COUNT)]
            bias=[payload.randint(-100000,100000) for unused in range(BIAS_COUNT)]
            if not direction: break
            # Nine INT8 products alone cannot overflow INT32; choose bias headroom.
            excursion=max(direction*d for d in dot_products(x,w)[:196])
            if excursion > 0:
                headroom=payload.randrange(excursion)
                bias[0]=(INT32_MAX if direction==1 else INT32_MIN)-direction*headroom
                break
        frames.append((x,w,bias,payload.choice((0,1,2,8,15)),bool(payload.getrandbits(1)),satfinite))
    return frames

def validate_profile(path):
    profile=json.loads(Path(path).read_text())
    expected={'schema','mmio_base','constant_base','clock_ns','cpu_transfer_timeout','npu_timeout','seed'}
    optional={'xq_layout','wq_layout'} | set(INPUT_BASES)
    if not expected<=set(profile)<=expected|optional or profile['schema']!='ee470.profile.v2':
        raise ValueError('v9 profile v2 required; old vector/address profiles are incompatible')
    for name in expected-{'schema'}:
        if type(profile[name]) is not int: raise ValueError('integer profile values required')
    m,c=profile['mmio_base'],profile['constant_base']
    if m%32 or c%256 or m<256 or c<256 or m+32>2048 or c+256>2048 or not(m+32<=c or c+256<=m):
        raise ValueError('profile overlap/alignment/range error')
    if profile['clock_ns']!=10 or profile['cpu_transfer_timeout']!=16 or profile['npu_timeout']!=NPU_TIMEOUT:
        raise ValueError('official reference clock/timeout contract changed')
    for name in ('xq_layout','wq_layout'):
        if profile.setdefault(name,'word32')!='word32': raise ValueError(name+' must use common word32 input')
    for name,default in INPUT_BASES.items():
        if type(profile.setdefault(name,default)) is not int or profile[name]!=default:
            raise ValueError(name+' must use fixed v9 offset '+hex(default))
    return profile

def rtl_defines(profile):
    return ['SOC_MMIO_BASE='+str(profile['mmio_base']),'SOC_CONST_BASE='+str(profile['constant_base']),
            'EE470_XQ_LANES=1','EE470_WQ_LANES=1','EE470_XQ_WORD='+str(X_BASE//4),
            'EE470_WQ_WORD='+str(W_BASE//4),'EE470_BIAS_WORD='+str(BIAS_BASE//4),
            'EE470_NPU_TIMEOUT='+str(NPU_TIMEOUT)]

def make_vectors(case, seed, overflow_rate=F07_OVERFLOW_RATE):
    base=([(i%17)-8 for i in range(X_COUNT)],
          [((f+1)*(t+2))%7-3 for f in range(4) for t in range(9)],[-64,0,32,128],2,True,True)
    if case=='F03': return [base,base[:4]+(False,True)]
    if case=='F04':
        return [([int(i==p)*127 for i in range(X_COUNT)],
                 [t-4+f for f in range(4) for t in range(9)],[7,-7,1,-1],2,False,True) for p in (0,17,255)]
    if case=='F05':
        frames=[([-128,127]*128,[-128,127,-1,1,0,3,-7,11,-13]*4,[-1,0,1,2],4,False,True),
                ([1]*256,[1]+[0]*7+[-1]+[0]*27,[INT32_MAX]*4,0,False,True)]
        for sign in (1,-1):
            for satfinite in (True,False):
                frames.append(([sign]*256,[1]*36,[INT32_MAX if sign>0 else INT32_MIN]*4,0,False,satfinite))
        return frames
    if case=='F06':
        return [([0]*256,[0]*36,[b]*4,s,r,True) for b,s,r in
                [(10,2,False),(-10,2,False),(200,0,False),(-200,0,False),
                 (3,1,False),(-3,1,False),(16384,15,False),(-16384,15,False),(-10,2,True)]]
    if case=='F07': return random_f07(seed,overflow_rate)
    return [base]

def generate(out, case, profile, seed=470, custom=None, overflow_rate=F07_OVERFLOW_RATE, replay=None):
    saved=None
    if replay:
        saved=json.loads(Path(replay).read_text())
        if case!='F07' or saved.get('schema')!='ee470.f07.v2' or saved.get('case')!='F07':
            raise ValueError('replay requires v9 F07 snapshot; v8 is incompatible')
        seed,overflow_rate,frames=saved['seed'],saved['overflow_rate_percent'],saved['frames']
        if type(seed) is not int or type(overflow_rate) is not int or not 0<=overflow_rate<=100 or len(frames)!=F07_FRAMES:
            raise ValueError('invalid F07 metadata')
    elif custom:
        value=json.loads(Path(custom).read_text())
        frames=[(v['x'],v['w'],v['bias'],v['shift'],v['relu'],v.get('satfinite',True)) for v in value['frames']]
        if not 1<=len(frames)<=100: raise ValueError('student frames must be 1..100')
    else: frames=make_vectors(case,seed,overflow_rate)
    words=[len(frames)]; overflow={'positive':[],'negative':[]}
    modes={'satfinite':{'positive':0,'negative':0},'wrap':{'positive':0,'negative':0}}
    for number,(x,w,b,s,r,satfinite) in enumerate(frames,1):
        if type(s) is not int or not 0<=s<=15 or type(r) is not bool or type(satfinite) is not bool:
            raise ValueError('invalid shift, ReLU or SATFINITE setting')
        config=(s<<4)|(int(satfinite)<<1)|int(r); sums=raw_sums(x,w,b)
        for sign,condition in (('positive',max(sums)>INT32_MAX),('negative',min(sums)<INT32_MIN)):
            if condition:
                config|=1<<31; overflow[sign].append(number)
                modes['satfinite' if satfinite else 'wrap'][sign]+=1
        raw=[narrow_int32(value,satfinite) for value in sums]; q=[requant(value,s,r) for value in raw]
        words += [config] + [v&255 for v in x+w] + list(b) + raw + [v&255 for v in q]
    encoded=''.join('{:08x}\n'.format(v&0xffffffff) for v in words).encode('ascii')
    vector_hash=hashlib.sha256(encoded).hexdigest()
    if saved is not None and saved.get('vector_sha256')!=vector_hash: raise ValueError('F07 replay checksum mismatch')
    if case=='F07' and any(count==0 for by_sign in modes.values() for count in by_sign.values()):
        raise ValueError('positive/negative overflow in both modes required')
    snapshot=dict(schema='ee470.f07.v2' if case=='F07' else 'ee470.vectors.v2',case=case,seed=seed,
                  frames=frames,shape=[16,16,1,3,3,4],vector_sha256=vector_hash)
    if case=='F07': snapshot['overflow_rate_percent']=overflow_rate
    out=Path(out); out.mkdir(parents=True,exist_ok=False)
    (out/'vectors.hex').write_bytes(encoded); (out/'vectors.json').write_text(json.dumps(snapshot,indent=2)+'\n')
    isa=isa_program(profile['constant_base']); program=integration_program(profile['mmio_base'],profile['constant_base'])
    trace,unused=interpret(isa.assemble(),{profile['constant_base']:0x80000000,
        profile['constant_base']+4:0x7fffffff,profile['constant_base']+8:0x600d})
    for name,p in (('isa',isa),('integration',program)):
        (out/(name+'.hex')).write_text(''.join('{:08x}\n'.format(v) for v in p.assemble()))
        (out/(name+'.s')).write_text('\n'.join('{}: {} {}'.format(4*i,op,', '.join(map(str,args)))
                                              for i,(op,args) in enumerate(p.code))+'\n')
    (out/'isa_trace.hex').write_text('{:08x}\n'.format(len(trace))+''.join('{:08x}\n'.format(v) for row in trace for v in row))
    meta=dict(frames=len(frames),words=len(words),frame_words=FRAME_WORDS,shape=[16,16,1,3,3,4],macs_per_frame=7056,
              isa_words=len(isa.code),isa_trace=len(trace),integration_words=len(program.code),
              cpu_start_pc=program.labels['start_store'],seed=seed,vector_sha256=vector_hash,
              overflow_expected_frames=len(set(overflow['positive']+overflow['negative'])),
              overflow_frame_indices=overflow,overflow_by_mode=modes)
    if case=='F07': meta.update(overflow_rate_percent=overflow_rate,minimum_overflow_per_sign=F07_MIN_PER_SIGN,replayed=saved is not None)
    (out/'metadata.json').write_text(json.dumps(meta,indent=2)+'\n'); return meta

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--case'); parser.add_argument('--out')
    parser.add_argument('--profile',default='config/public_profile.json'); parser.add_argument('--seed',type=int,default=470)
    parser.add_argument('--rtl-defines',action='store_true'); args=parser.parse_args(); profile=validate_profile(args.profile)
    if args.rtl_defines: print(' '.join(rtl_defines(profile)))
    elif not args.case or not args.out: parser.error('--case and --out are required')
    else: print(json.dumps(generate(args.out,args.case,profile,args.seed)))

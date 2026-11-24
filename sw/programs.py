"""Small assembler and independent interpreter for the exact 13-instruction subset."""
import json


def signed(value, bits=32):
    value &= (1 << bits)-1
    return value-(1 << bits) if value & (1 << (bits-1)) else value


class Program:
    def __init__(self):
        self.code, self.labels = [], {}

    def label(self, name):
        if name in self.labels:
            raise ValueError('duplicate label')
        self.labels[name] = 4*len(self.code)

    def emit(self, op, *args):
        self.code.append((op, args))

    def assemble(self):
        words = []
        for index, (op, args) in enumerate(self.code):
            f3 = {'add':0, 'sub':0, 'and':7, 'or':6, 'slt':2,
                  'addi':0, 'andi':7, 'ori':6, 'slti':2, 'lw':2, 'sw':2, 'beq':0}
            if op in ('add','sub','and','or','slt'):
                rd, rs1, rs2 = args
                word = (32 if op=='sub' else 0)<<25 | rs2<<20 | rs1<<15 | f3[op]<<12 | rd<<7 | 0x33
            elif op in ('addi','andi','ori','slti','lw'):
                rd, rs1, imm = args
                if not -2048 <= imm <= 2047:
                    raise ValueError('I immediate out of range')
                word = (imm&4095)<<20 | rs1<<15 | f3[op]<<12 | rd<<7 | (3 if op=='lw' else 0x13)
            elif op=='sw':
                rs2, rs1, imm = args
                if not -2048 <= imm <= 2047:
                    raise ValueError('S immediate out of range')
                word = ((imm&4095)>>5)<<25 | rs2<<20 | rs1<<15 | 2<<12 | (imm&31)<<7 | 0x23
            elif op=='beq':
                rs1, rs2, target = args
                imm = self.labels[target]-4*index
                if imm%2 or not -4096 <= imm <= 4094:
                    raise ValueError('B immediate out of range')
                word = ((imm>>12)&1)<<31 | ((imm>>5)&63)<<25 | rs2<<20 | rs1<<15 | ((imm>>1)&15)<<8 | ((imm>>11)&1)<<7 | 0x63
            elif op=='jal':
                rd, target = args
                imm = self.labels[target]-4*index
                if imm%2 or not -(1<<20) <= imm < (1<<20):
                    raise ValueError('J immediate out of range')
                word = ((imm>>20)&1)<<31 | ((imm>>1)&1023)<<21 | ((imm>>11)&1)<<20 | ((imm>>12)&255)<<12 | rd<<7 | 0x6f
            else:
                raise ValueError('unsupported opcode '+op)
            words.append(word)
        if len(words)>256:
            raise ValueError('program exceeds 256 words')
        return words


def isa_program(constant_base=1536):
    p=Program(); e=p.emit
    for op,args in [('addi',(1,0,7)),('addi',(2,0,-10)),('add',(3,1,2)),('sub',(4,1,2)),
                    ('and',(5,1,4)),('or',(6,1,4)),('slt',(10,2,1)),('andi',(11,4,15)),
                    ('ori',(12,1,16)),('slti',(13,2,-9)),('addi',(0,0,99)),
                    ('addi',(7,0,constant_base)),('lw',(8,7,0)),('lw',(9,7,4)),
                    ('slt',(14,8,9)),('slt',(15,9,8)),('addi',(20,0,64)),
                    ('andi',(21,2,-16)),('ori',(22,1,-32)),('slti',(25,1,-1)),
                    ('addi',(24,0,2)),('add',(26,9,24)),('sub',(27,8,24)),
                    ('sw',(9,20,-16)),('lw',(23,20,-16)),
                    ('sw',(4,0,32)),('lw',(16,0,32))]:
        e(op,*args)
    e('beq',16,4,'taken'); e('sw',0,0,36); p.label('taken')
    e('beq',1,2,'bad'); e('jal',17,'jump'); p.label('bad'); e('sw',0,0,40)
    p.label('jump'); e('addi',28,17,4); e('addi',18,0,3)
    p.label('loop'); e('addi',18,18,-1)
    e('beq',18,0,'exit'); e('beq',18,24,'loop'); e('jal',0,'loop'); p.label('exit')
    e('lw',19,7,8); e('sw',19,0,240); e('jal',0,'exit')
    return p


def interpret(words, memory):
    registers=[None]*32; registers[0]=0; pc=0; trace=[]; memory=dict(memory)
    def reg(index):
        if registers[index] is None:
            raise ValueError('read of uninitialized register')
        return registers[index]
    for unused in range(10000):
        instruction=words[pc//4]; op=instruction&127; rd=instruction>>7&31
        rs1=instruction>>15&31; rs2=instruction>>20&31; f3=instruction>>12&7
        imm=signed(instruction>>20,12); value=0; writes=False; next_pc=pc+4; stop=False
        if op in (0x13,0x33):
            a=reg(rs1); b=reg(rs2) if op==0x33 else imm&0xffffffff
            if f3==0: value=a-b if op==0x33 and instruction>>30&1 else a+b
            elif f3==7: value=a&b
            elif f3==6: value=a|b
            elif f3==2: value=int(signed(a)<signed(b))
            else: raise ValueError('unsupported funct3')
            writes=True
        elif op==3:
            address=(reg(rs1)+imm)&0xffffffff
            if address%4 or address not in memory: raise ValueError('uninitialized/misaligned load')
            value=memory[address]; writes=True
        elif op==0x23:
            imm=signed((instruction>>25)<<5 | (instruction>>7&31),12)
            address=(reg(rs1)+imm)&0xffffffff
            if address%4: raise ValueError('misaligned store')
            memory[address]=reg(rs2); stop=address==240
        elif op==0x63:
            offset=signed((instruction>>31)<<12 | (instruction>>7&1)<<11 | (instruction>>25&63)<<5 | (instruction>>8&15)<<1,13)
            if reg(rs1)==reg(rs2): next_pc=pc+offset
        elif op==0x6f:
            offset=signed((instruction>>31)<<20 | (instruction>>12&255)<<12 | (instruction>>20&1)<<11 | (instruction>>21&1023)<<1,21)
            value=pc+4; writes=True; next_pc=pc+offset
        else: raise ValueError('unsupported opcode')
        target=rd if writes else 0; result=(value&0xffffffff) if target else 0
        trace.append((pc,instruction,target,result))
        if target: registers[target]=result
        if stop: return trace,memory
        pc=next_pc
    raise ValueError('ISA watchdog')


def integration_program(mmio=1024, constants=1536):
    """TB preloads common inputs; CPU starts NPU and reads/checks every output."""
    p=Program(); e=p.emit
    e('addi',8,0,mmio); e('addi',7,0,constants)
    e('lw',3,7,0); e('sw',3,8,8); e('addi',3,0,1)
    p.label('start_store'); e('sw',3,8,0)
    p.label('cnn_poll'); e('lw',3,8,4); e('andi',4,3,4); e('beq',4,0,'cnn_noerr'); e('jal',0,'fail')
    p.label('cnn_noerr'); e('andi',4,3,2); e('beq',4,0,'cnn_poll')
    e('addi',1,0,1536); e('addi',5,0,1568); e('addi',9,0,0)
    p.label('read_output'); e('sw',1,8,12); e('addi',3,0,5); e('sw',3,8,20)
    p.label('read_poll'); e('lw',3,8,24); e('andi',4,3,4); e('beq',4,0,'read_noerr'); e('jal',0,'fail')
    p.label('read_noerr'); e('andi',4,3,2); e('beq',4,0,'read_poll')
    e('lw',2,8,28); e('add',9,9,2); e('addi',1,1,4); e('addi',5,5,-1)
    e('beq',5,0,'compare'); e('jal',0,'read_output')
    p.label('compare'); e('lw',3,7,4); e('beq',9,3,'pass'); e('jal',0,'fail')
    p.label('pass'); e('lw',3,7,8); e('sw',3,0,240); e('jal',0,'pass')
    p.label('fail'); e('lw',3,7,12); e('sw',3,0,240); e('jal',0,'fail')
    return p

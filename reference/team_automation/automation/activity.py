"""Slice a VCD to BUSY..DONE, preserve starting state and rebase time to zero.

This avoids guessing PrimeTime's -time units. It does not add missing activity.
"""
from fractions import Fraction
import re

def clip_vcd(source,destination,start_ps,end_ps):
    if end_ps<=start_ps: raise ValueError('Empty power measurement interval')
    with source.open(errors='strict') as stream, destination.open('x') as out:
        header=[]
        for line in stream:
            header.append(line)
            if '$enddefinitions' in line: break
        header_text=''.join(header)
        m=re.search(r'\$timescale\s+(\d+)\s*(s|ms|us|ns|ps|fs)\s+\$end',header_text)
        if not m: raise ValueError('VCD timescale missing')
        unit={'s':10**12,'ms':10**9,'us':10**6,'ns':1000,'ps':1,'fs':Fraction(1,1000)}
        tick_ps=Fraction(m.group(1))*unit[m.group(2)]
        first,last=Fraction(start_ps)/tick_ps,Fraction(end_ps)/tick_ps
        if first.denominator!=1 or last.denominator!=1: raise ValueError('Checkpoint is not on a VCD tick')
        first,last=int(first),int(last)
        out.write(header_text)
        state={}; time=0; started=False; events=0; max_time=0
        def initial():
            out.write('#0\n$dumpvars\n')
            for value in state.values(): out.write(value+'\n')
            out.write('$end\n')
        for raw in stream:
            line=raw.strip()
            if not line or line.startswith('$'): continue
            if line.startswith('#'):
                time=int(line[1:]); max_time=max(max_time,time)
                if time>first and not started:
                    initial(); started=True
                if time>last: break
                if started: out.write('#'+str(time-first)+'\n')
                continue
            if line[0] in '01xXzZ': identifier=line[1:]
            elif line[0] in 'bBrR': identifier=line.split()[-1]
            else: raise ValueError('Unsupported VCD value: '+line[:80])
            if time<=first: state[identifier]=line
            elif time<=last:
                out.write(line+'\n'); events+=1
        if not started or max_time<last: raise ValueError('VCD does not cover BUSY..DONE')
        out.write('#'+str(last-first)+'\n')
    return dict(start_ps=start_ps,end_ps=end_ps,duration_ps=end_ps-start_ps,
                vcd_tick_ps=str(tick_ps),initial_values=len(state),value_changes=events,
                activity_coverage=None,scope='tb_project/adapter/dut',rebased_to_zero=True)

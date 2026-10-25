"""Compile the actual engine mip reducers and verify all levels against area integration.
Windows: python test_texture_mips.py --cc PATH/clang-cl.exe --out TEMP_DIR
Optional --baseline OLD_gl_texmgr.c demonstrates the pre-fix corruption.
"""
import argparse,ctypes,os,re,subprocess
from pathlib import Path
import numpy as np

def reference(a,axis):
    n=a.shape[axis];size=n//2
    # Integrate piecewise-constant texels over equally spaced output intervals.
    a=np.moveaxis(a,axis,0).astype(np.float64)
    integral=np.concatenate((np.zeros_like(a[:1]),np.cumsum(a,axis=0)))
    edges=np.linspace(0,n,size+1);indices=np.minimum(edges.astype(int),n-1)
    values=integral[indices]+a[indices]*(edges-indices).reshape((-1,)+(1,)*(a.ndim-1))
    out=np.floor(np.diff(values,axis=0)/(n/size)+.500000001).clip(0,255).astype(np.uint8)
    return np.moveaxis(out,0,axis).copy()

def build(src,tag,sse,args,root,env):
    functions=[]
    for axis in ('W','H'):
        functions.append(re.search(r'static unsigned \*TexMgr_MipMap'+axis+r' \([^\n]+\)\n\{.*?\n\}',src,re.S).group())
    code='#include <stddef.h>\n#include <emmintrin.h>\n#include "texture_mip.h"\ntypedef unsigned char byte;\n'+'\n'.join(functions)
    for axis in ('W','H'):
        code+=f'\n__declspec(dllexport) void mip_{axis}(unsigned *p,int w,int h,int d){{TexMgr_MipMap{axis}(p,w,h,d);}}\n'
    c=args.out/(tag+'.c');dll=args.out/(tag+'.dll');c.write_text(code)
    cmd=[str(args.cc),'/nologo','/O2','/LD',str(c),'/I'+str(root/'Quake'),'/Fe:'+str(dll),'/Fo:'+str(args.out/(tag+'.obj'))]
    if sse:cmd+=['/DUSE_SSE2']
    subprocess.run(cmd,cwd=args.out,env=env,check=True,capture_output=True)
    lib=ctypes.CDLL(str(dll))
    for axis in ('W','H'):
        f=getattr(lib,'mip_'+axis);f.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int];f.restype=None
    return lib

def check(lib,w,h,d):
    rng=np.random.default_rng(123);expected=rng.integers(0,256,(d,h,w,4),dtype=np.uint8)
    buf=expected.copy().reshape(-1);levels=0;bad=0
    while w>1 or h>1:
        for axis in (1,2):
            if (h if axis==1 else w)<=1:continue
            expected=reference(expected,axis)
            getattr(lib,'mip_'+('H' if axis==1 else 'W'))(buf.ctypes.data,w,h,d)
            if axis==1:h//=2
            else:w//=2
            actual=buf[:d*h*w*4].reshape(d,h,w,4)
            bad+=np.count_nonzero(actual!=expected)
            if bad:return int(bad)
        levels+=1
    return 0

def main():
    p=argparse.ArgumentParser();p.add_argument('--cc',type=Path,required=True);p.add_argument('--out',type=Path,required=True);p.add_argument('--baseline',type=Path);args=p.parse_args()
    args.out=args.out.resolve();args.out.mkdir(parents=True,exist_ok=True);root=Path(__file__).resolve().parents[2]
    env=os.environ.copy();vswhere=Path(os.environ['ProgramFiles(x86)'])/'Microsoft Visual Studio/Installer/vswhere.exe'
    vs=Path(subprocess.check_output([str(vswhere),'-latest','-products','*','-requires','Microsoft.VisualStudio.Component.VC.Tools.x86.x64','-property','installationPath'],text=True).strip())
    vc=sorted((vs/'VC/Tools/MSVC').iterdir(),key=lambda x:tuple(map(int,x.name.split('.'))))[-1]
    sdk=Path(os.environ['ProgramFiles(x86)'])/'Windows Kits/10';version=sorted((sdk/'Include').iterdir(),key=lambda x:tuple(map(int,x.name.split('.'))))[-1].name
    env['INCLUDE']=';'.join(map(str,[vc/'include']+[sdk/'Include'/version/x for x in ('ucrt','shared','um','winrt')]))
    env['LIB']=';'.join(map(str,[vc/'lib/x64',sdk/'Lib'/version/'ucrt/x64',sdk/'Lib'/version/'um/x64']))
    env['PATH']=str(vc/'bin/Hostx64/x64')+';'+str(args.cc.parent)+';'+env['PATH']
    source=(root/'Quake/gl_texmgr.c').read_text()
    cases=[(1,7,1),(7,1,1),(3,5,3),(6,7,3),(8,8,1),(1019,1544,1),(1254,1254,1),(2172,724,1),(2172,772,1)]
    for sse in (False,True):
        lib=build(source,'fixed_'+str(sse),sse,args,root,env)
        for w,h,d in cases:assert check(lib,w,h,d)==0,(sse,w,h,d)
        print('PASS: '+('SSE2' if sse else 'scalar')+' full mip chains, RGBA, odd rows/columns, layers and real weapon sizes',flush=True)
    if args.baseline:
        lib=build(args.baseline.read_text(),'baseline',True,args,root,env)
        for w,h,d in cases[-4:]:
            bad=check(lib,w,h,d);assert bad>0
            print(f'CONFIRMED original corruption at {w}x{h}: {bad} incorrect channel values',flush=True)
if __name__=='__main__':main()

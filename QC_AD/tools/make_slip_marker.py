from pathlib import Path
import importlib.util,math
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('tome',ROOT/'QC_AD/tools/make_tome_model.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
a=m.mdl.Model((ROOT/'QC_AD/runtime/progs/advr_magic_charge.mdl').read_bytes())
points=[];a.tris=[]
for i in range(32):
 for radius in (12,15):points.append((radius*math.cos(i*math.tau/32),radius*math.sin(i*math.tau/32),0))
for i in range(32):
 j=i*2;k=((i+1)%32)*2
 for a0,b,c in [(j,j+1,k),(j+1,k+1,k)]:a.tris.extend([(1,a0,b,c),(1,a0,c,b)])
a.h[13:15]=[8,8];a.skins=[[0,b'', [bytes([15])*64]]];a.st=[[0,4,4] for p in points]
m.write_mesh(a,points)
(ROOT/'QC_AD/runtime/progs/advr_slip_marker.mdl').write_bytes(a.to_bytes())

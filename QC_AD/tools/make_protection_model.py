from pathlib import Path
import importlib.util,math
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('tome',ROOT/'QC_AD/tools/make_tome_model.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
a=m.mdl.Model((ROOT/'QC_AD/runtime/progs/advr_magic_charge.mdl').read_bytes())
points=[(0,0,0)]+[(20*math.cos(i*math.tau/32),0,20*math.sin(i*math.tau/32)) for i in range(32)]
a.h[13:15]=[8,8];a.skins=[[0,b'', [bytes([15])*64]]];a.st=[[0,4,4] for p in points];a.tris=[]
for i in range(32):
 j=i+1;k=(i+1)%32+1;a.tris.extend([(1,0,j,k),(1,0,k,j)])
m.write_mesh(a,points)
(ROOT/'QC_AD/runtime/progs/advr_shield.mdl').write_bytes(a.to_bytes())

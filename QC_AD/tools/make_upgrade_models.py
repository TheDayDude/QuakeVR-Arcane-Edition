"""Create distinct AD VR upgrade skins without changing calibrated geometry.
Usage: python QC_AD/tools/make_upgrade_models.py PATH_TO_ID1_PAK0
The supplied Quake palette is read locally, not bundled separately.
"""
from pathlib import Path
import sys, struct, shutil, math
root=Path(__file__).resolve().parents[2]
source=root/'quakevr/progs';target=root/'QC_AD/runtime/progs'
pak=Path(sys.argv[1]).read_bytes();magic,off,size=struct.unpack_from('<4sii',pak)
assert magic==b'PACK'
for o in range(off,off+size,64):
 name,start,length=struct.unpack_from('<56sii',pak,o)
 if name.split(b'\0')[0]==b'gfx/palette.lmp':palette=pak[start:start+length];break
else:raise RuntimeError('Quake palette not found')
colors=[tuple(palette[i:i+3]) for i in range(0,768,3)]
# Plasma now comes from AD's g_plasma.mdl via make_plasma_model.py.
variants=[('v_axe','advr_shadowaxe',(0.22,1.0,0.53)),('v_shot2','advr_widowmaker',(1.0,0.50,0.16))]
for original,name,tint in variants:
 data=bytearray((source/(original+'.mdl')).read_bytes())
 n,sw,sh=struct.unpack_from('<3i',data,48);assert n==1
 assert struct.unpack_from('<i',data,84)[0]==0
 start=88;end=start+sw*sh;old=bytes(data[start:end])
 mapping=[]
 for i,c in enumerate(colors):
  if i>=224: mapping.append(i);continue # preserve original muzzle/sight fullbrights
  light=0.2126*c[0]+0.7152*c[1]+0.0722*c[2]
  targetcolor=tuple(min(255,light*1.5*t) for t in tint)
  j=min(range(224),key=lambda j:sum((colors[j][k]-targetcolor[k])**2 for k in range(3)))
  mapping.append(j)
 data[start:end]=bytes(mapping[i] for i in old)
 assert bytes(data[end:])==(source/(original+'.mdl')).read_bytes()[end:]
 changed=sum(a!=b for a,b in zip(old,data[start:end]));assert changed>len(old)*0.1
 (target/(name+'.mdl')).write_bytes(data)
 norm=source/(original+'.mdl_0_norm.png')
 if norm.exists():shutil.copy2(norm,target/(name+'.mdl_0_norm.png'))
 print(name, 'skin texels changed',changed,'/',len(old),'geometry unchanged')

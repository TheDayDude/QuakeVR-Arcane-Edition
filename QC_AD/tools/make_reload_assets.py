from pathlib import Path
import sys,shutil
from PIL import Image
import argparse
parser=argparse.ArgumentParser(description="Build reload assets with QuakeVR upstream 76e28be1 generators; retain the installed SSG HD skin.")
parser.add_argument('upstream',type=Path)
parser.add_argument('quake_pak',type=Path,help='Legal Quake pak0.pak, for palette only')
args=parser.parse_args()
src=Path(__file__).resolve().parents[2];out=src/'QC_AD/runtime';up=args.upstream.resolve()
sys.path.insert(0,str(up/'Misc/quakevr'))
import make_ssg_open as gen
import mdlpolish as mp
gen.PROGS=str(out/'progs');gen.SRC=str(out/'progs/v_shot2.mdl')
gen.build()
names=[]
for n in ['vr_ssg_frame_on_v_shot2.mdl','vr_ssg_barrels_on_v_shot2.mdl']:
 names.append('progs/'+n)
 m=mp.Model(str(out/'progs'/n));base=mp.Model(gen.SRC)
 # Preserve the user's HD artwork exactly over its original UV area. The newly
 # exposed breech uses upstream's authored chamber/cap texels below those rows.
 import struct
 data=args.quake_pak.read_bytes()
 _,offset,size=struct.unpack_from('<4sii',data)
 for at in range(offset,offset+size,64):
  name,start,length=struct.unpack_from('<56sii',data,at)
  if name.rstrip(b'\0')==b'gfx/palette.lmp':palette=data[start:start+length];break
 for skin in range(len(m.skins)):
  im=Image.frombytes('P',(m.sw,m.sh),bytes(m.skin(skin)));im.putpalette(palette);im=im.convert('RGB')
  hd=Image.open(out/'progs/v_shot2.mdl_0.png').convert('RGB');scale=hd.width/m.sw
  result=im.resize((hd.width,round(m.sh*scale)),Image.Resampling.NEAREST)
  result.paste(hd.resize((hd.width,round(base.sh*scale)),Image.Resampling.LANCZOS),(0,0))
  name=f'progs/{n}_{skin}.png';result.save(out/name);names.append(name)
for n in ['reload_ssg_open.wav','reload_ssg_close.wav','reload_ssg_eject.wav']:
 shutil.copy2(up/'quakevr/sound/vr'/n,out/'sound/vr'/n);names.append('sound/vr/'+n)
shutil.copy2(up/'quakevr/progs/vr_shell.mdl',out/'progs/vr_shell.mdl');names.append('progs/vr_shell.mdl')
# Reuse the upstream box-magazine geometry, with shell-brass rather than nail
# steel on the feed area. A separate asset keeps its identity and future tuning.
m=mp.Model(str(out/'progs/vr_mag_snail.mdl'))
for im in m.skins:
 for skin in im[2]:
  for i,c in enumerate(skin):
   if 32<=c<=47:skin[i]=24+(c-32)//2
m.write(str(out/'progs/advr_mag_shell.mdl'));names.append('progs/advr_mag_shell.mdl')

# Match physical/installed ammunition and rotate around the middle of the grip.
for name in ['vr_mag_nail.mdl','vr_mag_snail.mdl','vr_mag_light.mdl','advr_mag_shell.mdl']:
 p=out/'progs'/name;data=bytearray(p.read_bytes());h=list(struct.unpack_from('<4si3f3ff3f8if',data))
 ns,w,height,nv,nt,nf=h[12:18];off=84
 for _ in range(ns):
  assert struct.unpack_from('<i',data,off)[0]==0;off+=4+w*height
 off+=12*nv+16*nt;assert struct.unpack_from('<i',data,off)[0]==0;off+=28
 pos=[[h[5+a]+data[off+4*i+a]*h[2+a] for a in range(3)] for i in range(nv)]
 low=[min(v[a] for v in pos) for a in range(3)];high=[max(v[a] for v in pos) for a in range(3)]
 k=6/(high[2]-low[2])
 for a in range(3):h[2+a]*=k;h[5+a]=(h[5+a]-(low[a]+high[a])/2)*k
 h[8]*=k;struct.pack_into('<4si3f3ff3f8if',data,0,*h);p.write_bytes(data)
shutil.copy2(out/'progs/vr_mag_snail.mdl',out/'progs/vr_mag_nail.mdl')

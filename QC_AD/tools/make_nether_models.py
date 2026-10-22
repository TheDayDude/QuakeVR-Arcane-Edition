"""Build Nether's palm-sized native rune and a double-sided crescent slash mesh.
Usage: python make_nether_models.py GAME/ad
"""
from pathlib import Path
import sys,math
from make_tome_model import asset,mdl,ROOT,write_mesh

def build(ad):
 rune=mdl.Model(asset(ad,'progs/key_rune3.mdl'))
 points=[rune.place(x) for x in rune.pose_bytes()[0]]
 center=[(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)]
 factor=12/max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))
 rune.h[2:5]=[x*factor for x in rune.h[2:5]];rune.h[5:8]=[(rune.h[5+i]-center[i])*factor for i in range(3)];rune.h[8]*=factor;rune.h[19]=0
 (ROOT/'QC_AD/runtime/progs/advr_nether_rune.mdl').write_bytes(rune.to_bytes())
 arc=mdl.Model(rune.to_bytes());arc.h[13:15]=[8,8];arc.skins=[[0,b'',[bytes([224+(i%8)//2 for i in range(64)])]]];points=[];arc.tris=[];arc.st=[]
 for i in range(17):
  angle=-math.pi*.43+i*math.pi*.86/16
  for radius in (23,17):
   points.append((0,radius*math.sin(angle),radius*math.cos(angle)-18))
   arc.st.append([0,i%8,0 if radius==23 else 7])
 for i in range(16):
  a=i*2;b=a+1;c=a+2;d=a+3
  for tri in [(a,b,c),(b,d,c)]:
   arc.tris.append((1,*tri));arc.tris.append((1,*reversed(tri)))
 write_mesh(arc,points);(ROOT/'QC_AD/runtime/progs/advr_nether_arc.mdl').write_bytes(arc.to_bytes())
if __name__=='__main__':build(Path(sys.argv[1]))

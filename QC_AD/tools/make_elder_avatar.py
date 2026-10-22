"""Retarget AD's Fiend surface onto QuakeVR's 29-joint tracked player skeleton.
Usage: python make_elder_avatar.py GAME
Requires numpy and Pillow. Reuses the native skin, leg/tail UVs and geometry;
rebuilds the torso and arms for tracked posing. No generated artwork.
The first-person mesh deliberately contains no head or native detached claws.
"""
from pathlib import Path
import re,sys,shutil
import numpy as np
from PIL import Image
from make_tome_model import asset,mdl,ROOT

def build(game):
 dest=ROOT/'QC_AD/runtime/progs';src=game/'quakevr/progs'
 text=(src/'vrbody.md5mesh').read_text();block=re.search(r'joints \{(.*?)\n\}',text,re.S)[1]
 joints=[]
 for name,parent,pos,quat in re.findall(r'"([^"]+)"\s+(-?\d+)\s+\( ([^)]+) \)\s+\( ([^)]+) \)',block):
  x,y,z=map(float,quat.split());w=-np.sqrt(max(0,1-x*x-y*y-z*z))
  rot=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
  joints.append((name,int(parent),np.array(list(map(float,pos.split()))),rot))
 assert len(joints)==29
 idx={j[0]:i for i,j in enumerate(joints)};jp=lambda n:joints[idx[n]][2]
 m=mdl.Model(asset(game/'ad','progs/mon_demon.mdl'));pts=np.array([m.place(v) for v in m.pose_bytes()[0]])
 labels=list(map(int,re.findall(r'\d+',re.search(r'ad_mon_demonLabels\[\] = \{(.*?)\};',(ROOT/'Quake/vr/vr_ad_rigs.inc').read_text(),re.S)[1])))
 assert len(labels)==len(pts)
 def basis(direction,hint):
  x=direction/np.linalg.norm(direction);z=np.array(hint,dtype=float);z-=x*np.dot(x,z);z/=np.linalg.norm(z);return np.column_stack([x,np.cross(z,x),z])
 def segment(p,a,b,ja,jb,width=.6):
  a=np.array(a);b=np.array(b);d=b-a;t=np.clip(np.dot(p-a,d)/np.dot(d,d),0,1)
  aa=jp(ja);bb=jp(jb);sb=basis(d,[1,0,0]);tb=basis(bb-aa,[1,0,0]);off=sb.T@(p-(a+t*d));off[0]=0
  out=aa+t*(bb-aa)+tb@off*width
  # Two-bone blending avoids detached rigid chunks at knees/elbows.
  blend=float(np.clip((t-.72)/.28,0,1))
  return out,[(idx[ja],1-blend),(idx[jb],blend)]
 def warp(i):
  p=pts[i];x,y,z=p;b=labels[i];side='l' if y>=0 else 'r';sgn=1 if y>=0 else -1
  if b in (3,4,5) or (x>8 and abs(y)>10 and z < -3):
   shoulder=(17,11*sgn,0);elbow=(14,14*sgn,-10);wrist=(13,12*sgn,-18)
   if z>-10:return segment(p,shoulder,elbow,'upperarm_'+side,'forearm_'+side,.6)
   return segment(p,elbow,wrist,'forearm_'+side,'hand_'+side,.6)
  if b in (6,7,8,9,10,11):
   side='l' if b in (6,7,8) else 'r';sgn=1 if side=='l' else -1
   hip=(-1,7*sgn,-5);knee=(-5,8*sgn,-13);ankle=(-2,8*sgn,-19)
   if b in (8,11):return jp('foot_'+side)+np.array([(x+2)*.55,(y-8*sgn)*.55,(z+19)*.32]),[(idx['foot_'+side],1)]
   if b in (6,9):return segment(p,hip,knee,'thigh_'+side,'calf_'+side,.55)
   return segment(p,knee,ankle,'calf_'+side,'foot_'+side,.55)
  if b==12:return jp('pelvis')+np.array([x*.55-3,y*.5,(z+3)*.48]),[(idx['pelvis'],1)]
  # Raise the horizontal monster spine into a player-shaped torso; retain the
  # Fiend's broad chest, muscular surface and tail, but never project a head forward.
  t=float(np.clip((x+3)/19,0,1));out=jp('pelvis')*(1-t)+jp('chest')*t+np.array([-(z+2)*.5,y*.5,0])
  return out,[(idx['pelvis'],1-t),(idx['chest'],t)]
 def hidden(i):
  x,y,z=pts[i];b=labels[i]
  return b in (1,2,3,4,5) or (b==0 and x>5)
 tris=[t for t in m.tris if not any(hidden(i) for i in t[1:])]
 assert len(tris)>100
 # Split seam UVs just as the alias renderer does, preserving the back skin half.
 verts=[];faces=[];lookup={};weights=[];sw,sh=m.skin_size
 for face,*tri in tris:
  ids=[]
  for i in tri:
   seam,ss,tt=m.st[i];uv=((ss+(sw/2 if seam and not face else 0)+.5)/sw,(tt+.5)/sh);key=(i,uv)
   if key not in lookup:
    pos,ws=warp(i);ws=[(j,w) for j,w in ws if w>.00001];start=len(weights)
    for j,w in ws:weights.append((j,w,joints[j][3].T@(pos-joints[j][2])))
    lookup[key]=len(verts);verts.append((uv,start,len(ws),pos))
   ids.append(lookup[key])
  faces.append(ids)
 # Complete the upright upper body with a closed, headless surface. The native
 # quadrupedal chest/head share triangles, so cutting the head alone leaves holes.
 def addvertex(pos,uv,ws):
  start=len(weights)
  for j,w in ws:weights.append((j,w,joints[j][3].T@(pos-joints[j][2])))
  verts.append((uv,start,len(ws),pos));return len(verts)-1
 def tube(rings,uvfunc):
  rows=[]
  for k,(centre,a,b,ws) in enumerate(rings):
   row=[]
   for n in range(13):
    th=n*2*np.pi/12;pos=centre+a*np.cos(th)+b*np.sin(th)
    row.append(addvertex(pos,uvfunc(k,n,th),ws))
   rows.append(row)
  for row,nxt in zip(rows,rows[1:]):
   for n in range(12):faces.extend([[row[n],nxt[n],row[n+1]],[row[n+1],nxt[n],nxt[n+1]]])
  # End caps (clockwise, like alias/MD5 surfaces).
  for row,ring,reverse in [(rows[0],rings[0],False),(rows[-1],rings[-1],True)]:
   c=addvertex(ring[0],uvfunc(0 if not reverse else len(rings)-1,0,0),ring[3])
   for n in range(12):faces.append([c,row[n+1],row[n]] if reverse else [c,row[n],row[n+1]])
 rings=[]
 for z,depth,width,t in [(24.5,2.8,3.5,0),(28.8,3,4.3,.4),(33.6,3.4,5.2,1),(36.8,2.6,5.1,1),(38.0,1.4,2.1,1)]:
  ws=[(idx['pelvis'],1-t),(idx['chest'],t)];ws=[(j,w) for j,w in ws if w>0]
  rings.append((np.array([-.3,0,z]),np.array([depth,0,0]),np.array([0,width,0]),ws))
 tube(rings,lambda k,n,th:((.25 if np.cos(th)>=0 else .75)+.115*np.sin(th),.58-k*.07))
 for side in ['l','r']:
  ja,jb,jc=['upperarm_'+side,'forearm_'+side,'hand_'+side];d=jp(jb)-jp(ja);ax=basis(d,[1,0,0]);rings=[]
  for centre,radius,ws in [(jp(ja),2.3,[(idx[ja],1)]),(jp(ja)*.5+jp(jb)*.5,2.0,[(idx[ja],1)]),(jp(jb),1.6,[(idx[ja],.5),(idx[jb],.5)]),(jp(jb)*.5+jp(jc)*.5,1.35,[(idx[jb],1)]),(jp(jc),1,[(idx[jc],1)])]:
   # Ring basis follows the arm direction to retain outward winding.
   rings.append((centre,ax[:,1]*radius,ax[:,2]*radius,ws))
  tube(rings,lambda k,n,th:(.055+.055*n/12,.23+k*.065))
 fmt=lambda p:' '.join(f'{x:.6f}' for x in p)
 lines=['MD5Version 10','commandline "make_elder_avatar.py"','numJoints 29','numMeshes 1','joints {'+block+'\n}','mesh {','shader "advr_fiend_body"',f'numverts {len(verts)}']
 lines += [f'vert {i} ( {fmt(uv)} ) {start} {count}' for i,(uv,start,count,p) in enumerate(verts)]
 lines += [f'numtris {len(faces)}']+[f'tri {i} '+ ' '.join(map(str,t)) for i,t in enumerate(faces)]
 lines += [f'numweights {len(weights)}']+[f'weight {i} {j} {w:.6f} ( {fmt(p)} )' for i,(j,w,p) in enumerate(weights)]+['}']
 (dest/'advr_fiend_body.md5mesh').write_text('\n'.join(lines)+'\n')
 shutil.copy2(src/'vrbody.md5anim',dest/'advr_fiend_body.md5anim')
 # Reuse the native Fiend skin and UVs for the skeletal replacement.
 pal=asset(game/'id1','gfx/palette.lmp');im=Image.frombytes('P',(sw,sh),m.skins[0][2][0]);im.putpalette(pal);im.convert('RGB').save(dest/'advr_fiend_body_00_00.tga')
 rest=np.array([p for uv,start,count,p in verts]);assert rest[:,2].max()<40,'head/view clearance'
 print('Fiend avatar:',len(verts),'vertices,',len(faces),'triangles,',len(weights),'weights; bounds',rest.min(0),rest.max(0))

if __name__=='__main__':build(Path(sys.argv[1]))

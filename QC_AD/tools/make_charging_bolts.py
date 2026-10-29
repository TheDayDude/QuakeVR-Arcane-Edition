"""Append editable, integrated bolt assemblies to freshly generated held models.

Run AFTER make_classic_vr_models.py and make_plasma_model.py. Never run twice
on already expanded models. Body topology/UVs and each original animation are
preserved. Frame = original + original_count * (pull_step + 16 * left_hand).
The left-hand bank reflects ONLY the bolt, cancelling the renderer's mirror.
The JSON report records mesh ranges and dimensions for subsequent hand edits.
"""
from pathlib import Path
import importlib.util, math, json, wave, struct
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('mdl',ROOT/'Misc/quakevr/blender/addons/quakevr_models/mdl.py')
mdl=importlib.util.module_from_spec(spec);spec.loader.exec_module(mdl)
SPECS={
 'advr_base_nail': ((3.6776,-2.736,.446),32,'round knurled knob'),
 'advr_base_nail2': ((5.2328,-3.1104,.032),32,'wide stepped lever'),
 'advr_base_light': ((1.185104,-3.224520,-.279400),32,'ribbed capacitor T-handle'),
 'advr_widowmaker': ((3.,-2.7,1.),1,'pierced loop charging lever'),
 'advr_plasma': ((2.,-2.7,1.),1,'forked energy-cell lever'),
}

def build(name,home,count,design):
 path=ROOT/'QC_AD/runtime/progs'/f'{name}.mdl';m=mdl.Model(path.read_bytes())
 assert len(m.frames)==count, 'Regenerate the base models before adding bolts'
 old=m.pose_bytes();body=[[m.place(v) for v in p] for p in old]
 nv=len(m.st);nt=len(m.tris);order=mdl.strip_order(m.tris)
 points=[];normals=[];moving=[];parts=[]
 # Sample existing receiver metal; do not change or expand any source skin.
 near=min(range(nv),key=lambda i:sum((body[0][i][a]-home[a])**2 for a in range(3)))
 uv=m.st[near]
 def face(vs,n,move):
  start=nv+len(points);points.extend(vs);normals.extend([mdl.nearest_normal(n)]*len(vs));moving.extend([move]*len(vs))
  # Reuse a small textured receiver patch instead of stretching one flat texel.
  axes=sorted(range(3),key=lambda a:max(v[a] for v in vs)-min(v[a] for v in vs),reverse=True)[:2]
  limits=[(min(v[a] for v in vs),max(v[a] for v in vs)) for a in axes]
  for v in vs:
   st=[0]
   for j,a in enumerate(axes):
    lo,hi=limits[j];f=(v[a]-lo)/max(hi-lo,.001)
    st.append(max(0,min(m.h[13+j]-1,round(uv[1+j]+(f-.5)*10))))
   m.st.append(tuple(st))
  # Quake uses clockwise faces viewed from outside.
  for i in range(1,len(vs)-1):m.tris.append((1,start,start+i+1,start+i))
 def box(label,lo,hi,move=True):
  start=nv+len(points);x,y,z=lo;X,Y,Z=hi
  face([(x,y,z),(x,y,Z),(x,Y,Z),(x,Y,z)],(-1,0,0),move)
  face([(X,y,z),(X,Y,z),(X,Y,Z),(X,y,Z)],(1,0,0),move)
  face([(x,y,z),(X,y,z),(X,y,Z),(x,y,Z)],(0,-1,0),move)
  face([(x,Y,z),(x,Y,Z),(X,Y,Z),(X,Y,z)],(0,1,0),move)
  face([(x,y,z),(x,Y,z),(X,Y,z),(X,y,z)],(0,0,-1),move)
  face([(x,y,Z),(X,y,Z),(X,Y,Z),(x,Y,Z)],(0,0,1),move)
  parts.append(dict(name=label,first_vertex=start,vertex_count=nv+len(points)-start,moving=move))
 x,y,z=home
 # Fixed receiver sleeve and sliding bolt overlap: no floating handle.
 box('receiver sleeve',(x-3.2,y+.45,z-.45),(x+2.1,y+1.65,z+.45),False)
 box('sliding bolt',(x-1.4,y+.25,z-.25),(x+3.0,y+1.2,z+.25))
 box('handle stem',(x-.22,y-.18,z-.18),(x+.22,y+.8,z+.18))
 if name.endswith('_nail'):
  # Octagonal knob with two raised collars.
  for j,(a,b,radius) in enumerate([(y-.65,y-.50,.45),(y-.50,y-.1,.34),(y-.1,y+.05,.45)]):
   start=nv+len(points)
   for k in range(8):
    q=2*math.pi*k/8;t=2*math.pi*(k+1)/8
    face([(x+radius*math.cos(q),a,z+radius*math.sin(q)),(x+radius*math.cos(q),b,z+radius*math.sin(q)),(x+radius*math.cos(t),b,z+radius*math.sin(t)),(x+radius*math.cos(t),a,z+radius*math.sin(t))],(math.cos((q+t)/2),0,math.sin((q+t)/2)),True)
   for yy,n,reverse in [(a,(0,-1,0),False),(b,(0,1,0),True)]:
    vs=[(x+radius*math.cos(k*math.pi/4),yy,z+radius*math.sin(k*math.pi/4)) for k in range(8)]
    face(vs[::-1] if reverse else vs,n,True)
   parts.append(dict(name=f'knob {j}',first_vertex=start,vertex_count=nv+len(points)-start,moving=True))
 elif name.endswith('_widowmaker'):
  # Open rectangular loop: a compact mechanical lever distinct from energy guns.
  box('loop upper rail',(x-.7,y-.72,z+.18),(x+.7,y-.3,z+.4))
  box('loop lower rail',(x-.7,y-.72,z-.65),(x+.7,y-.3,z-.43))
  box('loop rear upright',(x-.7,y-.72,z-.43),(x-.48,y-.3,z+.18))
  box('loop front upright',(x+.48,y-.72,z-.43),(x+.7,y-.3,z+.18))
 elif name.endswith('_light'):
  # Broad insulated T-grip with three raised ribs, distinct from the other guns.
  box('capacitor T-grip',(x-.8,y-.65,z-.32),(x+.8,y-.15,z+.32))
  for j in (-1,0,1):
   box('insulator rib '+str(j),(x+j*.5-.09,y-.72,z-.39),(x+j*.5+.09,y-.10,z+.39))
 elif name.endswith('_nail2'):
  box('wide lever',(x-.65,y-.4,z-.28),(x+.65,y+.05,z+.28))
  box('raised finger lip',(x-.65,y-.48,z-.28),(x-.4,y+.05,z+.7))
 else:
  box('rear fork',(x-.65,y-.5,z-.25),(x-.38,y+.1,z+.5))
  box('front fork',(x+.38,y-.5,z-.25),(x+.65,y+.1,z+.5))
  box('crossbar',(x-.65,y-.55,z+.25),(x+.65,y-.3,z+.5))
 assert mdl.strip_order(m.tris)[:len(order)]==order, 'Existing muzzle/display anchors must keep their strip indices'
 # Both mirror banks need identical winding. Reflect each face's vertex order
 # in the pose bank as well as its Y coordinates; normals reflect Y too.
 # Face-local vertices let us reverse winding without changing global topology.
 # Every generated face has private vertices; record ranges from repeated normals.
 # Reflecting Y plus reversing each face's positions keeps the outward winding.
 face_groups=[];used=set()
 for tri in m.tris[nt:]:
  a=tri[1]-nv
  if a not in used:
   ids=sorted({i-nv for t in m.tris[nt:] if t[1]-nv==a for i in t[1:]})
   used.add(a);face_groups.append(ids)
 reflected=list(range(len(points)))
 for ids in face_groups:
  for a,b in zip(ids,ids[:1]+list(reversed(ids[1:]))):reflected[a]=b
 allpoints=[p for pose in body for p in pose]
 for mirror in (False,True):
  for pull in (0,1):
   allpoints.extend((p[0]-3*pull*move,-p[1] if mirror else p[1],p[2]) for p,move in zip(points,moving))
 lo=[min(p[a] for p in allpoints) for a in range(3)];hi=[max(p[a] for p in allpoints) for a in range(3)]
 scale=[(hi[a]-lo[a])/255 for a in range(3)]
 m.h[2:5]=scale;m.h[5:8]=lo;m.frames=[]
 def pack(p,n):return bytes([max(0,min(255,round((p[a]-lo[a])/scale[a]))) for a in range(3)]+[n])
 for mirror in (False,True):
  for step in range(16):
   extra=bytearray()
   for j in range(len(points)):
    k=reflected[j] if mirror else j;p=points[k];n=normals[k]
    if mirror:
     normal=mdl.anorms()[n];n=mdl.nearest_normal((normal[0],-normal[1],normal[2]))
    extra+=pack((p[0]-3*step/15*moving[k],-p[1] if mirror else p[1],p[2]),n)
   for f in range(count):
    packed=b''.join(pack(p,v[3]) for p,v in zip(body[f],old[f]))+extra
    header=bytes([0,0,0,0,255,255,255,0])+f'b{int(mirror)}p{step}f{f}'.encode().ljust(16,b'\0')
    m.frames.append(['simple',header,packed])
 m.h[15]=len(m.st);m.h[8]=max(math.sqrt(sum(x*x for x in p)) for p in allpoints)
 path.write_bytes(m.to_bytes())
 return dict(design=design,home=home,travel=3,original_frames=count,frames=len(m.frames),body_vertices=nv,body_triangles=nt,parts=parts)

def sounds():
 folder=ROOT/'QC_AD/runtime/sound/vr'
 # Split the existing cocking sample into its opening and closing actions.
 with wave.open(str(folder/'reload_full.wav'),'rb') as w:
  params=w.getparams();data=w.readframes(w.getnframes())
 assert params.sampwidth==2
 samples=struct.unpack('<'+'h'*(len(data)//2),data);channels=params.nchannels
 # Find the quiet valley between the two central mechanical transients.
 frames=params.nframes;window=max(1,int(params.framerate*.01))
 candidates=range(int(frames*.3),int(frames*.7),window)
 split=min(candidates,key=lambda f:sum(abs(v) for v in samples[f*channels:(f+window)*channels]))
 for name,start,end in [('bolt_pull',0,split),('bolt_release',split,frames)]:
  chunk=list(samples[start*channels:end*channels]);fade=min(int(params.framerate*.003),len(chunk)//channels//2)
  for i in range(fade):
   for c in range(channels):
    chunk[i*channels+c]=int(chunk[i*channels+c]*i/fade)
    j=len(chunk)-(i+1)*channels+c;chunk[j]=int(chunk[j]*i/fade)
  with wave.open(str(folder/(name+'.wav')),'wb') as w:
   w.setparams(params);w.writeframes(struct.pack('<'+'h'*len(chunk),*chunk))

if __name__=='__main__':
 report={n:build(n,*args) for n,args in SPECS.items()}
 (ROOT/'QC_AD/tools/charging-bolts.json').write_text(json.dumps(report,indent=2)+'\n')
 sounds();print(json.dumps({n:v['frames'] for n,v in report.items()}))

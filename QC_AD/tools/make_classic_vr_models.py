"""Build articulated VR weapons from AD pickups and the original VR shotgun.

Run with the installed AD directory. Native UVs/skins are preserved. Magazines
are extracted from the actual mesh; poses 16..31 hide them without changing UVs.
No external model package or image generation is required.
"""
from pathlib import Path
import sys,copy,math,json
from make_tome_model import asset,mdl,write_mesh,ROOT

# Source-space grip centers measured on the original meshes. Positive X is forward.
SPECS={
 'shot':dict(source='g_shot1',slot=1,grip=(-5,0,32.5),support=(9,0,33),muzzle=(19,0,36.5),scale=.8,port=(-1,0,32.5)),
 'nail':dict(source='g_nail',slot=3,grip=(-7.4,0,27.5),support=(8,0,31.5),muzzle=(16.5,0,34.5),scale=.95,mag=[6,20],port=(2.47,0,29.98),charge=(-1,-4,34)),
 'nail2':dict(source='g_nail2',slot=4,grip=(-15.3,0,27),support=(8,0,28),muzzle=(22.5,0,32.74),scale=.8,mag=[35,36,37,38,39],port=(-.11,-.02,28.32),charge=(-5,-5.4,34)),
 'rock':dict(source='g_rock',slot=5,grip=(-7.3,0,28),support=(7.3,0,27.3),muzzle=(17.5,0,32.8),scale=.9),
 'rock2':dict(source='g_rock2',slot=6,grip=(-13.5,0,27.5),support=(10.4,0,27),muzzle=(26,0,32.9),scale=.8),
 'light':dict(source='g_light',slot=7,grip=(-3.8,0,26.5),support=(11,0,29.2),muzzle=(21,0,35.7),scale=.689,mag=[27,32,34,46,47],port=(4.37,-.03,30.71),charge=(0,-6.5,34)),
}
# The palm wraps below the tracked origin, as on the existing Plasma Gun.
# Scale the entire native mesh uniformly: no shortened stocks or lost detail.
PALM=(-.7,0.,-4.)
for spec in SPECS.values():spec['scale'] *= .72
SPECS['nail']['support']=(5.8,0,30.5)
SPECS['nail2']['support']=(4.3,0,28.7)
# Small headset-tested corrections in final model units; +X is toward the muzzle.
GRIP_TRIM={'shot':(-.45,0,0),'nail':(0,0,.45),'nail2':(0,0,.45),
 'rock':(-.5,0,.4),'rock2':(-.5,0,.4),'light':(-.7,0,0)}

def add_box(m,p,lo,hi,uv):
 base=len(p)
 p.extend((x,y,z) for x in (lo[0],hi[0]) for y in (lo[1],hi[1]) for z in (lo[2],hi[2]))
 m.st.extend([[0,*uv] for _ in range(8)])
 for a,b,c in [(0,1,3),(0,3,2),(4,6,7),(4,7,5),(0,4,5),(0,5,1),(2,3,7),(2,7,6),(0,2,6),(0,6,4),(1,5,7),(1,7,3)]:
  m.tris.append((1,base+a,base+c,base+b))

# Standardized grasp envelope, matching the original QuakeVR shotgun grip.
HANDLE_SIZE=(2.5,1.3,3.8)
HANDLE_PARTS={'nail':[27,36,37,60,61],'nail2':[8,9,10,31,33,34],
 'rock':[27,28,29,30,31],'rock2':[19,20,21,22,23],'light':[33,42,43,44,51]}
HANDLE_TOP={'nail':28.52,'nail2':29.08,'rock':30.43,'rock2':29.89,'light':29.94}

def fit_handle(p,native,groups,name,point):
 ids=[i for c in HANDLE_PARTS[name] for i in groups[c] if native[i][2]<=HANDLE_TOP[name]+.01]
 lo=[min(p[i][a] for i in ids) for a in range(3)];hi=[max(p[i][a] for i in ids) for a in range(3)]
 center=[(lo[a]+hi[a])/2 for a in range(3)]
 # Keep the mounting height, but normalize the handle below it. Vertices above
 # the mounting plane belong to the receiver and are intentionally untouched.
 center[2]=hi[2]-HANDLE_SIZE[2]/2
 # Components share positions across UV seams. Move every duplicate together,
 # and blend back to the unchanged receiver at the attachment plane.
 bottom=[p[i] for i in ids if p[i][2]<lo[2]+.4*(hi[2]-lo[2])]
 bx0=min(v[0] for v in bottom);bx1=max(v[0] for v in bottom)
 shaft=(bx0+bx1)/2
 assert bx1-bx0>1, (name,'degenerate grip cross section')
 center[0]=shaft+.25*HANDLE_SIZE[2]/2
 changes={}
 for i in ids:
  x,y,z=p[i];depth=(hi[2]-z)/(hi[2]-lo[2]);blend=min(1.,depth*3)
  cx=shaft+.25*(z-lo[2])
  nx=cx+(x-cx)*(1+(HANDLE_SIZE[0]/max(.1,bx1-bx0)-1)*blend)
  ny=center[1]+(y-center[1])*(1+(HANDLE_SIZE[1]/(hi[1]-lo[1])-1)*blend)
  changes[tuple(native[i])]=(nx,ny,hi[2]-depth*HANDLE_SIZE[2])
 for i,v in enumerate(native):
  if tuple(v) in changes:p[i]=changes[tuple(v)]
 return tuple(center)

def shotgun():
 m=mdl.Model((ROOT/'QC_AD/runtime/progs/v_shot.mdl').read_bytes())
 native=[m.place(v) for v in m.pose_bytes()[0]]
 def point(v):
  x,y,z=v
  if x>18:x=18+(x-18)*1.5
  return ((x-3.2)*.44-.7,y*.44,(z+2)*.44-4)
 p=[point(v) for v in native]
 # An attached shoulder stock behind the receiver; the original pistol grip,
 # trigger, fore-end and sights are untouched. Reuse receiver wood UVs.
 start=len(p)
 p.extend(point(v) for v in [(1.4,-1.3,1.5),(1.4,1.3,1.5),(1.4,1.3,4.8),(1.4,-1.3,4.8),
                            (-17,-2,-2),(-17,2,-2),(-17,2,5),(-17,-2,5)])
 uv=[[0,s,t] for s,t in [(60,132),(60,132),(60,158),(60,158),(4,132),(4,132),(4,158),(4,158)]]
 m.st.extend(uv)
 for a,b,c in [(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),(3,7,6),(3,6,2),(0,4,7),(0,7,3),(1,2,6),(1,6,5)]:
  m.tris.append((1,start+a,start+b,start+c))
 return m,p,point

def add_details(m,p,name,front):
 return max(v[2] for v in p)+.65

def components(m):
 parent=list(range(len(m.st)))
 def find(i):
  while parent[i]!=i:i=parent[i]
  return i
 for _,a,b,c in m.tris:
  for i in (b,c):parent[find(i)]=find(a)
 groups={}
 for i in range(len(parent)):groups.setdefault(find(i),[]).append(i)
 return sorted(groups.values(),key=lambda g:-len(g))
def subset(m,p,vertices):
 out=copy.deepcopy(m);ix=sorted(vertices);remap={v:i for i,v in enumerate(ix)}
 out.st=[m.st[i] for i in ix];out.tris=[(f,remap[a],remap[b],remap[c]) for f,a,b,c in m.tris if a in vertices and b in vertices and c in vertices]
 write_mesh(out,[p[i] for i in ix]);return out
def poses(m,points,variants,rotating=()):
 allp=[v for pose in variants for v in pose];lo=[min(v[i] for v in allp) for i in range(3)];hi=[max(v[i] for v in allp) for i in range(3)]
 scale=[max(.001,(hi[i]-lo[i])/255) for i in range(3)];m.h[2:5]=scale;m.h[5:8]=lo
 normal=[v[3] for v in m.pose_bytes()[0]];m.frames=[]
 for f,p in enumerate(variants):
  ns=list(normal)
  if rotating:
   angle=(f%16)*math.pi/16
   for j in rotating:
    x,y,z=mdl.anorms()[normal[j]];ns[j]=mdl.nearest_normal((x,y*math.cos(angle)-z*math.sin(angle),y*math.sin(angle)+z*math.cos(angle)))
  packed=b''.join(bytes([max(0,min(255,round((v[i]-lo[i])/scale[i]))) for i in range(3)]+[ns[j]]) for j,v in enumerate(p))
  m.frames.append(['simple',bytes([0,0,0,0,255,255,255,0])+('pose%d'%f).encode().ljust(16,b'\0'),packed])
def main(folder):
 out=ROOT/'QC_AD/runtime/progs';settings=[];ports=[];sights=[];report={}
 (out/'advr_base_shot.mdl_0.png').write_bytes((out/'v_shot.mdl_0.png').read_bytes())
 for name,s in SPECS.items():
  m=mdl.Model(asset(folder,'progs/'+s['source']+'.mdl'));original=copy.deepcopy(m);groups=components(m)
  native=[m.place(v) for v in m.pose_bytes()[0]]
  def point(v):return tuple((v[i]-s['grip'][i])*s['scale']+PALM[i] for i in range(3))
  p=[point(v) for v in native]
  grip=fit_handle(p,native,groups,name,point) if name!='shot' else PALM
  if name=='shot':
   m,p,point=shotgun();original=mdl.Model((ROOT/'QC_AD/runtime/progs/v_shot.mdl').read_bytes());native=[original.place(v) for v in original.pose_bytes()[0]]
   s=dict(s,support=(22,0,-.2),muzzle=(33.06,0,4.2),port=(13,0,-.8))
  grip=tuple(grip[i]+GRIP_TRIM.get(name,(0,0,0))[i] for i in range(3))
  support=list(point(s['support']))
  # Vertical foregrips use their shaft centers and the hand's grip channel.
  if name=='shot':support=[9.,0.,-2.1]
  if name=='rock':support=[8.77,0.,-4.5]
  if name=='rock2':support=[13.09,0.,-4.21]
  mag=set(i for c in s.get('mag',[]) for i in groups[c])
  port=point(s.get('port',s['muzzle']));charge=point(s['charge']) if 'charge' in s else (0,0,0)
  if mag:
   # Top-center is origin for the socket, but the loose prop rotates about its center.
   low=[min(p[i][a] for i in mag) for a in range(3)];high=[max(p[i][a] for i in mag) for a in range(3)]
   center=[(low[a]+high[a])/2 for a in range(3)]
   mp=[tuple(v[a]-center[a] for a in range(3)) for v in p]
   mm=subset(m,mp,mag)
   # The source's magazine top is hidden in its receiver. Close the extracted
   # loose prop using its existing metal texel rather than leaving an open mesh.
   q=[mm.place(v) for v in mm.pose_bytes()[0]];base=len(q)
   lx,ly,lz=[min(v[a] for v in q) for a in range(3)];hx,hy,hz=[max(v[a] for v in q) for a in range(3)]
   q.extend([(lx,ly,hz),(hx,ly,hz),(hx,hy,hz),(lx,hy,hz)])
   mm.st.extend([list(mm.st[0]) for _ in range(4)]);mm.tris.extend([(1,base,base+2,base+1),(1,base,base+3,base+2)])
   write_mesh(mm,q);(out/f'advr_base_mag_{name}.mdl').write_bytes(mm.to_bytes())
  sightz=add_details(m,p,name,point(s['muzzle'])[0])
  write_mesh(m,p);variants=[]
  for f in range(32 if mag else 1):
   pp=list(p)
   if name=='nail2':
    # Rotate the four complete barrels about their shared axle; keep the receiver fixed.
    cy,cz=point((0,-.02,32.74))[1:];a=(f%16)*math.pi/16
    for i,v in enumerate(native):
     if v[0]>5.4 and i not in mag:
      x,y,z=p[i];pp[i]=(x,cy+(y-cy)*math.cos(a)-(z-cz)*math.sin(a),cz+(y-cy)*math.sin(a)+(z-cz)*math.cos(a))
   if f>=16:
    for i in mag:pp[i]=port
   variants.append(pp)
  rotating=[i for i,v in enumerate(native) if v[0]>5.4 and i not in mag] if name=='nail2' else []
  poses(m,p,variants,rotating);(out/f'advr_base_{name}.mdl').write_bytes(m.to_bytes())
  order=mdl.strip_order(m.tris);actual=[m.place(v) for v in m.pose_bytes()[0]]
  # Attach UI/muzzle markers to the stationary receiver, not a removable mag
  # or a spinning barrel vertex. The local offset reaches the desired point.
  stable=[i for i,v in enumerate(order) if v not in mag and v not in rotating]
  st=dict(Scale=1,OffsetX=0,OffsetY=0,OffsetZ=0,Pitch=0,Yaw=0,Roll=0,ShotPitch=0,ShotYaw=0,HandOnlyPitch=0,HandOnlyYaw=0,HandOnlyRoll=0,ZeroBlend=0,TwoHZeroBlend=0,HandOnlyX=0,HandOnlyY=0,HandOnlyZ=0,
   TwoHOffsetX=0,TwoHOffsetY=0,TwoHOffsetZ=0,TwoHFixedOffsetX=0,TwoHFixedOffsetY=0,TwoHFixedOffsetZ=0,TwoHFixedMainHandOffsetX=0,TwoHFixedMainHandOffsetY=0,TwoHFixedMainHandOffsetZ=0,
   TwoHFixedHandPitch=-8.5,TwoHFixedHandYaw=-45 if name=='shot' else 0,TwoHFixedHandRoll=0 if name in ('rock','rock2') else -90,
   Hotspot1VisualX=0,Hotspot1VisualY=0,Hotspot1VisualZ=0,Hotspot1VisualPitch=0,Hotspot1VisualYaw=0,Hotspot1VisualRoll=0,
   Hotspot2Type=0,Hotspot1Type=1,Hotspot1X=support[0],Hotspot1Y=support[1],Hotspot1Z=support[2],Hotspot1Pitch=0,Hotspot1Yaw=0,Hotspot1Roll=0,
   WpnButtonMode=1,WpnTextMode=1,WpnTextScale=.22)
  for key,keys,target in [('MuzzleAnchorVertex',['MuzzleOffsetX','MuzzleOffsetY','MuzzleOffsetZ'],point(s['muzzle'])),('WpnButtonAnchorVertex',['WpnButtonX','WpnButtonY','WpnButtonZ'],(3,-2,-.3)),('WpnTextAnchorVertex',['WpnTextX','WpnTextY','WpnTextZ'],(3,-2,.4))]:
   ix=min(stable,key=lambda i:sum((actual[order[i]][j]-target[j])**2 for j in range(3)));st[key]=ix
   for j,k in enumerate(keys):st[k]=(target[j]-actual[order[ix]][j])*7/6
  settings.append(f'AD_BASE_ID({s["slot"]}, "progs/advr_base_{name}.mdl")\n')
  settings.extend(f'AD_BASE_SETTING({s["slot"]}, {k}, {v:.6f}f)\n' for k,v in st.items())
  ports.append(f'{{"progs/advr_base_{name}.mdl", {{{port[0]:.6f}f,{port[1]:.6f}f,{port[2]:.6f}f}}, {{{charge[0]:.6f}f,{charge[1]:.6f}f,{charge[2]:.6f}f}}, {str(bool(mag)).lower()}, {{{grip[0]:.6f}f,{grip[1]:.6f}f,{grip[2]:.6f}f}}}},\n')
  front=point(s['muzzle'])[0]-.5
  sights.append(f'{{"progs/advr_base_{name}.mdl", {{0.f,0.f,{sightz:.6f}f}}, {{{front:.6f}f,0.f,{sightz:.6f}f}}}},\n')
  assert m.st[:len(original.st)]==original.st and m.tris[:len(original.tris)]==original.tris
  report[name]={'vertices':len(p),'triangles':len(m.tris),'mag_vertices':len(mag),'grip':grip,'handle_size':HANDLE_SIZE,'support':support,'port':port,'charge':charge,'length':max(v[0] for v in p)-min(v[0] for v in p)}
 # Reuse an existing magazine's metal texels for a small T-shaped charging handle.
 m=mdl.Model(asset(folder,'progs/g_nail.mdl'));m.st=[];m.tris=[];p=[]
 def box(lo,hi):
  base=len(p)
  p.extend((x,y,z) for x in (lo[0],hi[0]) for y in (lo[1],hi[1]) for z in (lo[2],hi[2]))
  m.st.extend([[0,8,8] for _ in range(8)])
  for a,b,c in [(0,1,3),(0,3,2),(4,6,7),(4,7,5),(0,4,5),(0,5,1),(2,3,7),(2,7,6),(0,2,6),(0,6,4),(1,5,7),(1,7,3)]:m.tris.append((1,base+a,base+c,base+b))
 box((-.3,-.2,-.3),(.3,1.5,.3));box((-.7,-.55,-.55),(.7,.2,.55));write_mesh(m,p)
 (out/'advr_charge_handle.mdl').write_bytes(m.to_bytes())
 (ROOT/'Quake/vr/vr_ad_base.inc').write_text('// Generated by make_classic_vr_models.py\n'+''.join(settings))
 (ROOT/'Quake/vr/vr_ad_base_ports.inc').write_text('// Generated model-space attachment points\n'+''.join(ports))
 sights.append('{"progs/advr_crossbow.mdl", {3.f,0.f,2.95f}, {18.5f,0.f,-.0415f}},\n')
 (ROOT/'Quake/vr/vr_ad_base_sights.inc').write_text('// Generated barrel/bolt-rail reference lines (not added sight geometry)\n'+''.join(sights))
 (ROOT/'QC_AD/tools/classic-vr-models.json').write_text(json.dumps(report,indent=2))
 print(json.dumps(report,indent=2))
if __name__=='__main__':
 main(Path(sys.argv[1]))
 from import_custom_weapons import apply_custom
 apply_custom()

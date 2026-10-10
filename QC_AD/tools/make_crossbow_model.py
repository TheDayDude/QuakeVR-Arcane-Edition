"""Adapt the installed AD w_dcrossbow.mdl into the held/physical VR Crossbow.
Usage: python QC_AD/tools/make_crossbow_model.py GAME/ad
Preserves the source mesh topology, UVs and indexed skins; no AI artwork needed.
"""
from pathlib import Path
import importlib.util, struct, sys, math
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('mdl',ROOT/'Misc/quakevr/blender/addons/quakevr_models/mdl.py')
mdl=importlib.util.module_from_spec(spec);spec.loader.exec_module(mdl)
folder=Path(sys.argv[1]);data=None
for pak in sorted(folder.glob('*.pak')):
    b=pak.read_bytes();magic,start,size=struct.unpack_from('<4sii',b);assert magic==b'PACK'
    for pos in range(start,start+size,64):
        name,offset,length=struct.unpack_from('<56sii',b,pos)
        if name.split(b'\0')[0]==b'progs/w_dcrossbow.mdl':data=b[offset:offset+length]
loose=folder/'progs/w_dcrossbow.mdl'
if loose.exists():data=loose.read_bytes()
if data is None:raise SystemExit('Installed AD progs/w_dcrossbow.mdl not found')
m=mdl.Model(data,'w_dcrossbow.mdl');assert len(m.frames)==1 and m.frames[0][0]=='simple'
original_skins=list(m.skins);original_tris=list(m.tris)
# The detached weapon points down -Y. Rotate 90 degrees about Z and
# uniformly size to an 85 cm crossbow with its rear stock held at the tracked grip.
verts=m.pose_bytes()[0]
points=[(-m.place(v)[1]*.6+8.4,m.place(v)[0]*.6,m.place(v)[2]*.6-1.3) for v in verts]
# Append a small shaft, metal point and fletching, keeping original strip indices.
base_count=len(points);base_strip_count=len(mdl.strip_order(m.tris))
bolt=[];bolt_normals=[]
def tri(a,b,c,row):
    k=base_count+len(bolt);bolt.extend((a,b,c))
    u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    n=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
    length=math.sqrt(sum(q*q for q in n));normal=mdl.nearest_normal(tuple(q/length for q in n))
    bolt_normals.extend([normal]*3);m.st.extend([[0,4,m.h[14]+row]]*3);m.tris.append((1,k,k+1,k+2))
def quad(a,b,c,d,row):
    tri(a,b,c,row);tri(a,c,d,row)
z=2.95
for i in range(8):
    a=2*math.pi*i/8;b=2*math.pi*(i+1)/8
    quad((3,.15*math.cos(a),z+.15*math.sin(a)),(16.7,.15*math.cos(a),z+.15*math.sin(a)),
         (16.7,.15*math.cos(b),z+.15*math.sin(b)),(3,.15*math.cos(b),z+.15*math.sin(b)),1)
    tri((16.5,.38*math.cos(b),z+.38*math.sin(b)),(18.5,0,z),(16.5,.38*math.cos(a),z+.38*math.sin(a)),4)
for y,dz in ((.65,0),(-.65,0),(0,.65),(0,-.65)):
    quad((3,0,z),(3.4,y,z+dz),(5.4,y*.5,z+dz*.5),(6,0,z),7)
# Follow the original stock rail, which slopes down toward the bow.
bolt=[(x,y,z-.193*(x-3)) for x,y,z in bolt]
# Extend the indexed skin vertically; all original UV coordinates stay intact.
sw,sh=m.skin_size
m.skins=[[g,iv,[im+bytes([28])*(sw*3)+bytes([9])*(sw*3)+bytes([6])*(sw*2) for im in ims]] for g,iv,ims in m.skins]
m.h[14]=sh+8
poses=[]
for frame,bend in enumerate((0., .85, -.28, .10, 0.)):
    body=[(x+bend*max(0,(abs(y)-2)/8),y,z) for x,y,z in points]
    if frame==4:
        # The original string is triangles 135..146. Pull only its six shared
        # centre vertices behind the bolt's X=3 nock, leaving limb tips fixed.
        for i in (220,221,222,225,226,229):
            x,y,z=body[i];body[i]=(x-4.85,y,z+.193*4.85)
        assert max(body[i][0] for i in (220,221,222,225,226,229))<3
    # Zero-area bolt triangles inside the stock in all unloaded/firing poses.
    poses.append(body+(bolt if frame==4 else [(6,0,0)]*len(bolt)))
low=[min(p[i] for pose in poses for p in pose) for i in range(3)]
high=[max(p[i] for pose in poses for p in pose) for i in range(3)]
scale=[(high[i]-low[i])/255 for i in range(3)]
m.h[2:5]=scale;m.h[5:8]=low;m.h[8]=max(math.sqrt(sum(x*x for x in p)) for pose in poses for p in pose)
m.h[9:12]=[0.,0.,0.];m.h[19]=0
m.frames=[];m.trailing=b''
for frame,pose in enumerate(poses):
    packed=bytearray()
    for i,p in enumerate(pose):
        if i<base_count:
            n=mdl.anorms()[verts[i][3]];normal=mdl.nearest_normal((-n[1],n[0],n[2]))
        else:normal=bolt_normals[i-base_count]
        packed+=bytes([max(0,min(255,round((p[i]-low[i])/scale[i]))) for i in range(3)]+[normal])
    hdr=bytes([0,0,0,0,255,255,255,0])+f'vr_fire{frame}'.encode().ljust(16,b'\0')
    m.frames.append(['simple',hdr,bytes(packed)])
out=ROOT/'QC_AD/runtime/progs/advr_crossbow.mdl';out.write_bytes(m.to_bytes())
out.with_name(out.name+'_0_norm.png').unlink(missing_ok=True) # old fallback UVs do not match
check=mdl.Model(out.read_bytes());assert check.tris[:len(original_tris)]==original_tris
assert check.skins[0][2][0][:sw*sh]==original_skins[0][2][0]
order=mdl.strip_order(m.tris);actual=[m.place(v) for v in m.pose_bytes()[0]]
settings=dict(Scale=1,OffsetX=0,OffsetY=0,OffsetZ=-2.5,Pitch=0,Yaw=0,Roll=0,ZeroBlend=0,TwoHZeroBlend=0)
# Anchor indices are strip-order indices, NOT the source vertex indices.
# Anchor extra offsets use default world units (modelScale / offsetScale = 7/6).
def anchor(key,offsetkeys,point):
    idx=min(range(base_strip_count),key=lambda i:sum((actual[order[i]][j]-point[j])**2 for j in range(3)))
    settings[key]=idx
    for j,k in enumerate(offsetkeys):settings[k]=(point[j]-actual[order[idx]][j])*7/6
    return idx
anchor('MuzzleAnchorVertex',['MuzzleOffsetX','MuzzleOffsetY','MuzzleOffsetZ'],[18.5,0,2.95-.193*(18.5-3)])
anchor('WpnButtonAnchorVertex',['WpnButtonX','WpnButtonY','WpnButtonZ'],[5.6,-1.8,0])
anchor('WpnTextAnchorVertex',['WpnTextX','WpnTextY','WpnTextZ'],[5.6,-1.8,.8])
settings.update(WpnButtonMode=1,WpnButtonPitch=0,WpnButtonYaw=0,WpnButtonRoll=0,WpnTextMode=1,WpnTextPitch=0,WpnTextYaw=0,WpnTextRoll=0,WpnTextScale=.22)
# Support grip under the forward receiver; stock remains available for bracing.
settings.update(Hotspot1Type=1,Hotspot1X=11.6,Hotspot1Y=0,Hotspot1Z=-.5,Hotspot1Pitch=0,Hotspot1Yaw=0,Hotspot1Roll=0,
                Hotspot2Type=3,Hotspot2X=low[0],Hotspot2Y=0,Hotspot2Z=-1.3)
settings.update(Recoil=1,RecoilStrength=.4,RecoilTime=.16,Mass=3,Span=85,Balance=18,Flash=0)
inc=ROOT/'Quake/vr/vr_ad_crossbow.inc'
inc.write_text('// Generated by QC_AD/tools/make_crossbow_model.py from installed AD w_dcrossbow.mdl.\n'+''.join(f'AD_CROSSBOW_SETTING({k}, {v:.6f}f)\n' for k,v in settings.items()))
print('Converted',len(verts),'vertices;',len(m.tris),'triangles; skin',m.skin_size,'bounds',low,high)
print('Calibrated muzzle strip vertex',settings['MuzzleAnchorVertex'])


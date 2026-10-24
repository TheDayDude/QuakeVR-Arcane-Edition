"""Generate Earth rocks and the translucent necrotic ray from bundled rune data."""
from pathlib import Path
import sys,math
src=Path(__file__).resolve().parents[2];sys.path.insert(0,str(src/'QC_AD/tools'))
from make_tome_model import mdl,write_mesh
base=src/'QC_AD/runtime/progs'
def build(name,points,tris,color):
 m=mdl.Model((base/'advr_earth_rune.mdl').read_bytes());m.h[13:15]=[8,8];m.skins=[[0,b'',[bytes([color+(i%3) for i in range(64)])]]];m.st=[[0,i%8,(i*3)%8] for i in range(len(points))];m.tris=[(1,*x) for x in tris];write_mesh(m,points);(base/name).write_bytes(m.to_bytes())

# A slightly uneven convex stone, with clockwise faces for the alias renderer.
import itertools
phi=(1+math.sqrt(5))/2
rock=[(0,a,b*phi) for a in [-1,1] for b in [-1,1]]+[(a,b*phi,0) for a in [-1,1] for b in [-1,1]]+[(a*phi,0,b) for a in [-1,1] for b in [-1,1]]
rock=[tuple(c*(1+.15*math.sin(i*2.3)) for c in v) for i,v in enumerate(rock)];faces=[]
for a,b,c in itertools.combinations(range(12),3):
 u=[rock[b][j]-rock[a][j] for j in range(3)];v=[rock[c][j]-rock[a][j] for j in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
 sides=[sum(n[j]*(q[j]-rock[a][j]) for j in range(3)) for i,q in enumerate(rock) if i not in [a,b,c]]
 if max(sides)<.00001:faces.append((a,c,b))
 elif min(sides)>-.00001:faces.append((a,b,c))
build('advr_rune_rock.mdl',rock,faces,3)

pts=[(x,math.cos(i*math.pi/4)*.65,math.sin(i*math.pi/4)*.65) for x in [0,600] for i in range(8)];tris=[]
for i in range(8):
 j=(i+1)%8;tris.extend([(i,8+i,j),(j,8+i,8+j)])
build('advr_necrotic_ray.mdl',pts,tris,0)

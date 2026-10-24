"""Build Nether's palm-sized native rune and a fiery native-rune projectile.
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
 # Retain the native Hell Rune silhouette, centered in the flight plane.
 arc=mdl.Model(rune.to_bytes());points=[arc.place(v) for v in arc.pose_bytes()[0]]
 points=[tuple(c*3.5 for c in p) for p in points]
 arc.skins=[[0,b'', [bytes(224+(c%4) for c in arc.skins[0][2][0])]]]
 write_mesh(arc,points);(ROOT/'QC_AD/runtime/progs/advr_nether_arc.mdl').write_bytes(arc.to_bytes())
 # Shared mesh samples keep flames on the rune instead of the old crescent.
 unique=sorted(set(tuple(round(c,4) for c in p) for p in points))
 (ROOT/'Quake/vr/vr_nether_flame_points.inc').write_text('// Generated native Hell Rune surface samples.\n'+''.join('{'+', '.join(f'{c:.4f}f' for c in p)+'},\n' for p in unique))
if __name__=='__main__':build(Path(sys.argv[1]))

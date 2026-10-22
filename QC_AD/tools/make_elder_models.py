"""Build Elder Rune and tracked Fiend parts from installed AD assets.
Usage: python make_elder_models.py GAME/ad
The body preserves AD animation/UVs; the claw is aligned along controller +X.
"""
from pathlib import Path
import sys,re,copy
from make_tome_model import asset,mdl,ROOT,write_mesh

def build(ad):
 dest=ROOT/'QC_AD/runtime/progs'
 rune=mdl.Model(asset(ad,'progs/key_rune4.mdl'))
 points=[rune.place(v) for v in rune.pose_bytes()[0]]
 center=[(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)]
 factor=12/max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))
 rune.h[2:5]=[x*factor for x in rune.h[2:5]]
 rune.h[5:8]=[(rune.h[5+i]-center[i])*factor for i in range(3)]
 rune.h[8]*=factor;rune.h[19]=0
 (dest/'advr_elder_rune.mdl').write_bytes(rune.to_bytes())
 body=mdl.Model(asset(ad,'progs/mon_demon.mdl'))
 rigs=(ROOT/'Quake/vr/vr_ad_rigs.inc').read_text()
 labels=list(map(int,re.findall(r'\d+',re.search(r'ad_mon_demonLabels\[\] = \{(.*?)\};',rigs,re.S)[1])))
 assert len(labels)==body.num_verts
 # Remove the native head/arms: head would obscure the HMD and hands are tracked.
 body.tris=[t for t in body.tris if all(labels[i] not in (2,3,4,5) for i in t[1:])]
 assert len(body.tris)>50
 body.h[19]=0
 (dest/'advr_fiend_body.mdl').write_bytes(body.to_bytes())
 # Extract the living claw, not a bloody severed-arm gib. UVs remain those of the
 # original Fiend. Its wrist is the controller pivot; the hooked tip points ahead.
 claw=mdl.Model(asset(ad,'progs/mon_demon.mdl'))
 claw.tris=[t for t in claw.tris if all(labels[i] in (3,4) for i in t[1:]) and any(labels[i]==4 for i in t[1:])]
 used=sorted({i for t in claw.tris for i in t[1:]});remap={v:i for i,v in enumerate(used)}
 points=[claw.place(claw.pose_bytes()[0][i]) for i in used]
 claw.st=[claw.st[i] for i in used];claw.tris=[(t[0],*(remap[i] for i in t[1:])) for t in claw.tris]
 # Rotate about Z (rather than reflect), retaining triangle winding and normals.
 p2=[((12-y)*.85,-(x-11)*.85,-(z+18)*.85) for x,y,z in points]
 write_mesh(claw,p2);(dest/'advr_fiend_claw.mdl').write_bytes(claw.to_bytes())
 tome=mdl.Model((dest/'advr_tome.mdl').read_bytes())
 while len(tome.frames)<14:tome.frames.append(copy.deepcopy(tome.frames[0]))
 (dest/'advr_tome.mdl').write_bytes(tome.to_bytes())
 print('Elder meshes:',len(body.tris),'body triangles;',len(claw.tris),'claw triangles')

if __name__=='__main__':build(Path(sys.argv[1]))

"""Center and shrink QuakeVR's hand grenade, preserving both pin/live skins."""
from pathlib import Path
import sys
from make_tome_model import asset,mdl,ROOT
def build(folder):
 m=mdl.Model(asset(folder,'progs/grenade.mdl'))
 points=[m.place(v) for v in m.pose_bytes()[0]]
 center=[(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)]
 m.h[2:5]=[x*.78 for x in m.h[2:5]]
 m.h[5:8]=[(m.h[5+i]-center[i])*.78 for i in range(3)]
 m.h[8]*=.78;m.h[19]=0
 (ROOT/'QC_AD/runtime/progs/advr_handgrenade.mdl').write_bytes(m.to_bytes())
if __name__=='__main__':build(Path(sys.argv[1]))

from pathlib import Path
import sys
from make_tome_model import asset,mdl,ROOT
rune=mdl.Model(asset(Path(sys.argv[1]),'progs/key_rune1.mdl'))
points=[rune.place(x) for x in rune.pose_bytes()[0]]
center=[(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)]
factor=12/max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))
rune.h[2:5]=[x*factor for x in rune.h[2:5]]
rune.h[5:8]=[(rune.h[5+i]-center[i])*factor for i in range(3)]
rune.h[8]*=factor;rune.h[19]=0
(ROOT/'QC_AD/runtime/progs/advr_earth_rune.mdl').write_bytes(rune.to_bytes())

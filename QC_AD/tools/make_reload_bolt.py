"""Extract the loaded crossbow bolt as a centered, unlit reload prop.
Run after make_crossbow_model.py. No source game assets are required here.
"""
from pathlib import Path
import importlib.util, math
root=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('mdl',root/'Misc/quakevr/blender/addons/quakevr_models/mdl.py')
mdl=importlib.util.module_from_spec(spec);spec.loader.exec_module(mdl)
folder=root/'QC_AD/runtime/progs'
m=mdl.Model((folder/'advr_crossbow.mdl').read_bytes())
empty,loaded=m.pose_bytes()[0],m.pose_bytes()[4]
# Bolt triangles collapse to one point in unloaded poses. The cocked string
# moves too, but never collapses, so it cannot enter this selection.
tris=[t for t in m.tris if len({tuple(empty[i][:3]) for i in t[1:]})==1
      and len({tuple(loaded[i][:3]) for i in t[1:]})>1]
ids=sorted({i for t in tris for i in t[1:]});assert len(tris)==32,(len(tris),len(ids))
positions=[m.place(loaded[i]) for i in ids]
center=[(min(p[a] for p in positions)+max(p[a] for p in positions))/2 for a in range(3)]
m.h[5:8]=[m.h[5+a]-center[a] for a in range(3)]
lookup={v:i for i,v in enumerate(ids)}
m.st=[m.st[i] for i in ids];m.tris=[(t[0],*(lookup[i] for i in t[1:])) for t in tris]
hdr=bytes([0,0,0,0,255,255,255,0])+b'bolt'.ljust(16,b'\0')
m.frames=[['simple',hdr,b''.join(bytes(loaded[i]) for i in ids)]]
m.h[19]=0;m.h[9:12]=[0.,0.,0.];m.trailing=b''
(folder/'advr_reload_bolt.mdl').write_bytes(m.to_bytes())
print('Extracted loaded bolt:',len(tris),'triangles; centered at',center)


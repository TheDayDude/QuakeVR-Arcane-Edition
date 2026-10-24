"""Retain Quake lightning geometry/animation with a black non-fullbright skin.
Usage: python QC_AD/tools/make_necrotic_bolt.py GAME/id1
"""
from pathlib import Path
import sys
from make_tome_model import asset,mdl
m=mdl.Model(asset(Path(sys.argv[1]),'progs/bolt2.mdl'))
for skin in m.skins:
    skin[2]=[bytes(len(frame)) for frame in skin[2]]
m.h[19]=0
(Path(__file__).resolve().parents[1]/'runtime/progs/advr_necrotic_bolt.mdl').write_bytes(m.to_bytes())

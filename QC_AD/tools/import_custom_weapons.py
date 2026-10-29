"""Import the user's geometry while preserving model-space gameplay attachments.

Called after make_classic_vr_models, whose models/settings provide the reference
anchors. The unmodified artist exports live in QC_AD/custom-models.
"""
import re, struct, copy, json
from make_tome_model import ROOT, mdl, write_mesh

def read_custom(path):
    data=path.read_bytes()
    # This shotgun export changed the common skin dimensions to 116x192 but
    # retained the original 128x194 first image. MDL requires every skin to
    # have the common dimensions. Resample that image; leave all geometry,
    # UVs, normals, poses and the second image exactly as exported.
    h=mdl.HEADER.unpack_from(data)
    if path.name=='advr_base_shot.mdl' and h[12:18]==(2,116,192,1618,1200,1) and len(data)==92312:
        assert struct.unpack_from('<i',data,84)[0]==0
        assert struct.unpack_from('<i',data,24920)[0]==0
        image=data[88:24920]
        resized=bytes(image[min(193,int((y+.5)*194/192))*128+min(127,int((x+.5)*128/116))]
                      for y in range(192) for x in range(116))
        data=data[:88]+resized+data[24920:]
    m=mdl.Model(data,path.name)
    assert not m.trailing, 'Unexpected bytes after model poses'
    for pose in m.pose_bytes():
        assert len(pose)==len(m.st)
        assert all(v[3]<162 for v in pose)
    assert all(len(im)==m.h[13]*m.h[14] for skin in m.skins for im in skin[2])
    return m

def apply_custom():
    dest=ROOT/'QC_AD/runtime/progs';inc=ROOT/'Quake/vr/vr_ad_base.inc'
    settings=inc.read_text()
    report_path=ROOT/'QC_AD/tools/classic-vr-models.json'
    report=json.loads(report_path.read_text())
    for name,slot in [('shot',1),('nail2',4)]:
        path=ROOT/f'QC_AD/custom-models/advr_base_{name}.mdl'
        if not path.exists():continue
        output=dest/path.name;old=mdl.Model(output.read_bytes());new=read_custom(path)
        oldorder=mdl.strip_order(old.tris);order=mdl.strip_order(new.tris)
        before=[old.place(v) for v in old.pose_bytes()[0]]
        after=[new.place(v) for v in new.pose_bytes()[0]]
        def get(key):
            return float(re.search(rf'AD_BASE_SETTING\({slot}, {key}, ([\d.e+\-]+)f\)',settings)[1])
        def put(key,value):
            nonlocal settings
            settings=re.sub(rf'AD_BASE_SETTING\({slot}, {key}, [\d.e+\-]+f\)',
                            f'AD_BASE_SETTING({slot}, {key}, {value:.6f}f)',settings)
        if name=='shot':
            from make_classic_vr_models import components, poses as make_poses
            # This artist export shares vertices between the wooden fore-end
            # and barrel. Split their boundary before animating the wood.
            assert len(new.st)==1618 and len(new.tris)==1200
            faces=set(range(8,32))-{16,17,21,22}
            faces.update([33,35,36,40]);faces.update(range(226,234))
            # The ribbed outer shell is exported as disconnected UV islands.
            outer=set()
            for group in components(new):
                lo=[min(after[i][a] for i in group) for a in range(3)]
                hi=[max(after[i][a] for i in group) for a in range(3)]
                if lo[0]>6.3 and hi[0]<14 and hi[2]<-.95:
                    outer.update(group)
            assert len(outer)==416, len(outer)
            faces.update(j for j,t in enumerate(new.tris) if all(i in outer for i in t[1:]))
            moving={i for j,t in enumerate(new.tris) if j in faces for i in t[1:]}
            fixed={i for j,t in enumerate(new.tris) if j not in faces for i in t[1:]}
            boundary=sorted(moving & fixed);remap={i:len(new.st)+j for j,i in enumerate(boundary)}
            packed=new.frames[0][2]
            for i in boundary:
                new.st.append(list(new.st[i]));after.append(after[i])
                new.frames[0][2]+=packed[i*4:i*4+4]
            new.h[15]=len(new.st)
            new.tris=[(t[0],*(remap.get(i,i) for i in t[1:])) if j in faces else t for j,t in enumerate(new.tris)]
            pump={remap.get(i,i) for i in moving}
            order=mdl.strip_order(new.tris)
            variants=[]
            for frame in range(16):
                p=list(after)
                for i in pump:p[i]=(after[i][0]-3*frame/15,after[i][1],after[i][2])
                variants.append(p)
            make_poses(new,after,variants)
        stable=[]
        poses=new.pose_bytes()
        for i,v in enumerate(order):
            if all(p[v][:3]==poses[0][v][:3] for p in poses):stable.append(i)
        assert stable
        for anchor,keys in [('MuzzleAnchorVertex',['MuzzleOffsetX','MuzzleOffsetY','MuzzleOffsetZ']),
                            ('WpnButtonAnchorVertex',['WpnButtonX','WpnButtonY','WpnButtonZ']),
                            ('WpnTextAnchorVertex',['WpnTextX','WpnTextY','WpnTextZ'])]:
            v=before[oldorder[int(get(anchor))]]
            target=[v[a]+get(keys[a])*6/7 for a in range(3)]
            ix=min(stable,key=lambda i:sum((after[order[i]][a]-target[a])**2 for a in range(3)))
            put(anchor,ix)
            for a,key in enumerate(keys):put(key,(target[a]-after[order[ix]][a])*7/6)
        output.write_bytes(new.to_bytes())
        report[name].update(vertices=len(new.st),triangles=len(new.tris),
                            custom_source=str(path.relative_to(ROOT)).replace('\\','/'),
                            length=max(v[0] for v in after)-min(v[0] for v in after))
        if name=='nail2':
            # Exporters may quantize the magazine slightly differently. Build
            # its loose counterpart from exactly the new removable vertices.
            ids=[i for i in range(len(new.st)) if poses[0][i][:3]!=poses[16][i][:3]]
            assert ids and len(poses)==32
            index={v:i for i,v in enumerate(ids)};mag=copy.deepcopy(new)
            mag.st=[new.st[i] for i in ids]
            mag.tris=[(f,index[a],index[b],index[c]) for f,a,b,c in new.tris if all(i in index for i in (a,b,c))]
            center=[(min(after[i][a] for i in ids)+max(after[i][a] for i in ids))/2 for a in range(3)]
            points=[tuple(after[i][a]-center[a] for a in range(3)) for i in ids]
            lo=[min(v[a] for v in points) for a in range(3)];hi=[max(v[a] for v in points) for a in range(3)]
            base=len(points)
            points.extend([(lo[0],lo[1],hi[2]),(hi[0],lo[1],hi[2]),(hi[0],hi[1],hi[2]),(lo[0],hi[1],hi[2])])
            mag.st.extend([list(mag.st[0]) for _ in range(4)])
            mag.tris.extend([(1,base,base+2,base+1),(1,base,base+3,base+2)])
            write_mesh(mag,points);(dest/'advr_base_mag_nail2.mdl').write_bytes(mag.to_bytes())
        print(f'Custom {name}: {len(new.st)} vertices, {len(new.tris)} triangles, {len(poses)} poses; anchors remapped')
    inc.write_text(settings)
    report_path.write_text(json.dumps(report,indent=2))

if __name__=='__main__':apply_custom()

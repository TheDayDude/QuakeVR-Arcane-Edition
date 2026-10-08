"""Build AD's ragdoll skin assignments from the user's installed MDL animations.

No models/textures are redistributed. Anatomical templates seed a rigid-motion fit;
only adjacent mesh regions can exchange vertices. The checked-in include is used
at runtime, avoiding expensive clustering when an AD map loads. Requires numpy.
Usage: python make_ragdolls.py GAME/ad [--only mon_soldier]
"""
from pathlib import Path
import argparse, importlib.util, json, re, struct
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('mdl', ROOT/'Misc/quakevr/ragdoll/mdl.py')
mdl = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mdl)

# Related AD meshes retain the original creature's anatomy and animation layout.
FAMILIES = {
    'grunt': 'soldier',
    'enforcer': 'enforcer deflector centurion pyro fumigator',
    'knight': 'knight dguard dcrossbow',
    'hknight': 'hknight dguardq dknight dlord dprince dsergeant dfury judge justice',
    'ogre': 'ogre hogre hogreham hogremac',
    'shambler': 'shambler bossboglord golem bossicegolem seeker minotaur',
    'zombie': 'zombie zombiek skullwiz',
    'dog': 'dog', 'demon': 'demon', 'wizard': 'wizard bossnour',
}

def bone(name, parent, xyz):
    return dict(name=name, parent=parent, centre=np.array(xyz, float), joint='Ball')

def custom(name):
    # Coordinates normalized to each rest-pose box, x forward/y left/z up.
    b = [bone('body', -1, [.48,.5,.5])]
    if name in ('tarbaby','lostsoul','jim','jimrock','floyd'):
        return b  # no limbs; a physical whole-body hull is the appropriate rig
    if name in ('fish','eel'):
        b += [bone('head',0,[.86,.5,.5]),bone('tail',0,[.22,.5,.5]),bone('tailtip',2,[.04,.5,.5])]
    elif name in ('spiderb','spiderg','steelclaw','scorpion'):
        b[0]['centre'] = np.array([.36,.5,.55 if name!='scorpion' else .25])
        b += [bone('head',0,[.70,.5,.55 if name!='scorpion' else .25])]
        for side,y in (('l',.86),('r',.14)):
            for i,x in enumerate((.21,.39,.57,.76)):
                b += [bone(f'leg_{side}{i}',0,[x,y,.18])]
        if name=='scorpion':
            b += [bone('tail',0,[.08,.5,.5]),bone('stinger',10,[.20,.5,.9])]
    elif name in ('voreling','vorelingp','swampling','swamplingp','shalrath'):
        b[0]['centre']=np.array([.45,.5,.55])
        b += [bone('head',0,[.7,.5,.88])]
        for side,y in (('l',.9),('r',.1)):
            p=len(b);b += [bone('thigh_'+side,0,[.56,y,.51]),bone('shin_'+side,p,[.66,y,.12])]
        b += [bone('hindleg',0,[.07,.5,.23])]
        if name=='shalrath':
            b += [bone('arm_l',0,[.87,.66,.65]),bone('arm_r',0,[.87,.34,.65])]
    elif name in ('gargoyle','gaunt','bosseidolon'):
        b[0]['centre']=np.array([.57,.5,.4])
        b += [bone('chest',0,[.67,.5,.64]),bone('head',1,[.83,.5,.78])]
        for side,y in (('l',.72),('r',.28)):
            p=len(b);b += [bone('arm_'+side,1,[.83,y,.49]),bone('leg_'+side,0,[.47,y,.16])]
        if name!='bosseidolon':
            b += [bone('wing_l',1,[.27,.90,.83]),bone('wing_r',1,[.27,.10,.83])]
        b += [bone('tail',0,[.12,.5,.16])]
    elif name in ('wraith','sentinel'):
        b[0]['centre']=np.array([.48,.5,.42])
        b += [bone('head',0,[.55,.5,.85]),bone('arm_l',0,[.5,.85,.64]),bone('arm_r',0,[.5,.15,.64])]
    elif name=='boil':
        b[0]['centre']=np.array([.5,.5,.7])
        for side,y in (('l',.75),('r',.25)):
            p=len(b);b += [bone('thigh_'+side,0,[.4,y,.34]),bone('shin_'+side,p,[.38,y,.09])]
    elif name=='bosschthon':
        b += [bone('chest',0,[.35,.5,.75]),bone('head',1,[.55,.5,.91]),bone('arm_l',1,[.7,.85,.6]),bone('arm_r',1,[.7,.15,.6])]
    elif name in ('drole','freddie'):
        b[0]['centre']=np.array([.40,.5,.36])
        b += [bone('chest',0,[.4,.5,.64]),bone('head',1,[.59,.5,.84])]
        for side,y in (('l',.81),('r',.19)):
            p=len(b);b += [bone('arm_'+side,1,[.44,y,.78]),bone('hand_'+side,p,[.83,y,.89])]
            p=len(b);b += [bone('thigh_'+side,0,[.61,y,.26]),bone('shin_'+side,p,[.43,y,.08])]
    else:
        raise ValueError('No anatomical template for '+name)
    return b

def templates():
    cpp=(ROOT/'Quake/vr/vr_ragdoll.cpp').read_text()
    result={}
    pattern=r'\{"([^"]+)",\s*(-?\d+),\s*Joint::(\w+),\s*\{([^}]+)\},\s*\{([^}]+)\},\s*\{([^}]+)\}'
    for family in FAMILIES:
        block=re.search(r'constexpr Seed '+family+r'Seeds\[\] = \{(.*?)\n\};',cpp,re.S)[1]
        result[family]=[dict(name=n,parent=int(p),joint=j,centre=np.array([float(x.strip().rstrip('f')) for x in c.split(',')]))
                        for n,p,j,c,_,_ in re.findall(pattern,block)]
    return result

def fit(x, labels, k):
    rot=[];pos=[];errs=[]
    for b in range(k):
        mask=labels==b;a=x[0,mask];v=x[:,mask];ca=a.mean(0);cb=v.mean(1)
        u,_,vt=np.linalg.svd(np.einsum('vi,pvj->pij',a-ca,v-cb[:,None]))
        fix=np.tile(np.eye(3),(len(x),1,1));fix[:,2,2]=np.linalg.det(vt.transpose(0,2,1)@u.transpose(0,2,1))
        r=vt.transpose(0,2,1)@fix@u.transpose(0,2,1);t=cb-np.einsum('pij,j->pi',r,ca)
        err=((np.einsum('vj,pij->pvi',x[0],r)+t[:,None]-x)**2).sum(2).mean(0)
        rot.append(r);pos.append(t);errs.append(err)
    return np.array(rot),np.array(pos),np.array(errs).T

def generate(name, data, family, seeds):
    names,poses,tris=mdl.load(data);nv=poses.shape[1]
    # This reader's grouped-frame layout is not the engine's flattened pose layout.
    # Installed AD creature models use simple frames; reject other assets explicitly.
    ns,sw,sh,nverts,nt,nframes=struct.unpack_from('<6i',data,48)
    offset=84
    for _ in range(ns):
        group,=struct.unpack_from('<i',data,offset);offset+=4
        if group:
            n,=struct.unpack_from('<i',data,offset);offset+=4+4*n+n*sw*sh
        else:offset+=sw*sh
    offset+=12*nverts+16*nt
    for _ in range(nframes):
        group,=struct.unpack_from('<i',data,offset)
        assert group==0,name+' has grouped frames; flatten poses before rigging'
        offset+=28+4*nverts
    keys={};rep=[]
    for v in range(nv):rep.append(keys.setdefault(poses[:,v].tobytes(),v))
    reps=np.array(sorted(set(rep)));ri={int(v):i for i,v in enumerate(reps)}
    x=poses[:,reps];p=x[0];adj=[set() for _ in reps]
    for tri in tris:
        ids=[ri[rep[int(v)]] for v in tri]
        for i,j in zip(ids,ids[1:]+ids[:1]):
            if i!=j:adj[i].add(j);adj[j].add(i)
    if family:
        base={'grunt':'soldier'}.get(family,family)
        _,bp,_=mdl.load(ROOT/f'quakevr/progs/{base}.mdl')
        # Robust boxes avoid disproportionate scaling from a sword/chainsaw tip.
        lo,hi=np.percentile(p,[5,95],axis=0);bl,bh=np.percentile(bp[0],[5,95],axis=0)
        scale=(hi-lo)/np.maximum(bh-bl,1)
        for b in seeds:b['centre']=(b['centre']-bl)*scale+lo
    else:
        lo,hi=p.min(0),p.max(0)
        for b in seeds:b['centre']=lo+b['centre']*(hi-lo)
    centres=np.array([b['centre'] for b in seeds])
    heads=json.loads((ROOT/'QC_AD/tools/head-profiles.json').read_text())
    profile=next((h for h in heads if h['model']=='progs/'+name+'.mdl'),None)
    head=next((i for i,b in enumerate(seeds) if b['name']=='head'),None)
    headmask=np.zeros(len(p),bool)
    if profile and head is not None:
        headmask=((p>=np.array(profile['lo'])-.5)&(p<=np.array(profile['hi'])+.5)).all(1)
        if headmask.sum()>=4:centres[head]=p[headmask].mean(0)
        else:headmask[:]=False
    labels=((p[:,None]-centres)**2).sum(2).argmin(1)
    if headmask.any():labels[headmask]=head
    # Very low-poly models may not have enough vertices for every template segment.
    # Merge those into their parent rather than emitting singular/empty rigid fits.
    while min(np.bincount(labels,minlength=len(seeds)))<4 and len(seeds)>1:
        bad=int(np.argmin(np.bincount(labels,minlength=len(seeds))))
        parent=seeds[bad]['parent']
        if parent<0:parent=next(i for i in range(len(seeds)) if i!=bad)
        labels[labels==bad]=parent
        for b in seeds:
            if b['parent']==bad:b['parent']=parent if b is not seeds[parent] else -1
            if b['parent']>bad:b['parent']-=1
        seeds.pop(bad);labels[labels>bad]-=1
    assert seeds[0]['parent']==-1,name+' needs a root bone first'
    assert all(0<=b['parent']<i for i,b in enumerate(seeds) if i),name+' has an invalid joint tree'
    # Use living animation to find limb boundaries, not flattened death poses.
    alive=[i for i,n in enumerate(names) if not n.lower().startswith(('death','dead','die','gib'))]
    sample=sorted(set([0]+[alive[i] for i in np.linspace(0,len(alive)-1,min(32,len(alive))).astype(int)]))
    samplex=x[sample];k=len(seeds)
    head=next((i for i,b in enumerate(seeds) if b['name']=='head'),None)
    if head is None:headmask[:]=False
    for iteration in range(20):
        rot,pos,err=fit(samplex,labels,k);new=labels.copy();counts=np.bincount(labels,minlength=k)
        for v,nb in enumerate(adj):
            if headmask[v]:continue
            candidates={int(labels[u]) for u in nb}|{int(labels[v])}
            if headmask.any() and head in candidates and labels[v]!=head:candidates.remove(head)
            best=min(candidates,key=lambda b:err[v,b]);old=int(labels[v])
            if best!=old and counts[old]>4 and err[v,best]+.005<err[v,old]:
                new[v]=best;counts[old]-=1;counts[best]+=1
        if np.array_equal(new,labels):break
        labels=new
    rot,pos,err=fit(samplex,labels,k)
    assert np.isfinite(rot).all() and np.isfinite(pos).all(),name+' has a singular fit'
    # Regularized joint fit pulled toward the touching mesh boundary. Restrict to
    # nearby geometry so nearly rigid/identical motions cannot invent remote pivots.
    centres=np.array([p[labels==b].mean(0) for b in range(k)])
    for b,s in enumerate(seeds):
        s['centre']=centres[b];par=s['parent'];s['pivot']=centres[b].copy()
        if par>=0:
            a=p[labels==par];c=p[labels==b];d=((a[:,None]-c)**2).sum(2)
            close=np.unravel_index(np.argsort(d,axis=None)[:min(12,d.size)],d.shape)
            boundary=((a[close[0]]+c[close[1]])*.5).mean(0)
            A=(rot[par]-rot[b]).reshape(-1,3);y=(pos[b]-pos[par]).reshape(-1)
            pivot=np.linalg.lstsq(np.concatenate([A,2*np.eye(3)]),np.concatenate([y,2*boundary]),rcond=None)[0]
            radius=max(1,float(np.linalg.norm(centres[b]-centres[par]))*.3)
            delta=pivot-boundary
            s['pivot']=boundary+delta*min(1,radius/max(np.linalg.norm(delta),.001))
        # Ball joints avoid assuming a human elbow axis for unusual AD creatures.
        s['joint']='Root' if par<0 else 'Ball'
    full=np.array([labels[ri[r]] for r in rep])
    rms=float(np.sqrt(err[np.arange(len(labels)),labels].mean()))
    return dict(model='progs/'+name+'.mdl',verts=nv,poses=len(poses),bones=seeds,labels=full.tolist(),rms=rms,
                counts=np.bincount(labels,minlength=k).tolist(),names=names), (poses,tris,full)

def emit(records, dest):
    lines=['// Generated by QC_AD/tools/make_ragdolls.py. AD 1.80 animation-derived rigs.']
    vec=lambda v:'{'+', '.join(f'{float(x):.4f}f' for x in v)+'}'
    for row in records:
        key=Path(row['model']).stem
        lines += [f'constexpr Seed ad_{key}Seeds[] = {{']
        for b in row['bones']:
            end=2*np.array(b['centre'])-b['pivot']
            lines += ['    {"%s", %d, Joint::%s, %s, %s, %s, 0.f, 55.f, 35.f, 0.f, {}},'%
                      (b['name'],b['parent'],b['joint'],vec(b['centre']),vec(b['pivot']),vec(end))]
        lines += ['};',f'constexpr uint8_t ad_{key}Labels[] = {{']
        labels=row['labels']
        lines += ['    '+','.join(map(str,labels[i:i+48]))+',' for i in range(0,len(labels),48)]
        lines += ['};']
    lines += ['constexpr SeedTable adSeedTables[] = {']
    for r in records:
        key=Path(r['model']).stem
        lines += ['    {"%s", %d, ad_%sSeeds, %d, 0, {}, {}, 0, ad_%sLabels, %d},'%
                  (r['model'],r['verts'],key,len(r['bones']),key,r['poses'])]
    lines += ['};','']
    dest.write_text('\n'.join(lines))

def draw(name, model, output):
    from PIL import Image, ImageDraw
    poses,tris,labels=model;p=poses[0];im=Image.new('RGB',(800,450),'white');d=ImageDraw.Draw(im)
    import colorsys
    palette=[tuple(int(x*220) for x in colorsys.hsv_to_rgb(i*.618%1,.65,.95)) for i in range(16)]
    for view,axes in enumerate(((0,2),(1,2))):
        q=p[:,axes];lo=q.min(0);hi=q.max(0);s=350/max(hi-lo);q=(q-lo)*[s,-s]+[view*400+20,410]
        depth=1 if view==0 else 0
        for tri in tris[np.argsort(p[tris][:,:,depth].mean(1))]:
            label=int(np.bincount(labels[tri]).argmax());color=palette[label]
            d.polygon([tuple(a) for a in q[tri]],fill=color,outline=tuple(int(c*.6) for c in color))
    d.text((10,10),name,fill='black');im.save(output)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('pakdir',type=Path);ap.add_argument('--only');args=ap.parse_args()
    assets={}
    for pak in sorted(args.pakdir.glob('pak*.pak')):
        data=pak.read_bytes();_,off,size=struct.unpack_from('<4sii',data)
        for at in range(off,off+size,64):
            n,o,s=struct.unpack_from('<56sii',data,at);n=n.split(b'\0')[0].decode()
            if n.startswith('progs/mon_') and n.endswith('.mdl'):assets[n]=data[o:o+s]
    models=sorted(set(re.findall(r'self\.mdl\s*=\s*"(progs/mon_[^"]+\.mdl)"','\n'.join(p.read_text() for p in (ROOT/'QC_AD/game').glob('mon*.qc')))))
    ts=templates();families={name:f for f,names in FAMILIES.items() for name in names.split()}
    out=ROOT/'build-ad-rigs';out.mkdir(exist_ok=True);records=[]
    for path in models:
        if path not in assets:continue
        key=Path(path).stem
        if args.only and key!=args.only:continue
        name=key[4:];family=families.get(name)
        seeds=[dict(b,centre=b['centre'].copy()) for b in ts[family]] if family else custom(name)
        row,model=generate(key,assets[path],family,seeds);records.append(row)
        draw(key,model,out/(key+'.png'))
        print(key,len(row['bones']),'bones',row['counts'],'rms',round(row['rms'],2),flush=True)
    if not args.only:
        emit(records,ROOT/'Quake/vr/vr_ad_rigs.inc')
        qc=['// Generated roster; test-only precaching is opt-in, never used in normal play.',
            'string(float i) ADVR_RagdollModel = {']
        qc += [f'    if(i=={i})return "{r["model"]}";' for i,r in enumerate(records)]
        qc += ['    return "";', '};', 'void() ADVR_RagdollPrecache = {',
               '    if(!cvar("advr_ragdoll_test"))return;']
        qc += [f'    precache_model("{r["model"]}");' for r in records]
        qc += ['};','']
        (ROOT/'QC_AD/game/advr_ragdoll_models.qc').write_text('\n'.join(qc))
        summary=[{k:v for k,v in r.items() if k not in ('bones','labels','names')} for r in records]
        (out/'coverage.json').write_text(json.dumps(summary,indent=2)+'\n')
        (ROOT/'QC_AD/tools/ragdoll-coverage.json').write_text(json.dumps(summary,indent=2)+'\n')
        print('Generated',len(records),'rigs',flush=True)

if __name__=='__main__':main()

"""Create explicit editable weapon PNG sidecars, preserving effective game artwork.

Usage: python consolidate_weapon_textures.py GAME_ROOT [BACKUP_DIRECTORY]
Writes source runtime assets only. Existing PNGs are never regenerated.
"""
from pathlib import Path
import sys, struct, re, importlib.util, io, json, hashlib, shutil
from collections import deque
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('mdl',ROOT/'Misc/quakevr/blender/addons/quakevr_models/mdl.py')
mdl=importlib.util.module_from_spec(spec);spec.loader.exec_module(mdl)

def flood(data,w,h):
    """Match Mod_FloodFillSkin before externalizing an indexed skin."""
    data=bytearray(data);fill=data[0]
    if fill in (0,255):return bytes(data)
    queue=deque([(0,0)])
    while queue:
        x,y=queue.popleft();color=0
        for dx,dy in [(-1,0),(1,0),(0,-1),(0,1)]:
            X,Y=x+dx,y+dy
            if not (0<=X<w and 0<=Y<h):continue
            j=X+Y*w
            if data[j]==fill:data[j]=255;queue.append((X,Y))
            elif data[j]!=255:color=data[j]
        data[x+y*w]=color
    return bytes(data)

def main():
    game=Path(sys.argv[1]).resolve();dest=ROOT/'QC_AD/runtime/progs'
    backup=Path(sys.argv[2]).resolve() if len(sys.argv)>2 else None
    layers=[]
    for folder in ['advr','ad_hd','ad','quakevr','id1']:
        directory=game/folder;entries={}
        for pak in sorted(directory.glob('*.pak'),reverse=True):
            with pak.open('rb') as f:
                magic,start,size=struct.unpack('<4sii',f.read(12));assert magic==b'PACK'
                f.seek(start)
                for _ in range(size//64):
                    name,offset,length=struct.unpack('<56sii',f.read(64))
                    entries.setdefault(name.split(b'\0')[0].decode(),(pak,offset,length))
        layers.append((directory,entries))
    def asset(name):
        for directory,entries in layers:
            p=directory/name
            if p.is_file():return p.read_bytes(),str(p.relative_to(game))
            if name in entries:
                pak,offset,length=entries[name]
                with pak.open('rb') as f:f.seek(offset);return f.read(length),str(pak.relative_to(game))+':'+name
        return None,None
    palette,_=asset('gfx/palette.lmp');assert len(palette)==768
    names=set(re.findall(r'QVR_WEAPON_DEFAULT\(\d+, ID, "progs/([^"/]+\.mdl)"', (ROOT/'Quake/vr/vr_weapons.inc').read_text()))
    names.update(p.name for p in dest.glob('v_*.mdl'))
    names.update(p.name for p in (game/'quakevr/progs').glob('g_*.mdl'))
    names.update(n+'.mdl' for n in ['advr_crossbow','advr_plasma','advr_widowmaker','advr_shadowaxe','advr_hammer','advr_fury1','advr_fury2','advr_tome','advr_handgrenade'])
    names.update(p.name for p in dest.glob('advr_base_*.mdl'))
    names.update(p.name for p in dest.glob('vr_ssg_*.mdl'))
    names.update(p.name for p in dest.glob('vr_mag_*.mdl'))
    names.update(p.name for p in dest.glob('vr_shell*.mdl'))
    names.update(['advr_mag_shell.mdl','advr_charge_handle.mdl','vr_round_rocket.mdl','advr_reload_bolt.mdl'])
    definitions=(ROOT/'QC_AD/game/defscustom.qc').read_text()
    names.update(re.findall(r'progs/([gv]_[A-Za-z0-9_]+\.mdl)',definitions))
    def write(p,data):
        if p.exists():
            if p.read_bytes()==data:return
            if backup:
                b=backup/p.relative_to(ROOT);b.parent.mkdir(parents=True,exist_ok=True)
                if not b.exists():shutil.copy2(p,b)
        p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    report=[]
    for name in sorted(names):
        data,origin=asset('progs/'+name)
        if data is None:raise RuntimeError('Missing weapon '+name)
        model=mdl.Model(data,name);write(dest/name,data)
        record={'model':name,'model_source':origin,'skins':[]}
        for k,(group,_,images) in enumerate(model.skins):
            for j,indices in enumerate(images):
                stem=name+'_'+str(k)+(('_'+str(j)) if group else '')
                pixels=source=None
                for ext in ['png','tga','jpg','pcx','lmp']:
                    pixels,source=asset('progs/'+stem+'.'+ext)
                    if pixels is not None:break
                if pixels is None:
                    w,h=model.skin_size
                    im=Image.frombytes('P',(w,h),flood(indices,w,h));im.putpalette(palette)
                    im=im.convert('RGB');source=origin+' embedded skin '+str(k)
                elif ext=='lmp':
                    w,h=struct.unpack_from('<ii',pixels);im=Image.frombytes('P',(w,h),pixels[8:]);im.putpalette(palette);im=im.convert('RGB')
                else:im=Image.open(io.BytesIO(pixels)).convert('RGBA')
                if pixels is not None and ext=='png':encoded=pixels
                else:
                    out=io.BytesIO();im.save(out,format='PNG');encoded=out.getvalue()
                write(dest/(stem+'.png'),encoded)
                maps=[]
                for suffix in ['_norm','_bump','_glow','_luma']:
                    for extmap in ['png','tga','jpg']:
                        bits,where=asset('progs/'+stem+suffix+'.'+extmap)
                        if bits is None:continue
                        if extmap!='png':
                            out=io.BytesIO();Image.open(io.BytesIO(bits)).save(out,format='PNG');bits=out.getvalue()
                        write(dest/(stem+suffix+'.png'),bits);maps.append(stem+suffix+'.png');break
                record['skins'].append({'texture':stem+'.png','size':list(im.size),'source':source,'sha256':hashlib.sha256(encoded).hexdigest(),'support_maps':maps})
        report.append(record)
    write(ROOT/'QC_AD/weapon-textures.json',(json.dumps(report,indent=2)+'\n').encode())
    print('Consolidated',len(report),'models and',sum(len(r['skins']) for r in report),'skin states')

if __name__=='__main__':main()

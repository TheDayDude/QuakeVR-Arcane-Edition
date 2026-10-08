"""Install a user-supplied loose texture pack as an isolated AD HD overlay.

Usage: python install_hd_textures.py SOURCE GAME
Requires Pillow. Does not modify launchers or overwrite different existing files.
"""
import argparse
import hashlib
import json
import shutil
import struct
from collections import Counter
from pathlib import Path
from PIL import Image


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def coverage(ad, names):
    maps = {}
    for pak in sorted(ad.glob('pak*.pak'), key=lambda p: int(p.stem[3:])):
        with pak.open('rb') as stream:
            magic, offset, size = struct.unpack('<4sii', stream.read(12))
            if magic != b'PACK':
                raise ValueError(f'Invalid PAK: {pak}')
            stream.seek(offset)
            for raw, at, length in struct.iter_unpack('<56sii', stream.read(size)):
                name = raw.split(b'\0')[0].decode('ascii')
                if name.startswith('maps/') and name.endswith('.bsp') and name.count('/') == 1:
                    maps[name] = (pak, at, length)
    for bsp in (ad/'maps').glob('*.bsp'):
        maps['maps/'+bsp.name] = (bsp, 0, bsp.stat().st_size)
    rows = []
    for name, (path, base, length) in sorted(maps.items()):
        with path.open('rb') as stream:
            stream.seek(base)
            header = stream.read(124)
            ent_at, ent_len = struct.unpack_from('<ii', header, 4)
            stream.seek(base+ent_at)
            if b'info_player_start' not in stream.read(ent_len):
                continue  # exclude brush-model BSP assets
            at, size = struct.unpack_from('<ii', header, 20)
            if at < 0 or size < 4 or at+size > length:
                raise ValueError(f'Invalid BSP texture lump: {name}')
            stream.seek(base+at)
            count, = struct.unpack('<i', stream.read(4))
            offsets = struct.unpack('<'+'i'*count, stream.read(count*4))
            textures = set()
            for offset in offsets:
                if offset < 0:
                    continue
                stream.seek(base+at+offset)
                tex = stream.read(16).split(b'\0')[0].decode('latin1').lower()
                if tex and not tex.startswith('sky'):
                    textures.add('#'+tex[1:] if tex.startswith('*') else tex)
        mapname = Path(name).stem.lower()
        matches = {}
        for tex in sorted(textures):
            for candidate in (f'textures/{mapname}/{tex}.tga', f'textures/{tex}.tga'):
                if candidate in names:
                    matches[tex] = candidate
                    break
        rows.append(dict(map=mapname, matched=len(matches), total=len(textures), textures=matches))
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('game', type=Path)
    args = parser.parse_args()
    source, game = args.source.resolve(), args.game.resolve()
    if not (source/'textures').is_dir() or not (game/'ad/pak0.pak').is_file():
        raise ValueError('Expected SOURCE/textures and GAME/ad/pak0.pak')
    target = game/'ad_hd'
    entries, names, dimensions, kinds = [], set(), Counter(), Counter()
    files = sorted(p for p in (source/'textures').rglob('*') if p.is_file())
    for path in files:
        if not path.resolve().is_relative_to(source):
            raise ValueError(f'Source leaves pack: {path}')
        rel = path.relative_to(source).as_posix()
        if rel.lower() in names:
            raise ValueError(f'Duplicate path: {rel}')
        names.add(rel.lower())
        entry = dict(path=rel, bytes=path.stat().st_size, sha256=digest(path))
        if path.suffix.lower() == '.tga':
            with Image.open(path) as image:
                image.load()  # decode every image before installation
                entry.update(width=image.width, height=image.height, mode=image.mode)
                dimensions[f'{image.width}x{image.height}'] += 1
            kinds[next((s for s in ('_luma', '_glow', '_norm', '_bump', '_gloss') if path.stem.endswith(s)), 'diffuse')] += 1
        elif path.suffix.lower() != '.txt':
            raise ValueError(f'Unexpected pack file: {rel}')
        dest = target/rel
        if not dest.resolve().is_relative_to(target.resolve()):
            raise ValueError(f'Destination leaves overlay: {dest}')
        if dest.exists() and digest(dest) != entry['sha256']:
            raise ValueError(f'Existing different file: {dest}')
        entries.append(entry)
    rows = coverage(game/'ad', names)
    print(json.dumps(dict(files=len(entries), bytes=sum(e['bytes'] for e in entries), dimensions=dimensions, kinds=kinds,
                         maps=[{k:v for k,v in r.items() if k != 'textures'} for r in rows]), indent=2), flush=True)
    for entry in entries:
        dest = target/entry['path']
        if not dest.exists():
            dest.parent.mkdir(parents=True, exist_ok=True)
            with (source/entry['path']).open('rb') as src, dest.open('xb') as out:
                shutil.copyfileobj(src, out, 1024*1024)
        if digest(dest) != entry['sha256']:
            raise ValueError(f'Copy verification failed: {dest}')
    (target/'manifest.json').write_text(json.dumps(dict(source=source.name, files=entries, maps=rows), indent=2)+'\n', encoding='utf-8')
    print('Installed and SHA-256 verified:', target, flush=True)


if __name__ == '__main__':
    main()

"""One authored bolt animation; derive the engine's mirrored rendering bank.

Metadata travels inside the MDL (ignored by Quake), not a fragile sidecar.
The importer exposes only the canonical poses. Reflection is triangle-local,
so it cannot shear a bolt when its geometry is edited.
"""
import json
import copy
from . import mdl

MAGIC = b'QVRBOLT1\n'


def metadata(model):
    if not model.trailing.startswith(MAGIC):
        return None
    return json.loads(model.trailing[len(MAGIC):])


def tag(model, original_frames, triangles):
    model.trailing = MAGIC + json.dumps(dict(original_frames=original_frames,
        bolt_triangles=sorted(triangles)), separators=(',', ':')).encode()


def canonical(model):
    info = metadata(model)
    if info:
        n = info['original_frames'] * 16
        if len(model.frames) not in (n, 2*n):
            raise mdl.MdlError('Incomplete bolt animation: expected %d or %d frames' % (n, 2*n))
        model.frames = model.frames[:n]
    return model


def expanded(model):
    """Return a runtime copy; leave the editable model and references unchanged."""
    info = metadata(model)
    if not info:
        return model
    result = canonical(copy.deepcopy(model))
    # Private render corners avoid reflection permutation conflicts at welded
    # edges. Blender welds these by position across all canonical poses.
    mappings = []
    left_triangles = []
    for ti in info['bolt_triangles']:
        ff, a, b, c = result.tris[ti]
        for side, sources in enumerate(((a,b,c), (a,c,b))):
            ids = []
            for v in sources:
                ids.append(len(result.st))
                # UV travels with its geometric corner, including seam flags.
                result.st.append(list(model.st[v]))
                mappings.append((side, v, a))
            if side == 0:
                result.tris[ti] = (ff, *ids)
            else:
                left_triangles.append(len(result.tris))
                result.tris.append((ff, *ids))
    if len(result.st) > 32767:
        raise mdl.MdlError('Bolt render corners exceed the 32767 vertex limit')
    # Reflection must fit the same grid. Reject instead of silently clamping.
    result.frames = []
    for side in (0,1):
        for f in model.frames:
            p = bytearray(f[2])
            for visible_side, src, collapse_to in mappings:
                # The inactive variant is zero-area, never an overlapping face.
                v = f[2][src*4:src*4+4] if side == visible_side else f[2][collapse_to*4:collapse_to*4+4]
                if side == visible_side == 1:
                    y = round((-model.place(v)[1] - model.origin[1]) / model.scale[1])
                    if not 0 <= y <= 255:
                        raise mdl.MdlError('Bolt reflection exceeds the MDL bounds; export with Grow Bounds')
                    normal = mdl.anorms()[v[3]]
                    v = bytes((v[0], y, v[2], mdl.nearest_normal((normal[0], -normal[1], normal[2]))))
                p.extend(v)
            header = bytearray(f[1])
            if side:
                header[8:24] = header[8:24].replace(b'b0', b'b1', 1)
            for axis in range(3):
                header[axis] = min(p[axis::4])
                header[4+axis] = max(p[axis::4])
            result.frames.append(['simple', bytes(header), bytes(p)])
    # Remember canonical topology; on import discard render-only corners.
    info = dict(info, canonical_vertices=len(model.st), canonical_triangles=model.tris,
        left_triangles=left_triangles)
    result.trailing = MAGIC + json.dumps(info, separators=(',', ':')).encode()
    return result


def editable(model):
    info = metadata(model)
    canonical(model)
    if info and 'canonical_vertices' in info:
        n = info['canonical_vertices']
        model.st = model.st[:n]
        model.tris = [tuple(t) for t in info['canonical_triangles']]
        for f in model.frames:
            f[2] = f[2][:n*4]
        tag(model, info['original_frames'], info['bolt_triangles'])
    return model

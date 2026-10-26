# Custom shotgun and Super Nailgun

These are the user's unmodified October 26 exports. Do not install them directly.
`tools/make_classic_vr_models.py` generates the base attachments and then calls
`tools/import_custom_weapons.py` to import these meshes and remap strip-order
muzzle/button/display anchors without moving their model-space targets.

The shotgun export declares two 116x192 skins, but stores a 128x194 first skin
followed by a 116x192 second skin. This misaligns geometry reads by 2560 bytes.
The importer recognizes this specific export and resamples only its first image
to the declared size. All exported vertex, triangle, UV, pose and normal data are
preserved. The existing HD texture uses normalized UVs and remains applicable.

The Super Nailgun is structurally valid. Its reordered vertices require new
attachment anchors. Its 32 poses retain the rotating barrels and hidden magazine;
the importer extracts the loose magazine from its edited removable geometry.

For subsequent exports, all embedded skins must share the header's dimensions.
Preserve the 32 Super Nailgun poses. Regenerate through the import pipeline to
update anchors; replacing an MDL alone does not update strip-order attachments.
The narrowly scoped repair intentionally does not guess at other malformed files.

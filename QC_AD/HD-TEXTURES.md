# Optional AD HD textures

The supplied `ad_hires_textures` collection is installed as loose files in
`QuakeVR/ad_hd/textures`, preserving map-specific folders and original pixels.
Its 3,846 TGA images occupy approximately 6.6 GB, with 26 original credit/readme
files preserved alongside them. No engine rebuild or image conversion is needed.

`QuakeVR-AD.bat` automatically loads this optional folder when present:

    -game quakevr -game ad -game ad_hd -game advr

The last game directory remains `advr`, so both launchers use the same saves,
settings and gameplay. `QuakeVR-AD-Standard-Textures.bat` omits the HD overlay.
To disable HD for the normal launcher, close the game and rename `ad_hd` to
`ad_hd-disabled`; restore its name to re-enable it. The original QuakeVR launcher
does not load this overlay.

The pack supplies 3,135 base images, 548 `_luma` maps, 24 `_glow` maps and 139
`_gloss` maps. Base images and glow/luma maps use the engine's existing loader;
map-specific images take precedence over generic ones. Standalone DarkPlaces
`_gloss` maps are preserved but are not consumed by this loader. Existing VR
normal-map generation and compatible external-material settings remain intact.
No authored normal/bump maps are supplied. Coverage is partial and varies by
map; unmatched surfaces retain their existing textures.

Installation is reproducible with Python and Pillow:

    python QC_AD/tools/install_hd_textures.py SOURCE QuakeVR

The installer decodes every image before copying, refuses different existing
files, and verifies every installed file by SHA-256. `ad_hd/manifest.json`
records filenames, hashes, sizes, image dimensions and installed-map texture
name matches (not visible surface area; excludes skies). Original source files
are retained. A changed future pack should be installed into a fresh overlay
after moving the previous overlay aside to avoid leftover replacements.

Loose files avoid this engine's 2,048-entry PAK limit and allow easy custom
texture edits. PK3 archives are not loaded by this engine. The earlier Jakub
Knave PK3 was not installed or merged into this collection.

HD textures increase texture memory use and can make first map loads slower,
especially while VR normal maps are generated. Use the standard-texture
launcher to compare headset performance without changing gameplay or saves.

Validation: all 3,846 images decoded successfully and all 3,872 installed source
files passed SHA-256 verification. A mock-VR session loaded `start`, `ad_e1m1`
and `ad_e2m2`, captured screenshots and exited normally. The engine's image
inventory confirms HD map-specific images, glow/luma and generated normal maps.
Headset performance still needs user testing.

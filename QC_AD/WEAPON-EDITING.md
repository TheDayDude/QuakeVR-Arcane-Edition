# Editing weapon models and textures

## One live location

Edit files in `QuakeVR/advr/progs`. Each model uses the PNG with the same filename
plus its skin number: `advr_base_shot.mdl` uses `advr_base_shot.mdl_0.png`.
There is no separate HD/standard artwork selection. Existing full-resolution
artwork is preserved; weapons that used embedded artwork now have PNGs too.

| Weapon | Live model |
| --- | --- |
| Shotgun | `advr_base_shot.mdl` |
| Super shotgun | `v_shot2.mdl` (also `vr_ssg_frame_on_v_shot2.mdl` and `vr_ssg_barrels_on_v_shot2.mdl`) |
| Nailgun | `advr_base_nail.mdl` |
| Super nailgun | `advr_base_nail2.mdl` |
| Grenade launcher | `advr_base_rock.mdl` |
| Rocket launcher | `advr_base_rock2.mdl` |
| Thunderbolt | `advr_base_light.mdl` |
| Plasma gun | `advr_plasma.mdl` |
| Crossbow | `advr_crossbow.mdl` |
| Widowmaker | `advr_widowmaker.mdl` |
| Shadow axe | `advr_shadowaxe.mdl` |
| Hammer | `advr_hammer.mdl` |
| Fury | `advr_fury1.mdl`, `advr_fury2.mdl` |
| Tome | `advr_tome.mdl` |

`weapon-textures.json` lists every consolidated model, its actual texture files,
image dimensions, and optional material maps. Numbered skins are functional
states, not quality alternatives. Do not delete them. `_norm`/`_bump` describe
surface relief and `_glow`/`_luma` describe emission; they are not replacement
color textures.

## Blender

1. Install `tools/quakevr_models.zip` through Blender Preferences > Add-ons >
   Install, then enable **Quake VR Models**. Tested with Blender 4.0.2.
2. Use **File > Import > Quake VR Model (.mdl)** from this add-on, rather than
   the generic Quake MDL importer. Import the live model from `advr/progs`.
3. Switch to Material Preview. The material loads the adjacent `_0.png`,
   including the shotgun's actual stock and grip artwork. Reimport old models
   to replace materials created by a different importer.
4. Edit the mesh and export with **Quake VR Model (.mdl)**. Keep the original
   name. Existing frames, UVs, vertex identities and attachment anchors are
   preserved. Do not apply topology-changing modifiers or delete animation
   shape keys casually: the pump, magazines and bolts use those frames.
5. Save texture painting with **Image > Save** before exporting geometry.
   Geometry export never resizes, quantizes or overwrites the PNG. Exporting
   to a new folder also copies the PNG and its material maps; it refuses to
   overwrite different existing artwork there.

The MDL format requires an embedded 8-bit skin. It remains compatibility data,
not another texture to edit. A generic importer will still show it; use this
importer to see the same full-color image the game loads. Removing that data
would make an invalid MDL. Keep the PNG beside the MDL when moving either file.

## GIMP and testing

### Charging bolts (Models add-on 1.2.0)

Reinstall `tools/quakevr_models.zip` and reimport the repaired nailgun, super
nailgun, plasma and Widowmaker models before editing. These models now contain bolt metadata.
The importer exposes one shared animation: 512 poses for each nailgun (16 bolt
positions times 32 firing/magazine states), and 16 each for plasma and Widowmaker. Edit the Basis to
carry a geometry adjustment through the motion. Export with **Quake VR Model**;
the scene's timeline range is not an export range.

The exporter derives the engine's left-hand rendering bank automatically from
that animation, keeping the handle on the same physical side of the gun.
Do not author a separate left-hand animation. The extra runtime vertex corners
keep triangle winding and your UV mapping correct during reflection; they are
hidden on import. Only one variant has visible faces per pose; the other is
collapsed to zero area, so the render copies cannot Z-fight.
UV seams and hard shading edges also require split file vertices. Do not delete
vertices merely because their positions match.

The face attribute `qvr_bolt` identifies the complete assembly (including its
stationary sleeve). It follows existing faces through edits and extrusion.
For newly created disconnected bolt geometry, set this face attribute to 1;
body faces should be 0. Keep the animation shape keys and use this add-on to
preserve the metadata. Generic MDL exporters can discard it or export only a
short, shifted timeline range, breaking the game's frame layout.

Moving a handle to a new location also requires updating its interaction point
in the engine (`vr_ad_base_ports.inc`, or the plasma/Widowmaker home in `vr_view.cpp`).
The mesh export does not silently rewrite gameplay code.

Open the matching PNG directly in GIMP, edit, and export back to that same PNG.
Keep its dimensions and UV layout unless deliberately remapping the model.
Restart the game to reload assets. Both game launchers use this same weapon
artwork; the Standard Textures launcher only omits the separate **world** pack.
The existing HD Weapon Rendering setting controls filtering, not which PNG loads.

Source-distribution copies are in `QC_AD/runtime/progs`; they are build inputs,
not another live override. After accepting manual edits, copy the matching MDL,
PNGs and maps there if you want them included in future distributions. Do not
rerun geometry generators over manual edits: those reconstruct models.

## Cleanup and recovery

Superseded loose weapon textures are archived outside the game in
`work/weapon-texture-cleanup/backup/redundant-textures`. Original PAK archives
remain intact. Their assets are overridden by the explicit `advr/progs` files.
No world textures, monster textures, or unrelated models were removed.

## Shotgun loading and ejection ports

The standard shotgun retains its 16 pump poses. The small inner plate in the
right receiver slides back with the pump; its outer rim stays fixed. The underside
loading mouth has a dark inset and metal rim using the existing skin. The engine
places the loaded-shell count over that inset when viewed from underneath.
Keep this area near model coordinates (3.65, 0, -3.11) when editing. Spent shells
eject at (4.2, -1.13, -1.13), halfway through the automatic 0.30-second pump cycle.
Original weapon UVs and texture files were preserved.

## Plasma top-loading cylinder

`advr_plasma.mdl` has 32 editable poses: loaded/empty pairs for each of the
16 bolt positions. Its glowing upper cylinder is the loaded cell; only that
surface collapses in empty poses. The left-hand bolt bank is derived as before.
`vr_mag_light.mdl` is now the complete removable cylinder, centered on its body,
with its axis along X. Its texture and normal maps are copies of the plasma gun
atlas; the original upper-half UV coordinates are retained. The top loading
contact is (4.090084, -0.039266, 0.508208) in weapon model space.

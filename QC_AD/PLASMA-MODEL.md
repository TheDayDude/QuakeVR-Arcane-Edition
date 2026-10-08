# AD Plasma Gun model

The held, holstered and dropped Plasma Gun now uses AD's `g_plasma.mdl`
geometry and its original indexed skin. The Thunderbolt remains separate.
This applies both to the AD upgrade and to plasma weapons dropped by enemies.

The conversion rotates the pickup model 180 degrees, removes its display
height, and scales it uniformly to a rifle-sized VR weapon. The mesh, UVs and
skin are preserved; normals are rotated too. Its one static frame is suitable
for tracked VR aiming: the engine supplies recoil, while projectiles and
reloads retain their existing gameplay. This is an adaptation of the supplied
art, not a new high-resolution model or a magazine-removal animation.

The engine installs slot 27's calibration once through `advr_defaults`, using
`advr_plasma_model_version`. It sets the muzzle at the barrel opening, the
support grip under the forward receiver, the stock brace, and the side-mounted
reload button/ammo display. Effective recoil/reload/weight settings are
preserved when detaching from the old Thunderbolt geometry. Later manual
calibration changes persist. The previous placeholder's normal map must be
removed because its UV layout is incompatible.

## Rebuilding or editing

Run `python QC_AD/tools/make_plasma_model.py PATH_TO_GAME/ad` against your
installed AD data. Later numbered PAKs and then loose files take precedence.
The generator writes `QC_AD/runtime/progs/advr_plasma.mdl` and
`Quake/vr/vr_ad_plasma.inc`. Rebuild the engine after regenerating calibration.
`make_upgrade_models.py` now only generates the Shadow Axe and Widowmaker
fallback skins, so it cannot overwrite this model.

For Blender, import the generated MDL with the repository's QuakeVR Models
add-on. Keep the triangle order when editing vertices to preserve strip-order
anchors; reselect/calibrate anchors after changing topology. The conversion
script documents its model-space transform and exact grip/muzzle points.

Use the regular QuakeVR-AD launcher. No new controller bindings are required.

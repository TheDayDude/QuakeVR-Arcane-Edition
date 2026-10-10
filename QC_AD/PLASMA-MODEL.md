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

The engine installs slot 27's calibration through `advr_defaults`, using
`advr_plasma_model_version`. It sets the muzzle at the barrel opening, the
support grip under the forward receiver, the stock brace, and the side-mounted
reload button/ammo display. Effective recoil/reload/weight settings are
preserved when detaching from the old Thunderbolt geometry. Version 2 lowers the support grip by 1.2 model units (about 4 cm) once on
existing installs; other calibration changes persist. Subsequent launches do
not repeatedly lower it. The previous placeholder's normal map must be
removed because its UV layout is incompatible.

## Rebuilding or editing

Run `python QC_AD/tools/make_plasma_model.py PATH_TO_GAME/ad` against your
installed AD data. Later numbered PAKs and then loose files take precedence.
The generator writes `QC_AD/runtime/progs/advr_plasma.mdl` and
`Quake/vr/vr_ad_plasma.inc`. Rebuild the engine after regenerating calibration.
`make_upgrade_models.py` is retired; all three AD upgrades now use dedicated native mesh converters.

For Blender, import the generated MDL with the repository's QuakeVR Models
add-on. Keep the triangle order when editing vertices to preserve strip-order
anchors; reselect/calibrate anchors after changing topology. The conversion
script documents its model-space transform and exact grip/muzzle points.

Use the regular QuakeVR-AD launcher. No new controller bindings are required.

## Independent weapon identity

Map Plasma Gun pickups now create an explicit plasma weapon record. The AD
progression flag may remain set, but it cannot change the model or attack of
other Thunderbolts in your hands, holsters or on the floor. Normal Thunderbolt
pickups remain normal after acquiring plasma. Physical plasma catches do not
spread the upgrade flag. Record kinds persist through save/load and level
changes. Old untyped lightning records are treated as Thunderbolts; acquire a
Plasma Gun pickup to obtain an explicitly typed plasma record.

Accepted map pickups replace the weapon in the touching hand (the main hand
for body pickups). A displaced weapon falls at the hand, retaining its record
and loaded ammo. Grabbing a physical weapon with an occupied hand follows the
same rule. Replacement drops are not damaging throws, and a short owner
pickup cooldown prevents immediately re-grabbing the displaced gun.

`tests/pickups-test.cfg` checks native AD callbacks, matching weapon-bit
replacement, both hands, independent lightning/plasma fire, ammo conservation,
and existing save/load, level-transition and weapon regressions.

Plasma magazine capacity is now 24 cells (24 shots); Thunderbolt remains 36.

## Recoil revision 3

Plasma now uses aim-affecting recoil like the Widowmaker. Strength is 5.5 versus 7, with a 0.8-second transient return versus 0.95. A full support-hand grip reduces each shot to 45% strength (2.475). Lingering aim rise caps at 18 degrees versus 25, and transient burst strength at 8 versus 10. Recovery pauses 0.65 seconds after firing and then removes 1.5 degrees per second. Sustained fire builds recoil; lowering the controller counters it. The Thunderbolt remains unchanged. Magazine capacity remains 24.

The mock VR runtime tests both one- and two-handed kick strengths and actual shot direction after transient recoil ends.

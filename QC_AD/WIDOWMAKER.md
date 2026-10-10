# VR Widowmaker

The Widowmaker now uses AD's `g_shot3.mdl` geometry and original skin as
`progs/advr_widowmaker.mdl`. The conversion preserves proportions and UVs,
removes the pickup's floating origin, and places the pistol grip at the hand.
Its approximately 1.15 m overall length is intentional. The VR weight profile
uses 6 kg, a 115 cm span and a 32 cm forward balance, versus the ordinary
Super Shotgun's 3.5 kg / 60 cm / 20 cm. This uses the existing weight simulation
and weapon collisions, without changing damage or firing cadence. Support the
forward grip with the empty second hand to steady it. Headset feel may warrant
further calibration through the existing weapon settings.

The Widowmaker is its own weapon record, separate from the Super Shotgun:

- Magazine: 24 shells, eight shots of three shells each.
- Fewer than three loaded shells cannot fire a reduced-power shot.
- Lower the held gun to a hip holster to reload with the standard reload mode.
- Standard reload buttons also work; the Super Shotgun's wrist-flick reload
  does not apply to the Widowmaker.
- The ordinary Super Shotgun keeps its two-shell capacity and flick reload.
- Picking up a Widowmaker does not convert other Super Shotguns.
- Identity and magazine contents persist through holsters, drops, catches,
  saves and level transitions. An occupied hand drops its previous weapon.

The Plasma Gun's magazine is now 24 cells (24 shots). The Thunderbolt retains
its 36-cell capacity. Existing excess loaded plasma rounds return to the
carried reserve when the magazine is clamped; total ammunition is preserved.

The launcher applies the model calibration once using
`advr_widow_model_version`; later manual adjustments persist. The old fallback
normal map is removed because it uses incompatible UVs. Old untyped upgraded
SSG records are treated as ordinary SSGs; a new Widowmaker pickup creates the
explicit identity.

## Rebuild / Blender

Run `python QC_AD/tools/make_widowmaker_model.py PATH_TO_GAME/ad` using the
installed AD PAKs. It writes the held MDL and `Quake/vr/vr_ad_widowmaker.inc`;
rebuild the engine after changing calibration. Import the generated MDL with
the repository's Blender add-on for further editing. Topology edits can change
strip-order anchor indices, requiring muzzle/button/display recalibration.

`tests/widow-test.cfg` exercises native pickup identity, both-hand firing,
eight-shot capacity, partial-magazine lockout, holster versus flick reload,
drop/catch, map parameters, and the existing save/load and combat regressions.

## Grip and recoil revision 4

The main grip is about 4 cm farther forward and 2 cm higher relative to the gun; the support grip rises about 3 cm relative to the mesh. The wrist-flick visual spin is disabled; reload behavior remains unchanged.

Recoil strength is now 7 with a 0.95-second transient return. Full second-hand support scales each shot to 45% strength (3.15). In addition, shots accumulate an upward offset (7 degrees unsupported, 3.15 supported, capped at 25). This offset waits 0.65 seconds after a shot before recovering at 1.5 degrees per second. Physically lowering the controller counters the rise. Both the transient and lingering rise affect actual shot direction and the drawn weapon; the headset view is unaffected. Switching away clears the effect. Other weapons retain their original visual recoil behavior.

`tests/forcegrab-visual-test.cfg` checks actual shot direction after the transient has ended in each stance, plus force-grab selection and a real-time flick/catch. `advr_selftest nailspin` exercises Super Nailgun frame cycling in both hands.

Revision 4 lowers the main hand about two finger widths relative to the trigger (model OffsetZ +1.1). The support grip follows the mesh and retains its relative placement. Recoil and reloading are unchanged from revision 3.

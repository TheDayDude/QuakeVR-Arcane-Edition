# Manual reloading in Arcane Edition

This is a selective adaptation of QuakeVR's immersive reload system, based on
upstream commit `76e28be1ea6976ec3209136bdb9468fc434102c9`. It retains AD's weapon
records, capacities, ammunition, custom models, and user-painted skins.

## Controls

Manual reloading is enabled once when this version is first launched through
`QuakeVR-AD.bat`. In VR settings, Weapons and Holsters → Weapon Reloading Mode
offers **Manual (Ammo Pouch)** alongside the existing holster modes and Off.
The console equivalent is `vr_reload_mode 3`; `vr_reload_mode 2` restores hip reloads.

1. Hold a gun in one hand and leave the other hand empty.
2. Grip the pouch at the front of your belt. It gives ammunition for that gun.
3. Bring the ammunition to the gun's loading point. The standard shotgun requires the shell within two Quake units of its receiver loading point. Loading gives a sound and a short rumble.
4. Grip works with either normal hold-to-grab or sticky grip. Release/toggle a
   round at the pouch to return it to your inventory, or elsewhere to drop it.
5. B/Y on the weapon hand ejects
   its magazine or remaining ammunition. Partially used magazines keep their remaining rounds.

Dropped ammunition can be picked up or force-grabbed. Ordinary held reload rounds
are returned before changing maps or switching to simple reload mode. Abandoned
rounds expire after three minutes; at most 48 unarmed loose reload props are retained.
Grenade traps do not use that expiry timer. Armed grenades always keep their fuse
and cannot be refunded; held grenades remain usable in simple reload mode.

| Weapon | Ammunition and insertion point |
|---|---|
| Shotgun | Single shells, under the receiver |
| Super shotgun | Shell pairs, at the exposed breech after breaking open |
| Widowmaker | Dedicated 24-shell box magazine under the receiver (eight shots) |
| Nailgun | Native magazine under the receiver |
| Super nailgun | Native box magazine under the receiver |
| Thunderbolt / Plasma gun | Energy cell, underside; capacities remain 36 / 24 |
| Grenade / Rocket launcher | Individual rounds, at the muzzle |
| Crossbow | One bolt, on the rail |

Magazines remain installed when empty and must be manually ejected before replacing them. Empty magazines drop as physical props but contain no ammunition. Only the rounds that fit are inserted; surplus remains
in the held prop. Launcher rounds and nailgun magazines must match their weapon.
Chainsaws and melee weapons retain their existing behavior.

## Charging magazine-fed weapons

After inserting a fresh magazine into either nailgun, Thunderbolt, Plasma Gun,
or Widowmaker, hold the empty hand's trigger near the small handle on the side
of the receiver. Pull it fully back, then release the trigger. This gesture is
the same with normal and sticky grip. Partial pulls do not chamber a round. An uncocked
weapon clicks instead of firing, and retains this state when dropped, holstered,
or carried to another map. Holster reload modes keep their existing behavior.

The redesigned nailguns and Thunderbolt use detachable versions of their native
AD decorative magazines, including the under-receiver Super Nailgun magazine.
The launchers retain their vertical foregrips. The standard shotgun has its full
stock and longer barrel; the break-open Super Shotgun is unchanged.

## Shotgun: pump after an empty reload

After the standard shotgun runs empty, insert fresh shells under the receiver.
Hold the pump with the support hand's grip, then squeeze its trigger to unlock
the sliding action. Keep grip and trigger held, pull the pump fully rearward,
then push it forward before releasing the trigger. Keep holding grip to support
the weapon afterward. The entire wooden pump, including its outer ribs, moves with
the stroke. Releasing at the rear or making a short stroke leaves the gun
unchambered; repeat the complete stroke to finish loading.

Only a reload from zero shells requires this action. Topping up a partly loaded
shotgun does not, and ordinary shots cycle the pump automatically. This works
with either hand and either grip mode. Non-manual reload modes remain automatic.

## Super Shotgun: break open, load, close

In manual mode, press B/Y on the Super Shotgun controller to break
it open. The barrels hinge downward and eject spent shells; any unfired shells
are ejected as recoverable ammunition. Take a shell pair from the belt pouch and
insert it at the exposed chambers. Flick or press B/Y
to close it. Loading does not automatically close the gun, and it cannot fire
while open. The physical red button no longer operates the breech. Opening/closing gives sound and haptics.

The Widowmaker uses a distinct shotgun-shell magazine. A partially used magazine
keeps its remaining shells when ejected or returned to the pouch. It cannot be
inserted into either other shotgun, and loose shell pairs cannot be loaded into
the Widowmaker. Its capacity remains 24 shells, firing three per shot.

The hinged Super Shotgun uses upstream's split-mesh generator applied to this
build's model, with the existing HD skin retained on the original surfaces.
Magazine pull/bump, two-hand pry/slap gestures, and loose-round contact loading
are not part of this selective port. Opening uses B/Y; closing accepts B/Y or a flick.
The existing hip-reload modes retain their previous behavior.

## Calibration

- `vr_ad_reload_pouch_forward` (3): pouch distance in front of the pelvis.
- `vr_ad_reload_pouch_up` (8): vertical adjustment relative to the hip holsters.
- `vr_ad_reload_pouch_reach` (7): pouch interaction radius in Quake units.
- `vr_ad_reload_port_reach` (6): loading-point interaction radius.
- Reload-point glow markers are disabled.

## Implementation and verification

`game/advr_reload.qc` owns ammo accounting, physical props, loading, and ejection.
Rounds outside a gun or inventory are deducted from AD's total immediately;
loading/refunding adds them back exactly once. Crossbow bolts use their separate
reserve. Weapon records retain their loaded counts when holstered or dropped.

The engine sends the rendered loading points and belt pouch position alongside
tracked hand poses. The hand carrying ammunition is marked occupied so it cannot
also take a two-handed grip, flashlight, climbing hold, or cast a spell.

The VR move packet has new fields. Use matching engine builds for multiplayer;
do not connect older Arcane Edition/QuakeVR clients to this build.

`advr_selftest manualreload` runs destructive inventory fixtures in a test game.
`manualinput` prepares a nailgun for a mock-controller pouch-to-port test;
`manualcheck` verifies the resulting magazine and total ammo. `manualview` gives
a nailgun and a loose magazine for visual inspection. These commands replace
the test player's inventory and are not intended for an ongoing campaign.

Reload prop models and feedback sounds are from upstream QuakeVR. Existing
The loose crossbow bolt is extracted from the loaded crossbow model; the AD grenade model is used for grenade rounds. No AI-generated artwork was
needed for this port.

Magazine fitting: magazines and cells use a centered six-unit-high mesh, with the same physical size in a hand, on the ground, and installed. Both nailgun magazines now share the box-magazine shape. Plasma and thunderbolt share the same cell. The Plasma Gun and Widowmaker load beneath the receiver between their grips. Existing default pouch placement migrates from 9 to 3 units forward; custom offsets are preserved.

Held reload props are excluded from hand collision response so shells remain attached without pushing the hand away. Crossbow reload bolts retain the loaded model's plain appearance and size; up to three reserve bolts are visible in the pouch. The nailgun magazine tilts eight degrees, and the Super Nailgun magazine projects from the left side. Widowmaker and Plasma support grips move forward onto their foregrip and under rail, including migration of existing settings.

Attempting to fire an empty ranged weapon plays a dry click, limited to twice per second per weapon. Empty magazines remain visible until ejected with B/Y.

Ammo pouch attachment: the pouch and its grab point follow the avatar pelvis directly, including locomotion, crouching and leaning. Forward adjustment is measured from the front of the pelvis; the default up setting of 8 places it at pelvis height. Pouch bolts share this frame.

## Super Shotgun breech controls
Press the weapon-hand secondary button (B on the right controller) to open the breech. Flicking cannot open it. An ordinary flick closes an already-open breech, using the original sensitivity; pressing the button again leaves it open.

## Hand grenades

Grenades are 22% smaller and centered on the hand. Reserve grenades are visible in
the rear grenade pouch and in the ammo pouch while holding the grenade launcher.

- Grip the rear pouch with an empty hand to take a grenade, even without a launcher.
  With the launcher in the other hand, the ammo pouch supplies the same grenade.
- Press that hand's trigger to pull the pin. It starts the configured hand-grenade
  fuse (2.5 seconds by default), with ticking, sparks and controller feedback.
  Trigger does not launch it. Release grip to throw or drop it; with sticky grip,
  press grip again. An armed grenade can explode while held.
- An unarmed grenade can still load the launcher or be returned to a pouch. Leave
  it elsewhere to make a trap: bullets, melee damage or an explosion set it off.
  Armed grenades cannot be loaded or refunded.
- Ogre grenades can be selected with an empty hand's trigger and force-pulled with
  a flick, then caught with grip and thrown back. Their fuse continues during the
  pull. The first catch grants at least the configured held-fuse time; repeated
  catches do not reset it. Returning one uses player grenade damage and attribution.

This is a selective adaptation of QuakeVR's grenade system at commit
`699ce4757086acc4fbed949a5fd938879a99304d`, retaining AD's projectile effects,
poison variants, damage rules and shared rocket-ammo accounting.


### Charging-handle controls (updated)
With the opposite hand empty, hold its trigger near the charging handle, pull the handle fully back, then release the trigger. This also applies with sticky grip enabled. Grip is reserved for supporting the gun. In manual reload mode, only B/Y ejects magazines or opens the Super Shotgun; touching the red button has no effect.

### Integrated Nailgun, Super Nailgun and Plasma actions
These three weapons have distinct handle/bolt meshes inside their held MDL files.
Their actions remain on the same physical side when changing holding hands.
The receiver sleeve stays fixed while the bolt and handle travel together.
A manual stroke plays `vr/bolt_pull.wav` when movement starts and
`vr/bolt_release.wav` on release. Every fired shot runs a silent 90 ms bolt cycle;
this does not change firing rate, magazine capacity or the manual reload gate.

For geometry editing, `tools/charging-bolts.json` identifies the receiver sleeve,
sliding bolt and handle vertex ranges in each model. Preserve all original skin,
UV and body vertices. Frame layout is `original_frame + original_frame_count *
(pull_step + 16 * left_hand_bank)`, with 16 travel steps. The second bank reflects
only the action to cancel holding-hand mirroring, including winding and normals.
The Nailgun and Super Nailgun each have 32 original firing/magazine frames;
Plasma has one. Do not discard magazine or left-hand banks during MDL export.

To regenerate from source, run `make_classic_vr_models.py GAME/ad`, then
`make_plasma_model.py GAME/ad`, then `make_charging_bolts.py` from `QC_AD/tools`.
The final command must run once on fresh base models. Its dimensions and shape
builders can be edited directly for repeatable future changes.

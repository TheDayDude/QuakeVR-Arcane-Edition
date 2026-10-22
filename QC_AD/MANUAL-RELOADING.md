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
5. B/Y on the weapon hand, or physically pressing the gun's red button, ejects
   its magazine or remaining ammunition. Partially used magazines keep their remaining rounds.

Dropped ammunition can be picked up or force-grabbed. Held rounds are returned
before changing maps or switching to simple reload mode. Abandoned rounds expire
after three minutes; at most 48 loose reload props are retained.

| Weapon | Ammunition and insertion point |
|---|---|
| Shotgun | Single shells, under the receiver |
| Super shotgun | Shell pairs, at the exposed breech after breaking open |
| Widowmaker | Dedicated 24-shell box magazine under the receiver (eight shots) |
| Nailgun | Box magazine, angled under the receiver |
| Super nailgun | Box magazine, left side of the receiver |
| Thunderbolt / Plasma gun | Energy cell, underside; capacities remain 36 / 24 |
| Grenade / Rocket launcher | Individual rounds, at the muzzle |
| Crossbow | One bolt, on the rail |

Magazines remain installed when empty and must be manually ejected before replacing them. Empty magazines drop as physical props but contain no ammunition. Only the rounds that fit are inserted; surplus remains
in the held prop. Launcher rounds and nailgun magazines must match their weapon.
Chainsaws and melee weapons retain their existing behavior.

## Super Shotgun: break open, load, close

In manual mode, flick the Super Shotgun or press B/Y on its controller to break
it open. The barrels hinge downward and eject spent shells; any unfired shells
are ejected as recoverable ammunition. Take a shell pair from the belt pouch and
insert it at the blue marker on the exposed chambers. Flick again or press B/Y
to close it. Loading does not automatically close the gun, and it cannot fire
while open. The physical red button can also open/close the breech when the
other hand is not carrying ammunition. Opening/closing gives sound and haptics.

The Widowmaker uses a distinct shotgun-shell magazine. A partially used magazine
keeps its remaining shells when ejected or returned to the pouch. It cannot be
inserted into either other shotgun, and loose shell pairs cannot be loaded into
the Widowmaker. Its capacity remains 24 shells, firing three per shot.

The hinged Super Shotgun uses upstream's split-mesh generator applied to this
build's model, with the existing HD skin retained on the original surfaces.
Magazine pull/bump, two-hand pry/slap gestures, and loose-round contact loading
are not part of this selective port. Opening/closing uses flicks or buttons.
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

Attempting to fire an empty ranged weapon plays a dry click, limited to twice per second per weapon. Empty magazines remain visible until ejected with B/Y or the physical red button.

Ammo pouch attachment: the pouch and its grab point follow the avatar pelvis directly, including locomotion, crouching and leaning. Forward adjustment is measured from the front of the pelvis; the default up setting of 8 places it at pelvis height. Pouch bolts share this frame.

## Super Shotgun breech controls
Press the weapon-hand secondary button (B on the right controller) to open the breech. Flicking cannot open it. An ordinary flick closes an already-open breech, using the original sensitivity; pressing the button again leaves it open.

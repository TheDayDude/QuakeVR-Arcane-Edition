# Enemy weapon drops

Launch the usual `QuakeVR-AD.bat`. Kill fresh enemies to get the new drops;
already-dead bodies in older saves do not generate retroactive loot.
Grab with an empty hand, or aim an empty hand, hold the trigger and flick to pull a
weapon toward you, then grip to catch it. Dropped weapons use the existing holsters and physics.

Default loot, at `vr_enemy_drops_chance_mult 1`:

| Enemy | Drop |
| --- | --- |
| Standard grunt | Shotgun, always |
| Crossbow Knight | Crossbow with 12 reserve bolts, always |
| Knight, death guard, fury knight, zombie knight, invisible sword | QuakeVR knight sword, always |
| Hellknight, blood/death/prince/sergeant knights, Quoth guard/death lord, Justice/Judicator | QuakeVR hellknight sword, always |
| Original or hunter chainsaw ogre | 25% chainsaw, 25% grenade launcher, 50% no weapon |
| Hammer ogre | 50% ordinary axe |
| Mace ogre | 50% grenade launcher |
| Plasma soldier, enforcer, eliminator, deflector, centurion | 50% plasma gun |
| Defender | 25% standard super shotgun, 25% grenade launcher, 50% no weapon |

The existing **Enemy Drops Chance** multiplier scales the overall chance,
clamped to 100%, without changing the split between alternatives. Zero disables
new weapon drops. Stone statues and point-knight map effects are excluded.
Only genuine deaths count: zombie knockdowns do not repeatedly award swords.
Gib deaths still drop weapons. Native AD ammo backpacks and map death targets
remain intact. Guns include a small loaded magazine (shotgun 4, SSG/GL 2,
plasma 12), in addition to the original backpack ammunition.

Swing swords to attack, and use them with the existing parry system. Knight
swords have base swing damage 35; hellknight swords 45, before swing-speed and
AD damage modifiers. Their contact traces use the calibrated blade tip.
An empty second hand can grip the hilt or blade for two-handed control. Releasing
the handle while the second hand holds on transfers the sword to that hand.
Axes and swords also deal impact damage when thrown with sufficient speed; a
gentle drop or a weapon resting against an enemy does not deal repeated damage.

Hold the chainsaw hand's trigger to run its cutting bar. It has its own fuel,
shown as its magazine/fuel amount, and can still be swung as a club when empty.
This adapter uses trigger startup; QuakeVR's pull-cord, fuel-transfer and
running-on-the-ground interactions are not ported. Reload does not refuel it.
Its original settings are respected:

- `vr_chainsaw_damage`: damage per second (default 80).
- `vr_chainsaw_fuel_use`: fuel percentage per second (default 5).
- `vr_chainsaw_drop_fuel_min`: minimum dropped fuel (default 40%; maximum 100%).
- `vr_dmg_chainsaw_swing`: unpowered swing damage (default 20).

The new weapon kinds survive hand swaps, holsters, dropping, save/load and
level changes, subject to AD's normal map inventory restrictions. A dropped
plasma gun does not turn an existing thunderbolt into plasma. Enemy axes and
SSGs likewise retain their ordinary model and damage even when the player has
Shadow Axe or Widowmaker upgrades. Existing AD map pickups keep their upgrade
behaviour. These use QuakeVR's existing sword/chainsaw models and the port's
converted AD Plasma Gun model; no new artwork was generated.

## Verification

`advr_selftest drops` is a destructive developer fixture for a disposable test
session. It checks the class/chance table, normal and gibbed native grunt
deaths, duplicate prevention, physical prop setup, sword pickup/holstering/
drop/catch and tracked damage, stationary chainsaw cutting and fuel use,
independent plasma projectiles, and spawn-parm preservation.
`advr_selftest dropsload` checks the resulting inventory after save/load or
changelevel. `tests/enemy-drops.cfg` runs these in mock VR alongside the
existing parry, weapon, reload and combat regressions. Headset feel still
requires user testing.

When a usable weapon drops, AD's decorative `w_*` weapon debris is suppressed for that enemy, including delayed death animations and subsequent corpse gibbing. Flesh, heads and other body debris remain. If the loot roll produces no usable weapon, native debris remains unchanged. This applies to newly killed enemies; existing decorative props in saved games are not removed.

The built-in weapon geometry is also hidden in death poses for the 20 installed
armed monster models: grunts, enforcer variants, sword/crossbow knights,
ogre variants, and Justice/Judicator. This follows original QuakeVR's mesh
approach and applies by monster model, even when its loot roll yields nothing.
Living poses, body geometry, skin mappings and HD texture paths are unchanged.
Zombie knights have no persistent death corpse: their real death gibs them;
their temporary knockdown poses retain the sword.

`tools/weapon-meshes.json` records the disconnected weapon vertices and QC death
frame ranges for AD 1.80. `tools/make_weapon_meshes.py <ad-pak-directory>` validates
the selections and generates the engine profiles and separate trailing weapon
bones. It also runs after the full ragdoll generator. The corpse renderer hides
those bones and physics does not create bodies for them, including deaths from
a non-death animation or an existing knockdown. Replacement meshes with different
vertex/triangle/frame counts are left intact rather than using these selections.

`vr_ragdoll_info skincheck` now additionally reports `RAGDOLL WEAPON PASS/FAIL`
for these dead creatures. `tests/ragdoll-skins.cfg` covers all 60 creature rigs,
including all 20 weapon-bearing models, texture continuity and corpse physics.
Restart the game and kill fresh enemies when checking the change in a headset.

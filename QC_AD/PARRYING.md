# AD weapon parries and projectile deflection

Launch with `QuakeVR-AD.bat`. This update needs both `ironwail-ad.exe` and
`advr/progs.dat`; the texture overlay and saved controller bindings are unchanged.

Hold an axe, Shadow Axe or sword roughly level across the incoming melee attack,
in front of your body. Guns, chainsaws, the grapple and empty hands cannot guard
or bat projectiles. Pointing the weapon straight at the attacker is not a guard. Either
hand works. The default guard removes 75% of the hit's damage; armor and AD's
other damage rules then apply to the remainder. A successful guard produces a
clang, sparks, controller feedback and a visible hand knock.

Swing the weapon through an incoming projectile to bat it away. The adapter
sweeps the projectile's path against a short history of weapon positions, so a
slightly early swing can still connect. Reflected shots belong to the player;
homing shots target their original shooter. Grenades retain their fuse. The
supported AD projectile callbacks cover physical pellets, spikes, bolts, lasers,
plasma, rockets, fireballs, homing missiles and ordinary grenades. Hitscan beams,
explosions, poison clouds, environmental damage and monster-spawning eggs are
not projectile batting targets.

Both hands use one stamina pool, displayed on the wrist gadget. A melee parry
or a projectile-batting effort spends it. Repeated hits from the same melee
attack share one charge; a volley intercepted by one batting effort also shares
a charge. Two-handed grips cost less. The final successful parry that empties
the pool drops the weapon, preserving its magazine and making it recoverable.
Picking it back up does not allow another parry until stamina starts recovering.
Breath sounds and haptic warnings signal low stamina and exhaustion.

Recovery uses the original settings: 100 maximum, a two-second rest before
recovery, and 25 points per second. Original default costs are 30 for one hand
and 12 for two; this installation's existing two-hand cost of 10 is preserved.
The existing VR settings menu controls `vr_parry`, `vr_deflect`,
`vr_parry_stamina`, their costs and recovery values. The AD defaults migration
enables the three feature switches once; subsequent user adjustments persist.
The climbing system can share the same stamina fields. This change does not
add stamina costs to AD's existing offensive melee swings.

Implementation adapts the original QuakeVR weapon guard geometry and stamina
rules to AD's hand records and calibrated weapon tips. Physical melee hit sites
call a dedicated adapter, leaving beams and radius damage on the native damage
path. Projectile callbacks retain their native effects, lifetimes, damage and
steering, with reflected ownership, stored flight direction and special boss
damage payloads updated as needed. No creature models or rigs are replaced.

Developer fixtures are in `game/advr_parry_tests.qc`; run
`exec parry-test.cfg` from `tests/parry-test.cfg` in a disposable mock-VR runtime.
They exercise native melee and projectile callbacks, both hands, stance rejection,
cooldowns, stamina costs, disarming and weapon identity, exhaustion bypass
prevention, recovery/HUD flags, swept contact, homing and straight-flight updates,
grenade fuse preservation, trace preservation, feature switches, and save/load.
Headset timing and physical feedback require playtesting.

Validation passed in the mock-VR runtime for the parry fixture and save/load,
plus the existing weapon, reload, holster/haptic, headshot, blood and physical-gib
regressions. The native AD melee helper and homing projectile touch/think callbacks
were exercised, including continued flight in the reflected direction.

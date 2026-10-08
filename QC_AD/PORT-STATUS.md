# Arcane Dimensions VR interaction fork

Local branch: vr-ad-integration. Engine base: a236bb0db193698d3fb558092ff137b152380c58. AD gameplay source: the supplied AD 1.80 patch pak2.pak. This remains a local fork; no GitHub repository has been published.

## Play

Start QuakeVR-AD.bat with the headset and OpenXR runtime ready. It opens AD's hub. AD's complete pak0/pak1/pak2 files remain in ad; the interaction layer, saves and settings live in advr. The original QuakeVR.bat is still available.

## Optional AD HD textures

The user-supplied AD HD collection is installed in `ad_hd/textures`. The normal AD launcher loads it automatically when present; `QuakeVR-AD-Standard-Textures.bat` starts with the previous textures and the same saves/settings. Original pixels, map-specific folders and author credits are preserved. See `HD-TEXTURES.md` for installation, supported material maps and disabling instructions. No engine or gameplay changes are required.

## Enemy weapon drops

The Plasma Gun now uses the converted AD `g_plasma.mdl` mesh and original skin in VR, replacing the tinted Thunderbolt fallback. Held weapons, holsters and enemy drops share its calibrated geometry, muzzle, support grip and ammo display. See `PLASMA-MODEL.md` for the reproducible converter and Blender editing notes.

Combat follow-up: heavy player hits now knock back mobile monsters using the original `vr_push`, `vr_hit_push` and `vr_kill_push` settings, scaled by creature size. AD's projectile pellets accumulate in a fixed 0.1-second window rather than multiplying the impulse, and a heavy hit interrupts a fiend's damaging leap. Bosses and anchored creatures remain in place. Swords support hilt/blade two-hand grips and transfer to the supporting hand on handle release. Thrown weapons use QuakeVR's release-speed/weight calculation and gravity, with one damaging impact per throw. Parrying and projectile batting are limited to axes, Shadow Axe and swords; guns, chainsaws, grapple and empty hands are excluded. `tests/impacts-test.cfg` exercises these changes in mock VR.

Grunts now drop standard shotguns. Sword-bearing knights and related AD enemies drop QuakeVR knight/hellknight swords. Ogres, plasma troops, enforcers and defenders have weapon-drop chances; hammer ogres can drop axes. All use the existing physical pickup, throwing and holster path. Distinct record kinds preserve swords, chainsaws, ordinary enemy SSGs/axes and plasma guns through saves and map transitions without granting global upgrades. Chainsaws have trigger-driven cutting and their own fuel; pull-cord startup and fuel transfer are not ported. See `ENEMY-DROPS.md` for the exact loot table, controls and validation. The source test is `tests/enemy-drops.cfg`.

## Weapon parries and projectile batting

Hold a weapon level across a monster's melee blow to reduce its damage, or swing through an incoming projectile to bat it back. Both hands work and share the original stamina pool, with cheaper two-handed guards, delayed regeneration, wrist-gadget status, low-stamina feedback and a recoverable weapon drop on exhaustion. Repeated hits from the same attack share one charge. Reflected projectiles retain native AD effects; homing shots return to their thrower and grenades keep their fuse. Beams, explosions and environmental damage bypass the guard. See `PARRYING.md` for controls, supported projectiles, settings and validation. Install both the engine and gameplay runtime for this update.

## Creature ragdolls

Ragdoll texture-density fix: the synthetic skeletal mesh now retains its source MDL's retro-texture grid, retro-lighting grid and model-specific texture overrides. Previously the native skeletal-model rule reduced the corpse's sampling grid to one quarter in each direction, making the same skin appear much coarser after death when retro rendering was enabled. Texture files and user rendering settings are unchanged. `vr_ragdoll_info skincheck` compares active corpses with their source models, checking shared diffuse/glow skins and actual retro shader inputs. Mock-VR validation passed for all 60 creature rigs, plus a check with retro rendering disabled. `QC_AD/tests/ragdoll-skins.cfg` provides the disposable-session fixture. This fixes corpse rendering; it does not create new HD monster or gib artwork from the map-surface texture pack.

AD's 60 installed creature meshes now have physics rigs. Limbed creatures use articulated bodies; limbless blobs, skulls and drones use a single physical hull. The rigs are derived from AD's existing vertex animations with anatomical templates and per-model head regions. No replacement creature models or textures are needed. These are approximate animation-derived rigs, so some unusual creatures may still need joint/skin tuning after headset testing.

Normal deaths hand the body to QuakeVR's Box3D physics after AD's death callbacks finish. Corpses respond to world collisions, physical objects, shots and explosions. AD retains kill counts, death targets, ammunition drops, corpse chopping, fade timers and overkill gibs. Gibbing an existing ragdoll removes its whole-body physics. Stone, robot and poison corpses do not emit the red flesh limb trails.

Exploding, disintegrating and scripted boss deaths retain their AD sequences instead of gaining an extra permanent body. Zombies' temporary collapses retain their get-up behavior. A rig exists for those models, but it is only activated when AD leaves a normal dead body. This release does not add corpse grabbing or live-monster knockdowns to the AD hand controls.

The existing `vr_ragdoll` switch controls the feature (1 on, 0 off); `vr_ragdoll_max` bounds simultaneous active ragdolls (original default 8). At capacity, the oldest dead ragdoll is removed so new deaths remain physical, matching base QuakeVR's replacement policy. Living monsters are never removed to make room. Existing user settings are preserved. Old port saves can initialize eligible corpses when their normal corpse update runs; start a fresh map for the clearest comparison.

Validation covers physical creation for all 60 meshes, exclusion of live/gibbed creatures, material-specific blood suppression, native soldier death callbacks and loot, save/load, cleanup, conversion from a ragdoll to physical gibs, and oldest-corpse replacement at capacity. Existing weapon/reload/holster/haptic and headshot/gib regression fixtures also pass. Full campaign, every death animation, and headset performance still require playtesting.

The reproducible generator is `QC_AD/tools/make_ragdolls.py`, with model/vertex/pose counts in `QC_AD/tools/ragdoll-coverage.json`. To regenerate against the supplied AD PAKs: `python QC_AD/tools/make_ragdolls.py C:/path/to/QuakeVR/ad` (numpy and Pillow). Generated skin assignments are in `Quake/vr/vr_ad_rigs.inc`; incompatible vertex/pose counts are rejected. Developer-only `QC_AD/tests/ragdoll-test.cfg` precaches the full roster in a disposable session.

## Headshots, blood and physical gibs

Headshot damage is enabled for 55 applicable monster models present in the supplied AD 1.80 pack. Model-specific regions use the standing-pose mesh; precise hits are mapped back from the actual animated triangle, including crouched/pain poses. Creature variants sharing a model share its region. The ambiguous boil, Floyd drone, Jim/Jimrock and tarbaby are left without a bonus. Source-only monsters whose assets are absent from this pack have no guessed profiles.

The existing `vr_positional_damage` setting enables the bonus and `vr_headshot_mult` controls it (original default 1.5). `vr_headshot_sound` controls feedback volume. Direct hits from shotgun pellets, nails, plasma, rockets, lightning and axe/melee use the bonus. Each shotgun pellet is evaluated separately. Explosion splash, environmental damage and damage over time get no head multiplier. AD armor, ammo resistances, scripted immunity, death triggers and special monster rules still apply. Boss profiles do not bypass their damage restrictions.

Normal red-blood hits now use QuakeVR blood effects, including surface splatters. AD's stone, metal, poison and other special-color effects remain AD's own effects. Overkills retain each monster's existing AD gib threshold and special death behavior. Standard fragments become rigid-body props after a short launch grace period; red flesh models use the existing VR blood trails, floor drops and impact splats. Special animated/damaging fragments retain AD behavior. At most 96 eligible gibs use this added physics at once; overflow retains ordinary AD bounce/fade. Pieces keep AD's normal cleanup lifetime.

Ordinary headshot kills do not sever heads. Overkill deaths can throw head gibs through AD's existing death routines.

Combat validation covers standing, rotated and crouched head hits, torso exclusion, collision-box fallback, disabled bonus, direct projectile damage, actual projectile-shotgun touch, mixed head/body pellet accumulation, splash exclusion, blood throttling, stone material preservation, overkill death counts, moving rigid gibs and gib save/load persistence. Head-profile validation checks all 55 entries against the installed model meshes. Full campaign and every monster animation still need playtesting; unusual profiles may need tuning from headset feedback.

Both the engine and gameplay runtime should be updated together for this release. The engine also supports precise collision for AD's small-projectile mode. The original QuakeVR executable remains unchanged.

## Holster feedback and B binding follow-up

Holster proximity now uses the original fading haptic pulse, independently for each hand. A held weapon near a holster or an empty hand near a stored weapon triggers feedback. Empty hands over empty holsters stay quiet. The existing vr_holster_haptics setting is respected: 0 off, 1 continuous, 2 once per entry; vr_holster_haptic_time controls the burst duration. Leaving and re-entering, or moving to another holster, triggers a fresh pulse.

B is unbound in AD gameplay after restoring the base VR bindings, so it no longer cycles weapons. Its menu Back behavior remains available. Restart with QuakeVR-AD.bat to apply this change.

Regression checks pass for haptic entry/reentry, independent hands, empty slots, off/continuous modes, B's unbound state, the existing weapon/reload tests, save/load and level transition. Physical haptic feel still needs headset testing. This follow-up changes gameplay/runtime configuration; the engine binary is unchanged.

The accompanying AD-VR-Model-Kit contains the three existing upgrade models, the repository's Blender add-on, a calibration snapshot and an editing checklist. No paid model generation was used. Blender UI/export compatibility has not been tested here.

## October 6 update: recoil, reloads, distinct upgrades

Recoil now uses QuakeVR's per-hand weapon effects: kick back, muzzle rise, recovery, and firing haptics. Each weapon has its own strength; the Widowmaker kicks harder than the regular double-barrel, and plasma has a light repeating kick. This moves the drawn weapon, not the headset or controller aim. Tune it through the existing Weapon Effects and Weapon Offsets > Effects settings. Initial defaults are applied once; subsequent recoil/model menu changes are preserved.

Reload using the base QuakeVR bindings:

- Main/right hand: click the right stick (RTHUMB).
- Off/left hand: X (XBUTTON).
- Move a held gun to a hip holster while keeping hold of it to reload.
- The double-barrel and Widowmaker also support a wrist-flick reload.
- A remains jump; grips grab/holster/drop; triggers fire their own hands.

Reload mode defaults to hip holsters (vr_reload_mode 2). Mode 1 permits every holster; mode 0 disables the magazine requirement. Button and supported flick reloads work in either enabled mode. There is a short reload pause and sound/haptic feedback. These are the original style of holster/button/flick reloads, not detachable magazine props.

| Weapon | Loaded capacity |
| --- | ---: |
| Shotgun | 8 |
| Double-barrel | 2 |
| Widowmaker | 3 |
| Nailgun | 24 |
| Super Nailgun | 36 |
| Grenade Launcher | 4 |
| Rocket Launcher | 4 |
| Lightning / Plasma | 36 |

Loaded rounds belong to each weapon record. Holstering, hand transfers, dropping, pickup, save/load and level changes preserve them. Reloading allocates existing carried ammo; it never creates rounds. Dropping a loaded weapon transfers those rounds to the dropped gun. Weapon screens show loaded/capacity and reserve; AD's ordinary inventory ammo remains total carried ammo. Map-specific weapon removal rules still apply.

The upgrades now have distinct handless VR skins: green Shadow Axe, copper/orange Widowmaker, blue Plasma Gun. They retain the calibrated VR geometry and grip/muzzle anchors, with AD's upgrade damage and firing behavior. These are recognizable VR variants, not reproductions of AD's original desktop silhouettes. Their source geometry is unchanged to avoid reintroducing baked-in hands or broken grips.

## Existing interaction support

Independent tracked weapons, six holsters, hand transfers, hold/sticky grips, throwing and catching, force-grabbing dropped weapons, physical melee, hand item pickups, and touchable buttons. Empty hands remain visible after holstering/dropping. Dropped weapons use calibrated held meshes, avoiding oversized pickup meshes. The AD launcher restores the VR bindings after AD's desktop configuration. Calibration runs in the current AD map; choose a safe area.

## Validation and limits

Release x64 engine and FTEQCC -O2 gameplay builds pass. Existing AD source still produces two CSQC deprecation warnings. Runtime checks cover all seven ranged weapons and both ranged upgrades, separate hand cooldowns, empty-magazine lockout, reload buttons/hip/flick, ammo conservation, drop/catch magazine transfer, partial-magazine serialization, holsters, empty-hand models, physical melee, actual AD health pickups, save/load, and a level transition into ad_e1m1.

A separate simulated-input run executes the controller-bound commands during normal server frames. It verifies firing/reloading both hands and the resulting magazines/reserve. The client reports per-hand recoil events and nonzero kick/rise through their recovery, including Widowmaker and Plasma. The upgraded models have been visually inspected in the game. Mock key events alone queue behind an exec script, so the scripted test uses the actual bound commands (+attack, +offhandattack, +reloadmain, +reloadoff).

Headset feedback confirms recoil and reloading work, along with the body/hands, holsters, aiming, firing, picking up and dropping. Force grab covers dropped weapons, not every map prop. Full campaign/boss coverage, grapple behavior and multiplayer remain unverified. Original AD and original QuakeVR saves are not interchangeable with this port. Existing port saves initialize missing magazine state from carried ammunition.

## Source and rebuild

QC_AD/game is adapted AD source; QC_AD/upstream is the extracted reference. AD credits/terms accompany the source. Commercial game PAK assets are not included in this source repository. The upgraded skins are generated from the repository's handless VR models, retaining all geometry and anchors.

From the source repository in PowerShell:

    ./QC_AD/build-port.ps1 -Fteqcc 'C:/path/to/fteqcc64.exe'
    ./QC_AD/build-engine.ps1 -LlvmBin 'C:/path/to/LLVM/bin'
    ./QC_AD/install-runtime.ps1 -GameDirectory 'C:/path/to/QuakeVR' -Engine ./build-ad/ironwail.exe

This update requires both the new engine and runtime files. The installer preserves the AD PAKs and user settings. Keep the original packaged DLLs, especially the repository's x64 libcurl.dll plus zlib1.dll.

Tested tools: LLVM 20.1.8 clang-cl, Visual Studio 2022 MSVC 14.37.32822, Windows SDK 10.0.22621.0, VS CMake/Ninja, FTEQCC 2026-07-13. Compiler/SDK binaries are not bundled. The engine script accepts version/path overrides. Do not use -Fautoproto with AD's source.

Regenerate upgrade models with Python:

    python QC_AD/tools/make_upgrade_models.py 'C:/path/to/QuakeVR/id1/pak0.pak'

Developer-only disposable-session tests are in QC_AD/tests. advr_selftest mutates the current game with fixtures; use only a throwaway session. The state/input/inputstate/upgrades/plasma variants support persistence and rendering tests. They are local and require developer 1. Settings migration version is advr_settings_version; resetting it to 0 and running advr_defaults reinstalls the feature defaults and variant calibrations.

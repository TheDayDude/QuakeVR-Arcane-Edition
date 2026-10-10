# AD VR weapon force grab

1. With an empty hand, hold trigger and point at a dropped weapon or a normal map weapon. A green pointer and highlight show the selected weapon.
2. While holding trigger, flick the wrist backward or upward to launch the selected weapon. Grip is not required. Trigger alone does not pull it.
3. Press grip when the weapon comes within reach to catch it. An open hand cannot catch it. If trigger is still held at the catch, release it before pressing again to shoot.

Releasing trigger before launch cancels the selection. Once launched, the weapon keeps flying with trigger and grip both released. Missing the catch restores the object so it falls normally. Newly blocked flight paths cancel rather than passing through walls. Each hand has independent targeting, flight and trigger rearming. Native map weapon callbacks retain AD pickup rules; shared map weapons in cooperative/deathmatch play are excluded, as in the original system. Dropped weapon records retain identity and loaded ammunition.

The adapter publishes the original force-grab protocol fields to reuse the engine's beam, outline and flight effects. It reuses the original backward/upward motion tests and flight timing cvars, with grip required only for the catch. The launcher installs green feedback once via `advr_forcegrab_version`; subsequent color/settings changes persist.

Validation: `advr_selftest forcegrab` covers both hands, trigger-only selection, trigger/flick launch, selection cancellation, released-trigger flight, grip-only catch, trigger rearm, native pickups, missed catches and disabled mode. `tests/forcegrab-visual-test.cfg` also drives a real mock-controller wrist flick and timed flight, with selection and catch screenshots. Existing pickup, reload, parry, combat, gib physics and save/transition regressions pass.

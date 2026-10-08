# AD VR weapon force grab

1. With an empty, open hand, hold trigger and point at a dropped weapon or a normal map weapon. A green pointer and highlight show the selected weapon.
2. Keep trigger held, squeeze grip to lock that selection, and flick the wrist backward or upward. Trigger alone, grip alone, and flicking without grip do not pull it.
3. Keep gripping while it flies into the hand. Release trigger before pressing it again to shoot. The selection press cannot fire the caught weapon.

Releasing trigger before launch cancels the selection. Releasing grip during flight cancels the pull and restores the object. Newly blocked flight paths cancel rather than passing through walls. Each hand has independent targeting, flight and trigger rearming. Native map weapon callbacks retain AD pickup rules; shared map weapons in cooperative/deathmatch play are excluded, as in the original system. Dropped weapon records retain identity and loaded ammunition.

The adapter publishes the original force-grab protocol fields to reuse the engine's beam, outline and flight effects. It reuses the original backward/upward motion tests and flight timing cvars, with the requested additional grip requirement before launch. The launcher installs green feedback once via `advr_forcegrab_version`; subsequent color/settings changes persist.

Validation: `advr_selftest forcegrab` covers both hands, trigger-only selection, gesture gates, selection cancellation, flight updates, identity-preserving catch, trigger rearm, native pickups, grip cancellation and disabled mode. `tests/forcegrab-visual-test.cfg` also drives a real mock-controller wrist flick and timed flight, with selection and catch screenshots. Existing pickup, reload, parry, combat, gib physics and save/transition regressions pass.

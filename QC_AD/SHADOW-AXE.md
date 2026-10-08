# Shadow Axe VR model

The held, holstered and dropped Shadow Axe uses the native AD `g_shadaxe.mdl` mesh and its original skin 4 (the skin selected by the AD pickup). It retains the original topology and UVs. The handle is rotated upright, uniformly scaled and centered around the tracked grip. The cutting edge is calibrated for melee and parrying. The incompatible old fallback normal map is removed.

Shadow Axe records have kind 8. Acquiring one leaves existing normal axes unchanged; the Shadow Axe retains AD upgraded melee damage and zombie-finishing hit classification. Dropping, catching, holstering and map-transition records preserve the weapon type. Normal axe records never inherit the Shadow Axe skin or damage from the player's global upgrade flag.

Rebuild the asset with `python QC_AD/tools/make_shadowaxe_model.py GAME/ad`; rebuild the engine to embed the generated `Quake/vr/vr_ad_shadowaxe.inc` calibration. `advr_defaults` applies geometry calibration once and preserves subsequent manual adjustments. The old tint generator is retired.

`advr_selftest shadow` exercises the actual native pickup callback, independent models, parry eligibility, physical drop/catch, holster and map-parm round trips. Existing old saves cannot reliably distinguish untyped axes that formerly shared a global upgrade: acquire a fresh Shadow Axe pickup for the new identity.

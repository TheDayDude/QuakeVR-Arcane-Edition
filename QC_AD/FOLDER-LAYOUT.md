# QuakeVR Arcane Edition folders

Launch QuakeVR-AD.bat. QuakeVR-AD-Standard-Textures.bat omits the optional AD world texture pack but uses the same VR weapon skins.

- id1: required base Quake assets.
- quakevr: required shared VR assets and configuration, loaded below AD. Retained separately to preserve AD override priority.
- ad: Arcane Dimensions content.
- ad_hd: optional HD world textures.
- advr: Arcane Edition gameplay, VR models, replacement weapon skins and player saves/settings.

Weapon PNGs are installed directly beside their models in advr/progs. These include the user's revised artwork; no separate ad_weapon_hd layer or original-skins launcher is needed. To replace a skin, overwrite its matching .mdl_0.png (or .mdl_1.png) file here.

The rogue and hipnotic mission-pack folders are not loaded by either AD launcher and have been removed. Base-game launchers are omitted from this AD-focused package. Do not delete id1 or quakevr.

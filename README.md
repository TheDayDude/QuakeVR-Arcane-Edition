# Quake VR: Arcane Edition

This is an unofficial fork of Vittorio Romeo's [vr-ironwail](https://github.com/vittorioromeo/quakevr/tree/vr-ironwail) made to run the mod Arcane Dimensions.

The base engine is [Ironwail](https://github.com/andrei-drexler/ironwail) and talks to your
headset through [OpenXR](https://www.khronos.org/openxr/).

Compatibility with AD:
I've taken the framework for VR weapons, physics and enemies and applied those to all monsters in arcane dimensions.

Additional features:
Usable Crossbows

## Building and installing

See [docs/BUILDING.md](docs/BUILDING.md) for Windows/Linux engine builds,
AD gameplay compilation, dependencies, and installation into an existing game.
Windows x64 has OpenXR headset support. Linux currently uses the mock VR backend.

This repository contains source, required build dependencies, and the AD overlay.
Full Quake/AD/QuakeVR game content and optional HD packs are supplied separately.
See [LICENSE.txt](LICENSE.txt), [credits](docs/vr-port/CREDITS.md), and the original
AD notices under `QC_AD/` for attribution and distribution terms.

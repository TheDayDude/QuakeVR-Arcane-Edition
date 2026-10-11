# Building Quake VR: Arcane Edition

## Supported targets

- Windows x64: engine with the OpenXR headset backend.
- Linux x86-64: engine with the mock VR backend. The current OpenXR backend uses
  Windows WGL; this cleanup does not add Linux headset support.

Use CMake 3.21 or newer and a C++23 compiler. Windows requires clang-cl, not
MSVC cl.exe. LLVM 20.1.8 was used for the local Windows build. Linux requires
GCC or Clang with C++23 support; its build has not been validated on this machine.

## Windows engine

Install Visual Studio 2022's C++ desktop workload, a Windows SDK, CMake/Ninja,
and LLVM with clang-cl and lld-link. The required SDL2, OpenXR and audio/curl
headers and Windows libraries are kept under `Windows/`.

In PowerShell:

```powershell
./QC_AD/build-engine.ps1 -LlvmBin 'C:\path\to\LLVM\bin'
```

The helper discovers Visual Studio and SDK versions. Use `-BuildDirectory` to
choose a different output directory. Output: `build/windows/ironwail.exe` and
its DLL dependencies. Copy the DLLs too, including `zlib1.dll`.

Alternatively, from an x64 Visual Studio developer shell with LLVM on PATH:

```powershell
cmake -S . -B build/windows -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl
cmake --build build/windows --parallel
```

## Linux engine

Install CMake, Ninja, a current C++23 compiler, pkg-config, SDL2 development
files and OpenGL development files. Debian/Ubuntu package names for the library
prerequisites are `libsdl2-dev libgl1-mesa-dev`. Optional audio/download support
uses `libcurl4-openssl-dev libvorbis-dev libmpg123-dev libopusfile-dev libflac-dev`.

```sh
cmake -S . -B build/linux -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
cmake --build build/linux --parallel
```

Use `gcc` and `g++` instead if preferred. Output: `build/linux/ironwail`.
The existing `Quake/Makefile` is retained as an alternative build path.

## AD gameplay (both platforms)

Install FTEQCC separately. The AD gameplay manifest is `QC_AD/game/progs.src`;
it is self-contained and does not need the original QuakeVR `QC/` directory.

```powershell
./QC_AD/build-port.ps1 -Fteqcc 'C:\path\to\fteqcc64.exe'
```

```sh
FTEQCC=/path/to/fteqcc sh QC_AD/build-port.sh
```

Both write `QC_AD/advr-progs.dat`. This generated binary is not checked in.
Developer fixtures in `QC_AD/tests` are retained because they test the AD port.
They need a complete playable installation; they cannot run with source alone.

## Runtime content and installation

This is a source-only repository. Supply your existing Quake installation with
`id1`, QuakeVR's `quakevr` assets, and a complete Arcane Dimensions `ad` folder.
HD packs are optional and are not included. The AD-specific overlay assets and
launch/configuration files remain in `QC_AD/runtime`.

On Windows, after building gameplay and the engine:

```powershell
./QC_AD/install-runtime.ps1 -GameDirectory 'C:\Games\QuakeVR' -Engine './build/windows/ironwail.exe'
```

The installer copies the AD overlay and engine; copy the engine build's DLLs
alongside it. Launch `QuakeVR-AD.bat`. On Linux copy `advr-progs.dat` to
`advr/progs.dat`, overlay `QC_AD/runtime/progs`, `advr_start.cfg` and `default.cfg`
into `advr`, then run from the game directory:

```sh
./ironwail -game quakevr -game ad -game advr -vrmock +exec advr_start.cfg
```

Steam Audio is optional. Its headers and notices remain under
`Quake/vr/external/steamaudio`; obtain the matching runtime using that directory's
README and put `phonon.dll` (Windows) or `libphonon.so` (Linux) beside the engine.
Without it the engine uses its normal audio fallback.

## Regenerating models and rig tables

The engine builds directly from checked-in generated tables. Regeneration is
optional and requires the original installed models plus Python and NumPy
(and Pillow for scripts that generate previews). `QC_AD/tools` contains the AD
converters. The two MDL readers they import remain under `Misc/quakevr`.

```sh
python QC_AD/tools/make_ragdolls.py /path/to/game/ad --base-models /path/to/game/quakevr/progs
python QC_AD/tools/make_weapon_meshes.py /path/to/game/ad
```

Retain `LICENSE.txt`, dependency notices, `docs/vr-port/CREDITS.md`, and the AD
readme/credits/changelog when redistributing this source. The AD readme contains
its source and asset terms; asset terms are not replaced by the engine license.

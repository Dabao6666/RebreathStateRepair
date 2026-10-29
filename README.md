# RebreathStateRepair (SKSE / CommonLibSSE NG)

An independent, no-ESP SKSE plugin source project intended to clear common player animation-state locks after a save has finished loading.

## Behavior

- Listens to SKSE `kPreLoadGame` and `kPostLoadGame` messages.
- After `kPostLoadGame`, queues the repair on SKSE's main-thread task queue and waits until the player 3D / animation graph are ready (up to 120 task retries).
- Runs once for that save load; the guard resets on the next `kPreLoadGame`.
- Sends only the minimal animation-graph stop/reset events `staggerStop` and `IdleStop`.
- Does **not** play the Taunt idle, Rebreath animation, or Elden Rim effects/resources; it does not use an ESP/ESL or any Elden Rim FormID.
- Writes `RebreathStateRepair.log` under the SKSE log directory.

This is a conservative first implementation based on the uploaded compiled PEX files' string tables and their ESP effect references. It targets animation/combat-state cleanup, not actor values, equipment, inventory, stamina, cooldown, perks, or save data.

## Compatibility target

CommonLibSSE NG, one plugin build intended for Skyrim SE 1.5.97 and AE 1.6.x. The source has not been compiled or run in a Skyrim process in this environment; build and in-game validation remain necessary.

## Build on Windows

Requirements: Visual Studio 2022 with *Desktop development with C++*, CMake 3.21+, Git, and vcpkg. Set `VCPKG_ROOT` to your vcpkg directory.

From this folder in a Developer PowerShell:

```powershell
cmake --preset release
cmake --build --preset release
```

Expected output: `build/Release/RebreathStateRepair.dll`.

To auto-copy the DLL into the game, set `SKYRIM_FOLDER` to the Skyrim install folder before configuring. Alternatively, copy the DLL manually to:

`Data\SKSE\Plugins\RebreathStateRepair.dll`

For Mod Organizer 2, install it as a separate mod containing that path. No ESP/ESL is needed. Launch Skyrim through SKSE64.

## Automated Windows build (GitHub Actions)

This repository includes `.github/workflows/build-windows.yml`. On a GitHub repository containing this project, push the files to `main`/`master`, or open **Actions → Build Windows SKSE DLL → Run workflow**. The workflow uses a Windows Server 2022 runner, bootstraps vcpkg (including the Color-Glass Studios registry configured in `vcpkg-configuration.json`), configures with the checked-in CMake preset, builds the DLL, and uploads `RebreathStateRepair-Windows-x64` as a workflow artifact. Download the artifact from the completed run.

The workflow has been added to the source package but has **not been executed from this Linux environment**; the DLL is not yet compiled or verified. A successful workflow run is required before treating the binary as usable.

## Test plan

1. Back up the affected save and test on a separate copy.
2. Enable the plugin and load that save once.
3. Check `Documents\My Games\Skyrim Special Edition\SKSE\RebreathStateRepair.log` (the exact SKSE log folder can vary by setup).
4. Verify that no Taunt/Rebreath animation or visual effect played, and that the broken state clears.
5. Reload the same save again and confirm the repair runs once again for that load, but does not repeat within the same load.

If the state remains stuck, capture the log and describe the exact symptom (e.g. unable to move, stuck in stagger, stuck in dodge, unable to attack). The reset list can then be narrowed or expanded without adding Elden Rim dependencies.

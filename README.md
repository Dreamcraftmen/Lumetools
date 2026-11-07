# Lumetools

**Lumetools** is a compatibility layer that lets a Windows game build run on
**macOS (Apple Silicon)** through **CrossOver**.

It bundles the runtime fix, the overlay DLLs, a configuration template and a
one-click launcher. The launcher builds its own CrossOver bottle, so there is
no manual Wine setup.

```
Windows game folder  +  Lumetools  ->  runs on macOS
```

---

## Table of contents

- [Background](#background)
- [Requirements](#requirements)
- [Installation](#installation)
- [How it works](#how-it-works)
- [Configuration](#configuration)
- [Repository layout](#repository-layout)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)

---

## Background

Three things break a Windows build when it is moved to macOS:

1. **Runtime architecture mismatch.** The shipped VC++ runtime DLLs are 32-bit,
   while the background service is 64-bit. The service aborts on startup with
   a missing export.
2. **Wine prefers its own DLLs.** Even with the correct 64-bit DLLs next to the
   executable, Wine loads its built-in copy unless an override is set.
3. **Hardcoded drive paths.** The game expects specific drive letters and
   folders that do not exist in a fresh CrossOver bottle.

Lumetools fixes all three, then starts the service and the game in the right
order, with leftovers cleaned up first.

---

## Requirements

| | |
|---|---|
| OS | macOS 13 or newer, Apple Silicon (M1 – M4) |
| Runtime | [CrossOver 26+](https://www.codeweavers.com/crossover) |
| Game | a working Windows game folder containing `bin/` |

---

## Installation

### 1. Copy the overlay

Copy **everything inside `copy-to-bin/`** into the game's `bin/` directory.

When macOS asks to overwrite `msvcr110.dll` / `msvcp110.dll`, **choose Replace**.

> **Back up your `Lumetools.ini` first if you already tuned one.** The package
> ships its own copy, so overwriting `bin/` replaces it.

### 2. Copy the launcher

Put `Lumetools.command` in the game root — one level above `bin/`.

```
your-game/
├── Lumetools.command      <- launcher
└── bin/
    └── ...                <- overlay files
```

### 3. Configure

Open `bin/Lumetools.ini` and fill in at least:

```ini
[dns]
default=your.server.address

[keychip]
id=YOUR-KEYCHIP-ID
```

Every section in the file is commented.

### 4. Run

Double-click `Lumetools.command`.

The first run is slower: it creates the bottle and installs the runtime.
Later runs go straight to the game.

> macOS may block the script the first time:
> **System Settings → Privacy & Security → Open Anyway**,
> or right-click the file → **Open**.

---

## How it works

The launcher performs these steps on every run:

| Step | Reason |
|---|---|
| Creates the `Lumetools` bottle if missing | the Windows environment the game runs in |
| Copies the 64-bit runtime into the bottle's `system32` | the shipped DLLs are 32-bit and the service is 64-bit |
| Sets `DllOverrides = native` for both runtime DLLs | without it Wine loads its built-in copy and the service aborts |
| Maps `Y:` to `~/Lumetools/Y` | the game config hardcodes that path |
| Mounts `C:\mount\Option` to `bin/option` | the game's option-data path |
| Migrates an older config file, if one exists | keeps existing settings instead of resetting them |
| Kills leftover processes, then starts service + game | a stale service makes the new one exit immediately |

Everything is logged to `bin/mac-run.log`.

---

## Configuration

`bin/Lumetools.ini` is the only file you normally edit.

| Section | Controls |
|---|---|
| `[dns]` | server address; optional `router` / `startup` / `billing` / `aimedb` / `replaceHost` |
| `[keychip]` | machine identity, LAN subnet, optional identifiers |
| `[netenv]` | simulated LAN adapter, MAC address |
| `[chuniio]` | input backend — keep exactly **one** `path=` active |
| `[aimeio]` | card reader driver (only for real serial hardware) |
| `[aime]` | virtual card reader on/off |
| `[gpio]` | cabinet type via dipsw1 / dipsw2 / dipsw3 |
| `[gfx]` | windowed / fullscreen, border, monitor |
| `[vfs]` | `amfs` / `option` / `appdata` paths |
| `[io3]` | TEST / SERVICE / COIN / IR key codes |
| `[ir]` `[slider]` | per-receiver and per-cell input mapping |
| `[led]` | LED board emulation |

### Cabinet type

`dipsw2` and `dipsw3` describe your hardware. A wrong value makes the
self-check validate a different machine type and fail, even when everything
else is correct.

| | `dipsw2` | `dipsw3` |
|---|---|---|
| 120 Hz display, SP cabinet | `0` | `0` |
| 60 Hz display, CVT cabinet | `1` | `1` |

---

## Repository layout

```
.
├── Lumetools.command      launcher (place in the game root)
├── copy-to-bin/           everything to copy into the game's bin/
│   ├── Lumetools.ini      configuration
│   ├── msvcr110.dll       64-bit runtime
│   ├── msvcp110.dll       64-bit runtime
│   ├── fix-dll.reg        registry fix (manual repair)
│   ├── inject_*.exe       loader
│   ├── *hook.dll          runtime patches
│   ├── chuniio*.dll       input backends
│   └── aimeio*.dll        card reader backends
├── LICENSE
└── README.md
```

---

## Troubleshooting

**`bin/inject_x64.exe not found`**
`copy-to-bin/` was not copied into `bin/`, or it was copied somewhere else.

**Black screen, no window**
Set `[gfx] windowed=1`. Fullscreen can be hard to escape.

**Quits right after the LED check**
Keep `[led] enable=0` and `[chuniio] path=chuniio-mux.dll` active.

**Crashes right after launch**
Usually more than one input backend enabled in `[chuniio]`. Keep only one.

**Self-check fails although the game starts**
`dipsw2` / `dipsw3` do not match the real display and cabinet type.

**"cannot be opened because the developer cannot be verified"**
Right-click `Lumetools.command` → **Open** → **Open**.

**Processes do not exit**
End the game and service processes, or restart the bottle.

---

## FAQ

**Do I need a controller?**
No. The default `chuniio-mux.dll` tries each backend and skips the ones with no
device attached; the keyboard keeps working.

**Does it contain any game files?**
No. Only the compatibility layer: runtime DLLs, overlay DLLs, the config
template and the launcher.

**Can I use my own CrossOver bottle?**
Yes, as long as it is a Windows 10 64-bit bottle named `Lumetools`.

**Where are the logs?**
`bin/mac-run.log`, overwritten on every launch.

---

## License

MIT — see [LICENSE](LICENSE).

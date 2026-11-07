# Lumetools v1.0.0

A drop-in overlay that lets a Windows game directory run on **macOS (Apple Silicon)**
through **CrossOver**.

The package fixes the runtime mismatch that makes the background service abort on
startup, pins the correct DLL, and ships a launcher that builds its own CrossOver
bottle on first run.

---

## Requirements

- macOS 13+ on Apple Silicon (M1 – M4)
- **CrossOver 26 or newer** — https://www.codeweavers.com/crossover
- A working Windows game directory that contains a `bin/` folder

---

## Install

```
your-game/
├── Lumetools.command      ← copy here (next to bin/)
└── bin/                   ← copy the contents of copy-to-bin/ into here
```

### 1. Copy the overlay

Copy **everything inside `copy-to-bin/`** into the game's `bin/` directory.

When macOS asks to overwrite `msvcr110.dll` / `msvcp110.dll`, **choose Replace**.

> **Back up your `Lumetools.ini` first if you already tuned one.**
> The package ships its own copy, so overwriting `bin/` replaces it.

### 2. Copy the launcher

Put `Lumetools.command` in the game root — one level above `bin/`.

### 3. Configure

Open `bin/Lumetools.ini` and fill in at least:

```ini
[dns]
default=your.server.address

[keychip]
id=YOUR-KEYCHIP-ID
```

Then adjust to taste:

| Want to change | Edit |
|---|---|
| Server | `[dns] default` |
| Controller | `[chuniio]` — keep exactly **one** `path=` active |
| Cabinet type | `[gpio]` — `dipsw2` / `dipsw3` |
| Display mode | `[gfx]` — `windowed` / `framed` |
| Data folders | `[vfs]` — `amfs` / `option` / `appdata` |

Every section is commented inside the file.

### 4. Run

Double-click `Lumetools.command`.

On the first run macOS may block it: **System Settings → Privacy & Security →
Open Anyway**, or right-click the file → **Open**.

---

## What the launcher does

| Step | Why |
|---|---|
| Creates the `Lumetools` bottle if absent | Windows environment for the game |
| Copies the 64-bit runtime into the bottle | The copies shipped with the game are 32-bit, while the background service is 64-bit and aborts on them |
| Sets `DllOverrides = native` | **Shipping the DLLs alone is not enough**; Wine prefers its built-in copy |
| Maps `Y:` → `~/Lumetools/Y` | The game's config hardcodes that path |
| Mounts `C:\mount\Option` → `bin/option` | The game's option-data path |
| Kills leftovers, starts service + game | A stale service makes the new one exit immediately |

---

## Controls without a controller

- `1` = TEST / confirm
- `2` = SERVICE / next item
- Touch strip mapped to `S D F G H J K L` (32 cells, left to right)

---

## First run inside the game

| Screen | Action |
|---|---|
| Waiting for settings from a base machine | Press `1` → settings menu → mark this machine as the base machine |
| LED board check shows `----` or `BAD` | Normal without LED hardware. Press `S` (counts as a touch) |
| Closing-time settings | Make sure it reads *every day / all hours* |

These are written to `bin/amfs/sysfile.dat` — a one-time step.

---

## Troubleshooting

**`bin/inject_x64.exe not found`**
`copy-to-bin/` was not copied into `bin/`, or it went somewhere else.

**Black screen / no window**
Set `[gfx] windowed=1`. Fullscreen can be hard to escape.

**Quits right after the LED check**
Set `[led] enable=0` and keep `[chuniio] path=chuniio-mux.dll` active.

**Crashes right after launch**
Usually more than one IO enabled in `[chuniio]`. Keep only the one you use.

**Right cabinet type but self-check still fails**
`dipsw2` / `dipsw3` must match the actual display refresh rate and cabinet type.
A wrong value makes the self-check validate the wrong hardware.

**"cannot be opened because the developer cannot be verified"**
Right-click `Lumetools.command` → Open → Open.

---

## What is not included

No game assets, no executables, no data files. The package only contains the
compatibility layer: the runtime, the overlay DLLs, the configuration template
and the launcher.

---

## License

MIT — see `LICENSE`.

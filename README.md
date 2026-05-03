# poopDeck

Mudlet package source for Achaea seafaring helpers.

## Current Status

This repository has been restarted from the previous Claude-generated OOP prototype. The old tree contained useful command strings, trigger patterns, and help text, but the implementation was not considered reliable:

- package manifests were incomplete or `null` in important parent folders
- OOP and legacy procedural code overwrote the same `poopDeck.*` globals
- several event handlers could recursively raise the same event they handled
- config was split between a plain table and an object depending on load order
- old docs and CI/release files overstated package readiness

Use [CODEX.md](CODEX.md) for agent workflow and [DESIGN.md](DESIGN.md) for the restart target.

## Intended Scope

The restarted package should provide:

- Sailing aliases for navigation, maintenance, safety, and weather commands
- Seamonster manual and optional automatic fire support
- Shot tracking and seamonster spawn-cycle reminders
- Light fishing convenience triggers
- Help/status output that matches the installed aliases

The active runtime now uses simple module tables under `poopDeck`: `config`, `output`, `sailing`, `combat`, `fishing`, and `help`.

## Command Surface To Preserve

Help:

- `poopdeck`
- `poopsail`
- `poopmonster`
- `poopfull`

Sailing:

- `sstop`
- `scast`
- `srow`
- `sreo`
- `sss <full|furl|relax|strike|0-100>`
- `stt <heading>`
- `dock <dir>`
- `wav <dir> <1-8>`
- `lanc`, `ranc`
- `lpla`, `rpla`
- `scomm on|off`
- `mainh`, `mains`, `mainn`
- `srep` / `srn`
- `shw on|off`
- `chop`
- `crig`
- `dour`, `doum`, `dous`
- `rain`
- `sres`
- `wind`

Seamonsters:

- `seaweapon <ballista|onager|thrower>`
- `autosea on|off`
- `seastop`
- `poophp <percent>`
- `firb`, `firbf`, `firf`, `firo`, `firsp`, `first`, `firc`, `fird`

The restart should either support both `firbf` and `firf` for ballista flare or deliberately choose one and keep docs/help/aliases synchronized.

## Development

Source of truth is `src/` plus `mfile`. Do not edit generated build artifacts.

Static checks:

```sh
find src -name '*.lua' -print0 | while IFS= read -r -d '' f; do luac -p "$f" || exit 1; done
find src -name '*.json' -print0 | while IFS= read -r -d '' f; do jq empty "$f" || exit 1; done
lua tools/smoke_runtime.lua
```

Build command, when Muddler and its local prerequisites are installed:

```sh
muddle
```

Real Mudlet smoke testing is required before calling the package releasable.

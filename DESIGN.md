# DESIGN.md

Design target for the poopDeck restart.

## Purpose
Build a reliable Mudlet package for Achaea seafaring workflows:

- Ship command shortcuts for navigation, maintenance, safety, and weather abilities.
- Seamonster combat assistance with manual fire commands, optional auto-fire, shot tracking, and spawn-cycle reminders.
- Light fishing convenience triggers.
- Clear help/status output that matches the shipped command surface.

The current repo contains useful trigger patterns and command strings, but the implementation is not a reliable foundation. The restart should preserve proven behavior and replace the architecture.

## Non-Goals
- Do not keep the current OOP/procedural hybrid.
- Do not implement a generic framework for all Achaea automation.
- Do not depend on external curing, queueing, or UI packages.
- Do not claim backward compatibility with undocumented internal globals.
- Do not add broad automation beyond seafaring, seamonsters, and existing fishing conveniences during the first restart pass.

## Prototype Assessment
Useful behavior was salvaged from the previous prototype before cleanup:

- Sailing aliases and outbound command strings.
- Seamonster monster health table, weapon commands, timers, and trigger patterns.
- Fishing trigger patterns and simple actions.
- Help command categories.

The previous implementation was removed as architecture:

- Parent manifests were incomplete or `null`, so package contents could be omitted.
- Legacy scripts and OOP classes overwrote the same `poopDeck.*` globals.
- Several event handlers recursively raised the event they handled.
- Config was both a plain table and an object depending on load order.
- CI/release files referenced missing version/docs and stale package assumptions.

## Current Restart Architecture
Use a simple module table layout under one namespace:

```lua
poopDeck = poopDeck or {}
poopDeck.state = {}
poopDeck.config = {}
poopDeck.output = {}
poopDeck.sailing = {}
poopDeck.combat = {}
poopDeck.fishing = {}
poopDeck.help = {}
```

Load order:

1. `00_poopDeck_Init.lua` - namespace, version, defaults, safe Mudlet API helpers.
2. `10_poopDeck_Output.lua` - output helpers only.
3. `20_poopDeck_Config.lua` - load/save and validation.
4. `30_poopDeck_Sailing.lua` - command helpers and ship prompt parsing.
5. `40_poopDeck_Combat.lua` - seamonster state, weapons, timers, curing safety.
6. `50_poopDeck_Fishing.lua` - fishing helper functions.
7. `60_poopDeck_Help.lua` - help/status renderers.
8. `70_poopDeck_Events.lua` - event registration, if events are needed later.

Avoid class ceremony unless it removes real complexity. Mudlet package code benefits more from deterministic load order, explicit state tables, and clear command handlers.

## State Ownership
`poopDeck.state` should own runtime-only state:

- `state.ship`: prompt-derived ship heading, speed, hull/sails, wind, sea, rowing, turning.
- `state.combat`: selected weapon, mode, firing, out-of-range, shot count, current monster, timers.
- `state.fishing`: optional fishing flags if needed.

`poopDeck.config` should own persisted user preferences:

- `sipHealthPercent`, default `75`.
- `autoFire`, default `false`.
- `selectedWeapon`, default `nil`.
- `maintainTarget`, default `"hull"` or `nil`, depending on final behavior.

Runtime state should not be persisted unless there is a clear user-facing setting.

## Event Policy
Events are optional glue, not the core state engine.

- Trigger scripts may call module handlers directly for simple behavior.
- If custom events are used, name them by source and lifecycle, for example `poopDeck.combat.outOfRange.detected`.
- A handler must not raise the same event it is registered to unless it has an explicit guard and documented reason.
- Prefer direct functions for alias command handling.

## Command Surface To Preserve
Initial restart should preserve the visible aliases unless the user asks to rename them:

- Help: `poopdeck`, `poopsail`, `poopmonster`, `poopfull`.
- Sailing: `sstop`, `scast`, `srow`, `sreo`, `sss <speed>`, `stt <heading>`, `dock <dir>`, `wav <dir> <distance>`.
- Ship management: `lanc`, `ranc`, `lpla`, `rpla`, `scomm on|off`, `mainh`, `mains`, `mainn`, `srep`, `shw on|off`.
- Safety: `chop`, `crig`, `dour`, `doum`, `dous`, `rain`, `sres`, `wind`.
- Seamonsters: `seaweapon <ballista|onager|thrower>`, `autosea on|off`, `seastop`, `poophp <percent>`, `fir<ammo>`.

Docs and help must match actual alias regexes. Do not document commands that do not exist.

## Core Behavior To Preserve
Sailing:

- Direction abbreviations expand to Achaea ship directions.
- Named sail speeds send verbal sail commands.
- Numeric sail speeds from 0-100 send `ship sails set <speed>`.
- Rigging-cleared trigger should send `queue add freestand climb rigging down`.

Seamonsters:

- Manual fire ammo:
  - `b`: ballista dart.
  - `bf` and/or `f`: ballista flare. Current docs imply `firf`, while current procedural code supports `bf`; the restart should deliberately support both or document one.
  - `o`: alternating onager spider/star shot.
  - `sp`: onager spidershot.
  - `c`: onager chainshot.
  - `st`: onager starshot.
  - `d`: thrower disc.
- Auto-fire selected weapon:
  - `ballista`: dart.
  - `thrower`: disc.
  - `onager`: alternate spidershot and starshot.
- Fire commands should maintain hull before loading/firing unless maintain behavior is explicitly redesigned.
- Curing must be restored when firing completes, is interrupted, goes out of range, or cannot proceed.
- Auto-fire should stop cleanly when no weapon is selected or health is below threshold.
- Monster spawn reminders keep the current intervals:
  - five-minute warning at 900 seconds.
  - one-minute warning at 1140 seconds.
  - spawn expected at 1200 seconds.

Fishing:

- Small/medium fish strike triggers tease line after a short delay.
- Large strike trigger sends repeated `jerk pole`.
- Reel recovery trigger sends `reel line`.
- Fish-size trigger displays the hooked size.

## Packaging Plan
The first cleanup/rebuild pass made the package structure installable in principle:

1. Replaced incomplete parent manifests with explicit folder entries.
2. Flattened script layout enough to make load order obvious.
3. Set `mfile.version` to an initial restart version.
4. Added static checks for Lua syntax and JSON validity.
5. Added `tools/smoke_runtime.lua` for initialization and critical command smoke coverage.

## Implementation Slices
Recommended restart order:

1. Done: docs and project contract: `CODEX.md`, `DESIGN.md`, accurate `README.md`.
2. Done: package skeleton: clean manifests, load-order-safe script modules, non-empty `mfile.version`.
3. Done: sailing MVP: aliases plus outbound commands, prompt parse/status, rigging-cleared behavior.
4. Done: seamonster manual fire MVP: settings, health threshold, curing-safe manual fire, weapon fired/interrupted/out-of-range handlers.
5. Done: initial auto-fire support: selected weapon, alternating onager state, range retry, spawn timers.
6. Done: fishing helpers.
7. Next: real Mudlet package install/build validation and release/build cleanup.

Each slice should leave the package buildable and the command/help/docs synchronized.

## Roadmap

- Expand maintain behavior beyond a static command prefix. Future maintain work should decide how `maintainTarget` interacts with combat firing, sailing maintenance aliases, and urgent ship conditions such as dead sails, damaged hull, fires, leaks, and tangled rigging.
- Add context-aware emergency controls to the GUI for common live sailing responses, such as clear rigging, rainstorm, douse sails, maintain sails, and maintain hull.
- Explore richer turn and crew-readiness state, including parsing turn progress/completion and crew-ready lines into GUI status instead of relying on scrollback.

## Validation Checklist
Host-side checks:

- Lua syntax check for all `src/**/*.lua`.
- JSON syntax check for all `src/**/*.json`.
- Manifest check that every Lua object has a manifest entry and every manifest leaf has a Lua file.
- Stub smoke for namespace initialization and selected command handlers.

Mudlet smoke checklist:

- Install package without errors.
- `poopdeck`, `poopsail`, `poopmonster`, and `poopfull` render help.
- `sss full`, `sss 5`, `sss 100`, `stt n`, `sstop`, `scast`, `crig`, and rigging-cleared trigger send expected commands.
- `poophp 75`, `seaweapon ballista`, `autosea on`, `autosea off` update settings and confirm output.
- `firb`, `firo`, `first`, `firsp`, `firc`, and `fird` send expected weapon commands when health allows.
- Low-health fire attempt restores or keeps curing on and does not mark combat stuck.
- Out-of-range and interrupted shot triggers restore curing and clear firing state.

## Open Questions
- Should the restart preserve the short aliases exactly, or introduce clearer long aliases alongside them?
- Should `maintain` affect combat firing commands, sailing maintenance commands, or both?
- Should auto-fire disable external curing with `curing off`, or should that be configurable?
- Should `ship status` remain as a first-class command in the initial MVP?

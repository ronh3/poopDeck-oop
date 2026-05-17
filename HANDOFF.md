# Codex Handoff

Date: 2026-05-17

## Current State

This repo is a Mudlet package for Achaea seafaring. Start by reading `CODEX.md`, `DESIGN.md`, and `README.md`.

The recent work was driven by `output.md`, a live sailing/combat log. There is no `outlook.md` in the repo root; `output.md` was used as the live log.

## Recent Changes

- Quieted package-issued commands by changing `poopDeck.safeSend()` to call `send(command, false)`.
- Added compact poopDeck output mode:
  - `poopgui output compact`
  - `poopgui output framed`
  - Compact lines are indented and marked as `    >>> [poopDeck] ... <<<`.
  - Compact output keeps existing severity colors.
- Replaced the GUI header with a danger summary:
  - `Sails ... | Hull ... | Fires ... | Rigging ... | Range ... | Combat ...`
- Added GUI refresh coalescing:
  - `poopDeck.refreshGui()` schedules one update on a short `0.05s` timer.
  - `poopDeck.updateGuiNow()` exists for immediate/synchronous repaint needs.
- Added Geyser label write caching:
  - `setLabel()` skips unchanged text/color writes.
  - `setLabelStyle()` skips unchanged stylesheet writes.
- Added roadmap notes in `DESIGN.md` for:
  - expanded maintain behavior,
  - context-aware emergency GUI buttons,
  - turn/crew readiness tracking.
- Version bumped to `1.0.19` in `mfile` and `src/scripts/00_poopDeck_Init.lua`.

## Files Touched In This Work

- `src/scripts/00_poopDeck_Init.lua`
- `src/scripts/10_poopDeck_Output.lua`
- `src/scripts/20_poopDeck_Config.lua`
- `src/scripts/60_poopDeck_Help.lua`
- `src/scripts/70_poopDeck_GUI.lua`
- `tools/smoke_runtime.lua`
- `README.md`
- `DESIGN.md`
- `mfile`

## Existing Dirty File

`src/scripts/55_poopDeck_Stats.lua` is modified in the worktree, but it was not part of the sailing UX/performance changes above. Do not revert it unless the user explicitly asks.

## Checks Run

The latest full verification passed:

```sh
find src -name '*.lua' -print0 | while IFS= read -r -d '' f; do luac -p "$f" || exit 1; done
find src -name '*.json' -print0 | while IFS= read -r -d '' f; do jq empty "$f" || exit 1; done
lua tools/check_version.lua
lua tools/smoke_runtime.lua
git diff --check
```

Observed successful output:

```text
version ok 1.0.19
smoke_runtime ok
```

## Notes For Next Codex

- `gui.update()` is still unified for full and compact modes. After label/style caching, splitting full vs compact update paths is probably not worth doing unless profiling shows GUI Lua string building is still hot.
- If optimizing further, better targets are config/default read behavior and cached output/theme tags.
- For live sailing UX, the next likely feature work is the `DESIGN.md` roadmap:
  - smarter maintain behavior,
  - emergency GUI controls,
  - crew readiness and turn tracking.
- Real Mudlet validation has not been performed in this session. Host-side checks pass, but do not claim release readiness without a Mudlet install/smoke pass.

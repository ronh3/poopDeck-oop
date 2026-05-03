# CODEX.md

Guidance for Codex and future agent sessions when working in this repository.

## Project Overview
- Standalone Mudlet package for Achaea seafaring, seamonster combat, and light fishing automation.
- Package metadata lives in `mfile`; keep `package`, `title`, `version`, and build behavior current.
- Packaged source of truth is under `src/` plus `mfile`.
- Target namespace: `poopDeck`.
- Treat this file as the durable agent continuity file. Keep architecture in `DESIGN.md`, user-facing behavior in `README.md`, and temporary debugging notes out of durable docs.
- The current OOP/procedural hybrid is not considered authoritative architecture. Preserve useful command strings, trigger patterns, and gameplay behavior, but prefer a clean restart over repairing the hybrid structure.

## Source Of Truth / Build System
- Work only in source files and manifests under `src/` plus repo docs and `mfile`; never edit generated `build/` artifacts or exported packages.
- `mfile.version` is the authoritative shipped version.
- Each Mudlet object folder needs an accurate manifest JSON: `scripts.json`, `aliases.json`, `triggers.json`, and so on.
- Manifest names must stay aligned with corresponding Lua filenames using the repo's naming convention.
- For Mudlet/Muddler JSON:
  - Double-escape backslashes in regex patterns, for example `"^\\d+$"`.
  - Keep parent and child manifest wiring accurate when files are added, removed, renamed, or moved.
  - Verify load-order-sensitive manifests manually instead of assuming generic sort order is safe.
- Build locally from repo root with `muddle` when available.

## Current Source Layout
- `src/scripts/` - clean module-table runtime under the `poopDeck` namespace.
- `src/aliases/` - current command surface and alias manifests.
- `src/triggers/` - current trigger patterns and scripts.
- `src/resources/` - package icon/resources.
- `tools/` - host-side smoke checks and future development helpers.

## Commands
- Startup reads:
  - `CODEX.md`
  - `DESIGN.md`
  - `README.md`
- Build:
  - `muddle`
- Static checks:
  - `find src -name '*.lua' -print0 | while IFS= read -r -d '' f; do luac -p "$f" || exit 1; done`
  - `find src -name '*.json' -print0 | while IFS= read -r -d '' f; do jq empty "$f" || exit 1; done`
- Smoke:
  - `lua tools/check_version.lua`
  - `lua tools/smoke_runtime.lua`
- Version checks:
  - `grep -n '"version"' mfile`
- Debug / failure context:
  - Inspect current aliases/triggers first; many failures are likely manifest wiring, load order, or recursive event bugs.

## Workflow Rules
- Analyze first. Read the smallest set of files that define the behavior before proposing or making changes.
- Use subagents liberally for bounded exploration, comparison, behavior inventory, verification, and review.
- Keep the main architectural reasoning in the primary thread when work affects public commands, trigger behavior, load order, package manifests, or shared runtime state.
- For non-trivial behavior or architecture work, summarize the intended slice before editing.
- Prefer coherent replacement slices over broad cleanup inside the current hybrid implementation.
- Keep manifests, loaders, docs, and related wiring synchronized in the same change when behavior crosses layers.
- When adding or changing commands, aliases, triggers, public APIs, event names, or state keys, update `README.md`, `DESIGN.md`, help output, and manifests in the same change.
- Preserve useful gameplay behavior from the current package, but do not preserve broken architecture for compatibility's sake.
- If runtime verification in Mudlet is unavailable, say so explicitly and fall back to static checks plus a host-side Mudlet API stub where practical.
- Respect dirty worktrees. Do not overwrite or revert unrelated user changes.

## Restart Direction
- The restart should be a single runtime model under `poopDeck`, not a mixed OOP/procedural global collision.
- The first implementation pass established deterministic package loading, clear state ownership, direct alias/trigger shims, accurate manifests, and a host-side smoke test.
- Useful current assets to salvage:
  - Sailing command aliases and outbound command strings.
  - Seamonster trigger patterns, weapon command strings, shot counting, and monster timer intervals.
  - Fishing trigger patterns and simple outbound commands.
  - Framed output/help styling, if simplified and made deterministic.
- Current assets to discard or rewrite:
  - The removed OOP class layer and duplicate legacy compatibility wrappers.
  - Recursive event handlers that listened for and raised the same event.
  - Stale release automation and docs that claimed the old implementation was production-ready.

## Versioning
- Treat `mfile.version` as the release version.
- Bump the patch version for every completed source/docs/config change unless the user explicitly says not to.
- Keep these fields synchronized on every bump:
  - `mfile.version`
  - `mfile.title` as `poopDeck Restart <version>`
  - `src/scripts/00_poopDeck_Init.lua` `poopDeck.version`
- Run `lua tools/check_version.lua` before final response after changes.
- Do not claim release readiness until a package build and Mudlet smoke checklist are available.

## Verification Priorities
- For manifest/package changes:
  - Verify parent/child manifest wiring.
  - Verify filename alignment.
  - Verify regex escaping.
  - Verify load order for namespace/init scripts.
- For runtime changes:
  - Run Lua syntax checks.
  - Run JSON checks.
  - Run or update a host-side Mudlet API stub for initialization and event flow.
  - Confirm no event handler raises the exact event it handles unless guarded and intentionally documented.
- For command changes:
  - Verify alias regex, help text, README command table, and outbound `send`/`sendAll` command all agree.
- For combat changes:
  - Verify curing is always restored after shot completion, interruption, out-of-range, unknown ammo, and missing weapon cases.

## Documentation Hygiene
- `CODEX.md` is for durable repo-specific agent rules and continuity only.
- `README.md` is for operator-facing commands, installation, and package overview.
- `DESIGN.md` is for architecture, boundaries, restart plan, and tradeoffs.
- Removed Claude-era files and changelogs are historical context only in git history.
- Do not store rolling session notes, active debug diaries, or long reference dumps in `CODEX.md`.

## Repo-Specific Notes
- Authoritative metadata/version file: `mfile`.
- Namespace/module: `poopDeck`.
- Build command: `muddle`.
- Primary smoke/test commands: static Lua/JSON checks plus future Mudlet smoke checklist.
- Mirrored version fields: `mfile.title`, `src/scripts/00_poopDeck_Init.lua`.
- Hybrid live-source paths outside `src/`: none.
- Special docs to read on startup: `CODEX.md`, `DESIGN.md`, `README.md`.
- Push/branch policy overrides: none.
- Testing authority overrides: real Mudlet runtime validation is required before release claims.
- Other durable constraints:
  - Keep the package installable before adding automation complexity.
  - Keep numbered runtime script prefixes synchronized with `src/scripts/scripts.json`.
  - Keep command behavior explicit and responsive; aliases should not fail silently.
  - Keep combat automation conservative around curing and player health.

# IMPORTANT: Re-read after context resets. Use this as the primary touchstone for Codex work here.

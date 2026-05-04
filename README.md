# poopDeck

poopDeck is a Mudlet package for Achaea seafaring. It provides sailing aliases,
seamonster combat helpers, fishing automation, a small Geyser status window, and
local stats for fish catches and seamonster kills.

## Features

- Sailing shortcuts for common ship commands, repair work, rigging, fires, and weather utilities.
- Seamonster firing helpers for ballista, onager, and thrower weapons.
- Optional automatic seamonster firing with health gating, range state, retry handling, and timer cleanup.
- Fishing triggers for baiting, casting, teasing, reeling, lost fish recovery, and caught-fish display.
- Geyser UserWindow status panel that shows ship, combat, and fishing state.
- Mudlet DB-backed stats for fish catches and seamonster kills.
- MDK TableMaker output for readable stats tables.
- agnosticDB theme integration for GUI and framed command output when agnosticDB is installed.

## Installation

Install the latest `poopDeck.mpackage` from the GitHub release page:

https://github.com/ronh3/poopDeck2/releases

In Mudlet, use `Package Manager` or `Module Manager` to install the `.mpackage`.
After installation, `poopdeck` prints the main help menu.

## Building From Source

This repo is built with Muddler. From the repository root:

```sh
muddle
```

The package is written to `build/poopDeck.mpackage`.

Source files live under `src/`; generated `build/` output should not be edited.

## Help Commands

| Command | Description |
| --- | --- |
| `poopdeck` | Shows the short help menu and top-level command groups. |
| `poopsail` | Shows sailing command help. |
| `poopmonster` | Shows seamonster command help. |
| `poopfull` | Shows all poopDeck help sections. |
| `ship status` | Prints the currently tracked ship and seamonster combat state. |

## GUI Commands

| Command | Description |
| --- | --- |
| `poopgui` | Shows GUI settings such as position, size, restore-layout mode, and theme source. |
| `poopgui theme adb` | Uses the active agnosticDB theme when agnosticDB is installed. |
| `poopgui theme runewarden` | Uses poopDeck's built-in Runewarden-style theme. |
| `poopgui theme default` | Uses poopDeck's neutral built-in theme. |
| `poopgui restore on` | Lets Mudlet restore the saved UserWindow position and size. |
| `poopgui restore off` | Uses poopDeck's configured spawn position and size instead of Mudlet's saved layout. |
| `poopgui pos <x> <y>` | Sets the GUI spawn position, for example `poopgui pos 80 80`. |
| `poopgui size <width> <height>` | Sets the GUI size, for example `poopgui size 720 360`. |
| `poopgui reset` | Restores default GUI position, size, and layout restore settings. |

The GUI automatically appears when poopDeck detects that you board a ship and hides when you disembark.

## Sailing Commands

| Command | Description |
| --- | --- |
| `sstop` | Sends the all-stop command sequence for the ship. |
| `scast` | Casts off. |
| `srow` | Orders rowing. |
| `sreo` | Relaxes oars. |
| `sss full` | Sets full sails. |
| `sss furl` | Furls sails. |
| `sss relax` | Relaxes sails. |
| `sss strike` | Strikes sails. |
| `sss <0-100>` | Sets sail percentage directly, for example `sss 35`. |
| `stt <heading>` | Turns the ship toward a compass heading such as `n`, `se`, or `wnw`. |
| `dock <dir>` | Docks in the given direction. |
| `wav <dir> <1-8>` | Uses wavecall in a direction with the given strength. |
| `lanc` / `ranc` | Lowers or raises the anchor. |
| `lpla` / `rpla` | Lowers or raises the plank. |
| `scomm on` / `scomm off` | Toggles the ship commscreen. |
| `mainh` | Maintains hull. |
| `mains` | Maintains sails. |
| `mainn` | Stops maintain work. |
| `srep` / `srn` | Starts ship repair work. |
| `shw on` / `shw off` | Toggles ship warning. |
| `chop` | Chops ropes. |
| `crig` | Clears tangled rigging and climbs back down after clearing. |
| `dour` | Douses the current room. |
| `doum` | Douses yourself. |
| `dous` | Douses sails. |
| `rain` | Calls rainstorm. |
| `sres` | Runs ship rescue. |
| `wind` | Uses windboost. |

poopDeck also parses ship prompts and `SHIP INFO` output to keep ship state current.

## Seamonster Commands

| Command | Description |
| --- | --- |
| `seaweapon ballista` | Selects ballista for automatic seamonster firing. |
| `seaweapon onager` | Selects onager for automatic seamonster firing. |
| `seaweapon thrower` | Selects thrower for automatic seamonster firing. |
| `autosea on` | Enables automatic seamonster firing. |
| `autosea off` | Disables automatic seamonster firing and clears active combat state. |
| `seastop` | Stops seamonster combat timers and clears firing/range state. |
| `poophp <percent>` | Sets the minimum health percentage required before poopDeck fires. |
| `maint h` / `maint hull` | Sets automatic seamonster firing to maintain hull. |
| `maint s` / `maint sails` | Sets automatic seamonster firing to maintain sails. |
| `maint n` / `maint none` | Clears automatic maintain target. |
| `firb` | Manually fires ballista dart. |
| `firbf` / `firf` | Manually fires ballista flare. |
| `firo` | Manually fires the selected alternating onager shot. |
| `firsp` | Manually fires onager spidershot. |
| `first` | Manually fires onager starshot. |
| `firc` | Manually fires onager chainshot. |
| `fird` | Manually fires thrower disc. |

poopDeck tracks shot count, firing state, range state, active monster type, and kill stats.

## Fishing

Fishing behavior is mostly trigger-driven rather than command-driven.

poopDeck watches for fishing lines that indicate baiting, casting, strikes, hooked fish,
line distance, lost fish, and landed fish. It updates GUI state and records caught fish
in the stats database.

The GUI includes buttons for common fishing actions:

| Button | Description |
| --- | --- |
| `Fcast` | Runs the queued fcast command. |
| `Medium` | Casts line at medium distance. |
| `Tease` | Teases the line. |
| `Reel` | Reels line in. |

## Stats Commands

| Command | Description |
| --- | --- |
| `poopstats` | Shows fish and seamonster overview tables for today, week, month, and all time. |
| `poopstats today` | Shows a compact overview for today. |
| `poopstats week` | Shows a compact overview for this week. |
| `poopstats month` | Shows a compact overview for this month. |
| `poopstats all` | Shows a compact all-time overview. |
| `poopstats fish` | Shows fish catch totals and biggest catches. |
| `poopstats fish <period>` | Shows fish stats for `today`, `week`, `month`, or `all`. |
| `poopstats fish <period> <type>` | Shows fish stats for one fish type. |
| `poopstats monsters` | Shows seamonster kill totals by type. |
| `poopstats monsters <period>` | Shows seamonster stats for `today`, `week`, `month`, or `all`. |
| `poopstats db` | Shows database backend and row counts. |
| `poopstats reset confirm` | Permanently deletes recorded fish and seamonster stats. |

Stats are stored with Mudlet's DB API when available. If the DB API is unavailable,
poopDeck falls back to session memory.

## Theming

If agnosticDB is installed, `poopgui theme adb` uses its current theme colors.
poopDeck also listens for `agnosticdb.theme.changed` and redraws the GUI when the
agnosticDB theme changes.

The stats table formatter is vendored from MDK's `fText` TableMaker. The package
includes the MDK license in `src/resources/LICENSE-MDK.lua`.

## Development Checks

Useful checks before packaging:

```sh
lua tools/check_version.lua
find src -name '*.json' -print0 | xargs -0 jq empty
lua tools/smoke_runtime.lua
```

Build the installable package with:

```sh
muddle
```

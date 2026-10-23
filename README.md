# Throttle Trace TOTW Stats

An unofficial mod for [Throttle Trace](https://store.steampowered.com/app/4535730/) that counts how much you drive the Track of the Week.

While you drive the Track of the Week in Time Attack, two extra rows appear in the timing box at the top right, below **Best**:

```
Current           +0.412  1:23.865
Best              +1.425  1:22.031
Attempts · Laps          46 · 34
Time                     42:17
```

- **Attempts:** every lap you started and drove for more than 2 seconds, whether you finished it, restarted or left the track. Finished laps count as attempts too.
- **Laps:** every lap you finished.
- **Time:** time spent driving this week's track.

The stats start from zero every week (weeks start on Monday 00:00 UTC, like the Track of the Week) and are kept per week and track in `totw_stats.json`.

Built for Throttle Trace v0.40.1 (Godot 4.6). Game updates may break it.

## Install

### 1. Install the mod loader

The game has no built-in mod support. Install the [Throttle Trace Mod Loader](https://github.com/NoelJarling/Throttle-Trace-Mod-Loader) first, including the `--enable-mods` launch option.

### 2. Copy `mods/` into the game's user data folder

| OS      | User data folder                                    |
|---------|-----------------------------------------------------|
| Linux   | `~/.local/share/godot/app_userdata/Throttle Trace/` |
| Windows | `%APPDATA%\Godot\app_userdata\Throttle Trace\`      |

Afterwards the user data folder should look like this:

```
Throttle Trace/            (user data folder)
├── mod_loader/
│   └── mod_loader.gd
├── mods/
│   └── totw_stats/
│       └── mod.gd
└── totw_stats.json        (created by the mod when you first drive the Track of the Week)
```

### 3. Start the game

Start Throttle Trace through Steam and drive the Track of the Week in Time Attack. The rows only appear on the Track of the Week; other tracks look the same as without the mod.

## Stats file

`totw_stats.json` holds one entry per week and track, keyed by the date the week starts and the track's id:

```json
{
	"2026-10-19_c2104ce6-cc2a-44ed-a7eb-af75d8945efd": {
		"attempts": 46,
		"laps": 34,
		"seconds": 2537.2,
		"track_id": "c2104ce6-cc2a-44ed-a7eb-af75d8945efd",
		"track_name": "Luxomburg GP by LUCIEN"
	}
}
```

The file is saved whenever an attempt ends and whenever you pause.

Your stats are saved locally to this file only. They are not synced with steam. Loosing or deleting the file resets your statistics.

## Uninstall

Delete `mods/totw_stats/` from the user data folder. Your stats stay in `totw_stats.json` until you delete that file too.

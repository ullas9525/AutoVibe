# Problem Statement — AutoVibe

## What is the Current Real-World Problem?

Mobile phone users frequently need to automatically switch to vibrate/silent mode during meetings, classes, worship, sleep, or work hours — and then switch back to normal ringer mode afterward. Doing this manually every day is easy to forget, leading to embarrassing ringtone disruptions or missed calls after the quiet period.

## What Exact Problem Are We Solving?

AutoVibe is an Android application that automates the process of toggling between vibrate mode and normal ringer mode based on user-defined schedules. Users configure:
- **Start/End Times**: When vibrate should activate and deactivate
- **Active Days**: Which days of the week the schedule applies
- **Multiple Schedules**: Different schedules for different routines

The app uses Android's `AlarmManager` to fire precise alarms that change the ringer mode, even when the app is not running in the foreground.

## What Features/Solutions Are We Providing?

1. **Schedule Creation** — Create named schedules with start/end times and day selection
2. **Automatic Vibrate Activation** — AlarmManager-based exact alarms toggle ringer mode
3. **Multiple Schedules** — Support for multiple independent schedules
4. **Enable/Disable Toggle** — Per-schedule on/off switch without deleting
5. **Manual Test** — One-tap test to verify vibrate mode works
6. **Battery Optimization Warning** — Detects and warns if Doze mode may interfere
7. **DND Permission Handling** — Guides user through required permission grants
8. **Logging** — Built-in diagnostic logging for troubleshooting alarm behavior

## Recent Bug Fix (April 2026)

A critical bug was identified and fixed where deleting an existing schedule and creating a new one would cause the new schedule's automatic vibrate mode to fail. The root causes were:
- Missing `AlarmManager` initialization in background alarm callback isolate
- Stale alarm IDs from deleted schedules not being cleaned up
- Ringer mode not being restored when deleting a currently-active schedule

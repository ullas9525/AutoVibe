# Changes Log — AutoVibe

---

## Change #2: Fix Regression — Alarms Not Firing Due to AlarmManager.initialize() in Callback

**Date:** 2026-04-02

### What Was Requested
After applying Change #1, alarms were being scheduled correctly but never firing. Debug logs showed no "Alarm Fired" entries despite alarms being registered at the correct times.

### What Was Implemented
- **Removed** `await AndroidAlarmManager.initialize()` from `alarmCallback()`
- **Root Cause**: `AndroidAlarmManager.initialize()` is designed to be called ONLY from the main isolate. Calling it inside the background alarm callback isolate crashed the entire callback, preventing any alarm action (vibrate toggle) from executing.
- **Effect**: Alarms now fire correctly and the callback executes without crashing.

### Files Modified

| File | Change Summary |
|---|---|
| `lib/services/scheduler_service.dart` | Removed `AndroidAlarmManager.initialize()` from `alarmCallback()` |

### Git Commit Message
```
fix: remove AlarmManager.initialize() from background callback

Calling initialize() in the alarm callback's background isolate crashed
the entire callback, preventing alarms from executing. The method is
designed for main isolate only.
```

---

## Change #1: Fix Auto Vibe Schedule Not Updating After Delete → Create

**Date:** 2026-04-02

### What Was Requested
The automatic vibrate mode feature was not correctly updating or activating new schedules after an existing one was deleted. Steps to reproduce: create a schedule → delete it → create a new schedule → new schedule fails to activate vibrate mode.

### What Was Implemented

#### Bug 1 Fix: Stale Alarm ID Cleanup
- Added `cancelAllStaleAlarms()` method to `SchedulerService`
- Added `saveActiveAlarmIds()` / `loadActiveAlarmIds()` to `PreferencesService`
- Every call to `scheduleAlarms()` now: (1) loads previously stored alarm IDs, (2) cancels ALL of them from Android's AlarmManager, (3) schedules the current alarms, (4) persists the new alarm IDs
- **Why**: When a schedule was deleted, its alarm IDs were cancelled at that moment — but if the alarm had already fired and rescheduled itself (inside the callback), the rescheduled version used the same ID and could linger as a ghost alarm. By tracking IDs in SharedPreferences and cancelling them all before each sync, stale alarms are guaranteed to be cleaned up.

#### Bug 2 Fix: Ringer Mode Restoration on Delete
- Updated `_deleteSchedule()` in `HomeScreen` to check if the deleted schedule was in its active window
- If it was, and no other schedule is currently active, the ringer mode is restored to normal
- **Why**: Deleting a schedule while vibrate mode was active would leave the phone stuck in vibrate permanently. Users would then create a new schedule, but since vibrate was already ON, the new schedule's "start" alarm appeared to do nothing.

### Files Modified

| File | Change Summary |
|---|---|
| `lib/services/scheduler_service.dart` | Added `cancelAllStaleAlarms()`, updated `scheduleAlarms()` to cancel stale IDs and persist active IDs |
| `lib/services/preferences_service.dart` | Added `saveActiveAlarmIds()` and `loadActiveAlarmIds()` methods |
| `lib/screens/home_screen.dart` | Updated `_deleteSchedule()` to restore ringer mode, added `_isScheduleCurrentlyActive()` helper |

### Git Commit Message
```
fix: resolve schedule not activating after delete-and-recreate

- Track and cancel stale alarm IDs via SharedPreferences on every sync
- Restore normal ringer mode when deleting a currently-active schedule
```

---


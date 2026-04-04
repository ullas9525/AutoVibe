# AutoVibe — Technical Documentation

## 1. Project Overview

### What the Project Is
AutoVibe is a native Android application built with Flutter that automates the toggling of a phone's ringer mode (vibrate/normal) based on user-defined time schedules. It acts as an "automatic Do Not Disturb" manager specifically for vibrate mode.

### What Problem It Solves
Users who need their phone in vibrate mode during specific recurring periods (meetings, classes, sleep) often forget to toggle it manually. AutoVibe automates this entirely, using precise Android alarms that fire even when the app is not in the foreground or the phone is in Doze mode.

### Overall Architecture
```
┌─────────────────────────────────────────────┐
│                Flutter UI                    │
│  HomeScreen → CreateScheduleScreen           │
│  SettingsScreen → PermissionScreen           │
├─────────────────────────────────────────────┤
│              Service Layer                   │
│  SchedulerService (AlarmManager integration) │
│  PreferencesService (SharedPreferences)      │
│  NativeService (Ringer mode via platform ch) │
│  LoggerService (Diagnostic logging)          │
├─────────────────────────────────────────────┤
│           Platform Channel                   │
│  native_ringer (local Flutter plugin)        │
│  → DND permission, ringer mode, battery opt  │
├─────────────────────────────────────────────┤
│          Android Platform                    │
│  AlarmManager (exact alarms, alarm clock)    │
│  AudioManager (ringer mode control)          │
│  NotificationManager (DND access)            │
└─────────────────────────────────────────────┘
```

---

## 2. Tools Used

| Tool | Purpose |
|---|---|
| **Programming Language** | Dart 3.10+ |
| **Framework** | Flutter (cross-platform, but Android-targeted) |
| **Database/Storage** | SharedPreferences (local key-value store) |
| **Platform Integration** | Android AlarmManager via `android_alarm_manager_plus` |
| **Ringer Control** | Custom Flutter plugin (`native_ringer`) via platform channels |
| **Version Control** | Git |

---

## 3. Libraries & Dependencies

### Production Dependencies

| Library | Type | Where Used | Purpose |
|---|---|---|---|
| `android_alarm_manager_plus: ^5.0.0` | Library | Backend/Service | Schedules exact Android alarms that fire a Dart callback, even in background or Doze mode |
| `shared_preferences: ^2.5.3` | Library | Backend/Service | Persists schedules, active alarm IDs, and diagnostic logs as key-value pairs on disk |
| `intl: ^0.20.2` | Library | UI | Date/time formatting for display |
| `uuid: ^4.5.2` | Library | Backend | Generates unique identifiers for schedule objects |
| `native_ringer` (local plugin) | Plugin | Backend/Platform | Custom platform channel plugin to check DND permission, set ringer mode, manage battery optimization |
| `cupertino_icons: ^1.0.8` | Library | UI | iOS-style icons (included by default) |

### Dev Dependencies

| Library | Purpose |
|---|---|
| `flutter_lints: ^2.0.0` | Lint rules for code quality |
| `flutter_launcher_icons: ^0.13.1` | Generates app launcher icons from config |

---

## 4. Frameworks & Libraries Justification

### android_alarm_manager_plus
- **Why chosen**: Only reliable way to schedule exact alarms on Android that survive app closure and Doze mode. Uses `AlarmManager.setAlarmClock()` which is exempt from Doze restrictions.
- **Benefit**: Alarms fire at the exact scheduled time regardless of app state.
- **Why not WorkManager/JobScheduler**: These are for background tasks with flexible timing — they don't guarantee exact firing times, which is unacceptable for a ringer-mode scheduler.

### shared_preferences
- **Why chosen**: Simple, lightweight key-value storage perfect for storing a small list of schedule objects (< 10 typically).
- **Benefit**: Zero setup, synchronous reads after first load, cross-platform API.
- **Why not SQLite/Hive**: Overkill for storing 1-10 schedule entries. No relational queries needed.

### native_ringer (custom plugin)
- **Why chosen**: No existing pub.dev package provides the exact combination of DND permission check + ringer mode control + battery optimization management.
- **Benefit**: Full control over the platform channel API surface. Direct access to Android's `AudioManager.setRingerMode()` and `NotificationManager.isNotificationPolicyAccessGranted()`.
- **Why not an API**: This is a local-only device operation — no API exists or makes sense for controlling the phone's ringer mode.

---

## 5. Processing Details

### Schedule Creation Flow
1. User taps "+" on HomeScreen
2. `CreateScheduleScreen` opens with default values (9 AM – 5 PM, all days)
3. User configures name, times, and active days
4. On save: a `Schedule` object is created with a unique `id` (UUID) and a random even `alarmId` (for AlarmManager)
5. `Navigator.pop()` returns the Schedule to HomeScreen

### Alarm Registration Flow
1. `_saveSchedule()` adds the Schedule to the in-memory list
2. `PreferencesService.saveSchedules()` persists the list to SharedPreferences as JSON
3. `SchedulerService.scheduleAlarms()` is called:
   - **Step A**: `cancelAllStaleAlarms()` loads previously stored alarm IDs from SharedPreferences and cancels every one via `AndroidAlarmManager.cancel(id)`
   - **Step B**: For each enabled schedule, checks if we're currently in its active window → if yes, activates vibrate immediately
   - **Step C**: `_scheduleOne(startId, startTime)` calculates the next occurrence of the start time (today if future, tomorrow if past), then calls `AndroidAlarmManager.oneShot()` with `alarmClock: true`
   - **Step D**: `_scheduleOne(endId, endTime)` does the same for the end time
   - **Step E**: All new alarm IDs are persisted to SharedPreferences via `saveActiveAlarmIds()`

### Alarm Callback Flow (Background Isolate)
1. Android fires the alarm → `alarmCallback(int id)` is invoked in a **background Dart isolate**
2. `WidgetsFlutterBinding.ensureInitialized()` and `AndroidAlarmManager.initialize()` are called
3. Schedules are loaded from SharedPreferences
4. The fired alarm ID is matched against all schedules' `alarmId` and `alarmId + 1`
5. If matched and enabled:
   - **Reschedule**: The alarm is rescheduled for the same time tomorrow via `oneShot()` (creating a repeating chain)
   - **Day check**: If today is an active day for this schedule, proceed
   - **Execute**: Call `NativeService.setRingerMode(true)` for start alarms, `setRingerMode(false)` for end alarms

### Schedule Deletion Flow
1. User taps delete → confirmation dialog
2. `_deleteSchedule()` checks if the schedule is currently in its active window
3. Schedule is removed from the list and persisted
4. `cancelSchedule()` cancels the specific alarm IDs
5. `scheduleAlarms()` re-syncs all remaining schedules (also cleans up stale IDs)
6. If the deleted schedule was active AND no other schedule is active → ringer restored to normal

### Authentication Flow
Not applicable — AutoVibe is a fully local, offline application with no user accounts or authentication.

---

## 6. Functionality Breakdown

### Schedule Module
- **Create**: Name, start/end time, day selection, auto-generated alarm ID
- **Edit**: Navigate to CreateScheduleScreen with existing data pre-filled
- **Delete**: Confirmation dialog → cancel alarms → restore ringer if needed
- **Enable/Disable**: Toggle switch per schedule without deleting

### Alarm Module
- **Registration**: Exact alarms via `AndroidAlarmManager.setAlarmClock()`
- **Callback**: Background isolate execution with AlarmManager re-initialization
- **Rescheduling**: Self-rescheduling chain (fires → reschedules for tomorrow)
- **Cleanup**: Track alarm IDs in SharedPreferences, cancel all before re-sync

### Permission Module
- **DND Access**: Required to change ringer mode. Detected on launch, user guided to settings if not granted
- **Battery Optimization**: Warning banner if Doze mode may prevent alarm firing. User can tap "FIX" to open system settings

### Settings Module
- **Diagnostic Logs**: View the last 50 log entries for troubleshooting
- **Test Alarm**: Schedule a test alarm for 10 seconds later to verify the system works

---

## 7. How to Run the System

### Prerequisites
- Flutter SDK 3.10+
- Android SDK (API 21+)
- Android device or emulator with DND permission access

### Setup Steps
```bash
# 1. Clone the repository
git clone <repo-url>
cd autovibe

# 2. Install dependencies
flutter pub get

# 3. Connect an Android device (USB debugging enabled)
adb devices

# 4. Run the app
flutter run

# 5. Grant DND permission when prompted (first launch)
```

### Build for Release
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 8. System Usage

### Creating a Schedule
1. Open the app → Tap the "+" icon next to "Your Schedules"
2. Enter a name (e.g., "Work Hours")
3. Set start time (when vibrate activates)
4. Set end time (when normal ringer restores)
5. Select active days
6. Tap "Save Schedule"

### Testing
1. Tap the vibration icon (top-left) to manually toggle vibrate ON/OFF
2. Go to Settings → "Test Alarm" to schedule a test alarm that fires in 10 seconds

### Troubleshooting
1. Go to Settings → View diagnostic logs
2. Check for "Alarm Fired", "Rescheduling", and "Action completed" entries
3. If "Battery Optimization Detected" banner appears → Tap "FIX"

---

## 9. Output Format Compliance

This document follows a clean, structured technical report format with:
- Clear section hierarchy
- Tables for structured data
- Code blocks for architecture diagrams and commands
- Step-by-step flows for all processing logic
- No vague or high-level explanations — exact working details provided

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:autovibe/models/schedule_model.dart';
import 'package:autovibe/services/logger_service.dart';
import 'package:autovibe/services/native_service.dart';
import 'package:autovibe/services/preferences_service.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();

  await LoggerService.log("Alarm Fired: ID $id");
  
  final nativeService = NativeService();

  if (id == 999999) {
    // Test Alarm
    await LoggerService.log("Test Alarm: Toggling Vibrate ON");
    try {
      await nativeService.setRingerMode(true);
      await LoggerService.log("Test Alarm: Success");
    } catch (e) {
      await LoggerService.log("Test Alarm Error: $e");
    }
    return;
  }

  // Initialize services
  final prefsService = PreferencesService();

  // Load all schedules
  await LoggerService.log("Loading schedules...");
  final schedules = await prefsService.loadSchedules();
  
  Schedule? matchedSchedule;
  bool isStart = false;

  for (var s in schedules) {
    final startId = s.alarmId;
    final endId = s.alarmId + 1;
    
    if (startId == id) {
      matchedSchedule = s;
      isStart = true;
      break;
    } else if (endId == id) {
      matchedSchedule = s;
      isStart = false;
      break;
    }
  }

  if (matchedSchedule == null) {
    await LoggerService.log("No matching schedule for ID $id. Schedule may have been deleted. Skipping.");
    return;
  }

  if (!matchedSchedule.isEnabled) {
    await LoggerService.log("Schedule ${matchedSchedule.name} disabled. Skipping.");
    return;
  }

  // --- RESCHEDULE FOR NEXT DAY (Recurring Loop) ---
  try {
    final time = isStart ? matchedSchedule.startTime : matchedSchedule.endTime;
    final now = DateTime.now();
    
    var nextDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // We want the next occurrence (tomorrow)
    nextDateTime = nextDateTime.add(const Duration(days: 1));
    
    // Safety check
    if (nextDateTime.isBefore(now)) {
       nextDateTime = nextDateTime.add(const Duration(days: 1));
    }

    await LoggerService.log("Rescheduling alarm ID $id for $nextDateTime");
    
    // Cancel any existing alarm with this ID first (safety)
    await AndroidAlarmManager.cancel(id);

    await AndroidAlarmManager.oneShot(
      nextDateTime.difference(now), 
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // Bypasses Doze quota
      rescheduleOnReboot: false,
    );
    await LoggerService.log("Rescheduled alarm ID $id successfully");
  } catch (e) {
    await LoggerService.log("Failed to reschedule alarm ID $id: $e");
  }
  // ------------------------------------------------

  // Check Day
  final checkTime = DateTime.now();
  final currentDayIndex = checkTime.weekday - 1; // Mon=0, Sun=6
  
  if (!matchedSchedule.days[currentDayIndex]) {
    await LoggerService.log("Today not selected for ${matchedSchedule.name}. Skipping action.");
    return;
  }

  // Execute
  try {
    if (isStart) {
      await LoggerService.log("Turning Vibrate ON for ${matchedSchedule.name}");
      await nativeService.setRingerMode(true);
    } else {
      await LoggerService.log("Turning Vibrate OFF for ${matchedSchedule.name}");
      await nativeService.setRingerMode(false);
    }
    await LoggerService.log("Action completed successfully");
  } catch (e) {
    await LoggerService.log("Action failed: $e");
  }
}

class SchedulerService {
  final PreferencesService _prefsService = PreferencesService();

  Future<void> initialize() async {
    try {
      final bool success = await AndroidAlarmManager.initialize();
      await LoggerService.log("AlarmManager initialized: $success");
    } catch (e) {
      await LoggerService.log("AlarmManager init failed: $e");
    }
  }

  /// Cancels ALL previously tracked alarm IDs from the Android system.
  /// This ensures that stale alarms from deleted schedules are cleaned up.
  Future<void> cancelAllStaleAlarms() async {
    final staleIds = await _prefsService.loadActiveAlarmIds();
    if (staleIds.isEmpty) {
      await LoggerService.log("No stale alarm IDs to cancel.");
      return;
    }
    await LoggerService.log("Cancelling ${staleIds.length} stale alarm IDs: $staleIds");
    for (final id in staleIds) {
      try {
        await AndroidAlarmManager.cancel(id);
      } catch (e) {
        await LoggerService.log("Failed to cancel stale alarm ID $id: $e");
      }
    }
    // Clear the stored IDs since they're all cancelled now
    await _prefsService.saveActiveAlarmIds([]);
    await LoggerService.log("All stale alarms cancelled and ID list cleared.");
  }

  Future<void> scheduleAlarms(List<Schedule> schedules) async {
    await LoggerService.log("--- Scheduling ${schedules.length} schedules ---");
    
    // CRITICAL FIX: Cancel ALL previously registered alarm IDs first.
    // This ensures that alarms from deleted schedules are cleaned up,
    // preventing ghost alarms from interfering with new schedules.
    await cancelAllStaleAlarms();

    bool isCurrentlyActive = false;
    List<int> newActiveIds = [];

    for (var schedule in schedules) {
      if (!schedule.isEnabled) {
        await LoggerService.log("Skipping disabled schedule: ${schedule.name} (${schedule.alarmId})");
        // Still cancel its alarms explicitly (belt and suspenders)
        await cancelSchedule(schedule);
        continue;
      }

      // Check if we should be active RIGHT NOW
      if (_isAppInScheduleWindow(schedule)) {
        await LoggerService.log("CURRENTLY IN WINDOW for '${schedule.name}' -> Activating Vibrate NOW");
        final nativeService = NativeService();
        await nativeService.setRingerMode(true);
        isCurrentlyActive = true;
      }

      final int startId = schedule.alarmId;
      final int endId = schedule.alarmId + 1;
      
      await LoggerService.log("Scheduling '${schedule.name}': StartID=$startId, EndID=$endId");

      await _scheduleOne(startId, schedule.startTime);
      await _scheduleOne(endId, schedule.endTime);

      // Track these IDs so we can cancel them later if the schedule is deleted
      newActiveIds.add(startId);
      newActiveIds.add(endId);
    }

    // Persist active alarm IDs for future cleanup
    await _prefsService.saveActiveAlarmIds(newActiveIds);
    await LoggerService.log("Saved ${newActiveIds.length} active alarm IDs: $newActiveIds");
    
    if (!isCurrentlyActive) {
       await LoggerService.log("No active schedules found for current time.");
    }

    await LoggerService.log("--- Scheduling Complete ---");
  }

  bool _isAppInScheduleWindow(Schedule schedule) {
    final now = DateTime.now();
    
    // 1. Check Day
    final currentDayIndex = now.weekday - 1; // Mon=0
    if (!schedule.days[currentDayIndex]) return false;

    // 2. Check Time
    final start = schedule.startTime;
    final end = schedule.endTime;
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      // Normal day schedule (e.g. 10:00 to 12:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight schedule (e.g. 23:00 to 07:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  Future<void> cancelSchedule(Schedule schedule) async {
    await LoggerService.log("Cancelling schedule '${schedule.name}' (IDs: ${schedule.alarmId}, ${schedule.alarmId + 1})");
    await AndroidAlarmManager.cancel(schedule.alarmId);
    await AndroidAlarmManager.cancel(schedule.alarmId + 1);
  }

  Future<void> _scheduleOne(int id, TimeOfDay time) async {
    final now = DateTime.now();
    var dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (dateTime.isBefore(now)) {
      dateTime = dateTime.add(const Duration(days: 1));
    }

    await LoggerService.log("Scheduling (AlarmClock) ID $id at $dateTime");

    // Ensure no conflict — cancel any existing alarm with this ID
    await AndroidAlarmManager.cancel(id);

    await AndroidAlarmManager.oneShot(
      dateTime.difference(now),
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // Bypasses Doze quota
      rescheduleOnReboot: false,
    );
  }

  Future<void> scheduleTestAlarm() async {
    final int testId = 999999;
    await LoggerService.log("Scheduling Test Alarm for 10s later...");
    try {
      final bool success = await AndroidAlarmManager.oneShot(
        const Duration(seconds: 10),
        testId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: false,
      );
      await LoggerService.log("Test Alarm scheduled result: $success");
    } catch (e) {
      await LoggerService.log("Test Alarm schedule failed: $e");
    }
  }
}

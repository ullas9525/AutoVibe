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

  // We need to match the ID. Since we mask IDs now, we need to be careful.
  // But wait, we can't easily reverse the hash.
  // We have to re-calculate hash for all schedules and see which one matches.
  
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
    await LoggerService.log("No matching schedule for ID $id");
    return;
  }

  if (!matchedSchedule.isEnabled) {
    await LoggerService.log("Schedule ${matchedSchedule.name} disabled");
    return;
  }

  // --- RESCHEDULE FOR NEXT DAY (Recursive Loop) ---
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

    await LoggerService.log("Rescheduling $id for $nextDateTime");
    
    await AndroidAlarmManager.oneShot(
      nextDateTime.difference(now), 
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // Bypasses Doze quota
      rescheduleOnReboot: false,
    );
  } catch (e) {
    await LoggerService.log("Failed to reschedule: $e");
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
  Future<void> initialize() async {
    try {
      final bool success = await AndroidAlarmManager.initialize();
      await LoggerService.log("AlarmManager initialized: $success");
    } catch (e) {
      await LoggerService.log("AlarmManager init failed: $e");
    }
  }

  Future<void> scheduleAlarms(List<Schedule> schedules) async {
    await LoggerService.log("--- Scheduling ${schedules.length} schedules ---");
    
    bool isCurrentlyActive = false;

    for (var schedule in schedules) {
      if (!schedule.isEnabled) {
        await LoggerService.log("Skipping disabled schedule: ${schedule.name} (${schedule.alarmId})");
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
    }
    
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

    // LoggerService.log("Checking Window for ${schedule.name}: Now=$nowMinutes, Start=$startMinutes, End=$endMinutes");

    if (startMinutes < endMinutes) {
      // Normal day schedule (e.g. 10:00 to 12:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight schedule (e.g. 23:00 to 07:00)
      // Active if after start (23:00+) OR before end (00:00 - 06:59)
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

    await LoggerService.log("Scheduling (AlarmClock) $id at $dateTime");

    // Ensure no conflict
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

  // Helper methods removed as we use alarmId directly

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

import 'package:autovibe/models/schedule_model.dart';
import 'package:autovibe/screens/create_schedule_screen.dart';
import 'package:autovibe/screens/permission_screen.dart';
import 'package:autovibe/screens/settings_screen.dart';
import 'package:autovibe/services/native_service.dart';
import 'package:autovibe/services/preferences_service.dart';
import 'package:autovibe/services/scheduler_service.dart';
import 'package:autovibe/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nativeService = NativeService();
  final _prefsService = PreferencesService();
  final _schedulerService = SchedulerService();

  bool _dndGranted = false;
  List<Schedule> _schedules = [];
  bool _testToggleState = false; // For manual testing
  bool _isBatteryOptimized = false;

  @override
  void initState() {
    super.initState();
    _checkDnd();
    _checkBatteryOptimization();
    _loadSchedules();
  }

  Future<void> _checkDnd() async {
    final granted = await _nativeService.checkDndPermission();
    setState(() {
      _dndGranted = granted;
    });
  }

  Future<void> _checkBatteryOptimization() async {
    // Returns true if IGNORING optimization (good).
    // So if it returns false, we are OPTIMIZED (bad).
    final isIgnoring = await _nativeService.isIgnoringBatteryOptimizations();
    setState(() {
      _isBatteryOptimized = !isIgnoring;
    });
  }

  Future<void> _loadSchedules() async {
    final schedules = await _prefsService.loadSchedules();
    setState(() {
      _schedules = schedules;
    });
    // Ensure alarms are synced
    await _schedulerService.scheduleAlarms(_schedules);
  }

  Future<void> _saveSchedule(Schedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      setState(() {
        _schedules[index] = schedule;
      });
    } else {
      setState(() {
        _schedules.add(schedule);
      });
    }
    await _prefsService.saveSchedules(_schedules);
    
    // Force Sync immediately
    await _schedulerService.scheduleAlarms(_schedules);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule Saved & Synced!')),
      );
    }
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    // Check if we're currently in this schedule's active window BEFORE deleting.
    // If so, we need to restore normal ringer mode after cancelling.
    final wasInActiveWindow = _isScheduleCurrentlyActive(schedule);

    setState(() {
      _schedules.removeWhere((s) => s.id == schedule.id);
    });
    await _prefsService.saveSchedules(_schedules);
    
    // Cancel specific alarm first
    await _schedulerService.cancelSchedule(schedule);
    
    // Force Sync remaining alarms to ensure state is correct
    await _schedulerService.scheduleAlarms(_schedules);

    // If the deleted schedule was active, restore normal ringer mode
    // (unless another schedule is currently active)
    if (wasInActiveWindow) {
      bool anotherScheduleActive = false;
      for (var s in _schedules) {
        if (s.isEnabled && _isScheduleCurrentlyActive(s)) {
          anotherScheduleActive = true;
          break;
        }
      }
      if (!anotherScheduleActive) {
        await _nativeService.setRingerMode(false);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule Deleted & Synced!')),
      );
    }
  }

  /// Checks if a schedule is currently in its active time window.
  bool _isScheduleCurrentlyActive(Schedule schedule) {
    if (!schedule.isEnabled) return false;

    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1; // Mon=0
    if (!schedule.days[currentDayIndex]) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
    final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dndGranted) {
      return PermissionScreen(onPermissionGranted: () {
        _checkDnd();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Vibe'),
        leading: IconButton(
          icon: const Icon(Icons.vibration),
          onPressed: () async {
            // Manual Test Toggle
            // We don't track the actual system state here perfectly, just toggling for test.
            // Let's assume we want to toggle ON then OFF.
            // Or better, let's ask the user? No, just toggle.
            // We'll use a static variable or just toggle based on a local flag?
            // Let's just force VIBRATE ON for now, or cycle?
            // User said "turn on/off".
            
            // Let's check current state if possible? No, we don't have a check method yet.
            // We'll just use a local flag.
            _testToggleState = !_testToggleState;
            await _nativeService.setRingerMode(_testToggleState);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_testToggleState ? 'Testing: Vibrate ON (Vol 0)' : 'Testing: Normal (Vol Max)'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          if (_isBatteryOptimized)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.battery_alert, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Battery Optimization Detected",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Alarms may not fire reliably. Please disable optimization.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _nativeService.requestBatteryOptimization();
                      // Wait a bit and recheck
                      await Future.delayed(const Duration(seconds: 2));
                      _checkBatteryOptimization();
                    },
                    child: const Text("FIX"),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Schedules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.accentColor),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateScheduleScreen()),
                  );
                  if (result is Schedule) {
                    _saveSchedule(result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_schedules.isEmpty)
            const Center(child: Text("No schedules yet. Tap + to add one.", style: TextStyle(color: Colors.grey)))
          else
            ..._schedules.map((s) => _buildScheduleCard(s)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Waiting for next activation',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // In a real app, we'd calculate the next activation time and display it.
          // For now, static or simple logic.
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(schedule.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.accentColor),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateScheduleScreen(existingSchedule: schedule)),
                      );
                      if (result is Schedule) {
                        _saveSchedule(result);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Schedule?'),
                          content: Text('Are you sure you want to delete "${schedule.name}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _deleteSchedule(schedule);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(schedule.startTime.format(context), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('End Time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(schedule.endTime.format(context), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Active on', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final isActive = schedule.days[index];
              if (!isActive) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dayLabels[index],
                  style: const TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Enable Scheduler', style: TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: schedule.isEnabled,
                onChanged: (val) {
                  final updated = Schedule(
                    id: schedule.id,
                    name: schedule.name,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    days: schedule.days,
                    isEnabled: val,
                    alarmId: schedule.alarmId,
                  );
                  _saveSchedule(updated);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _checkDnd();
    _loadSchedules();
  }

  Future<void> _checkDnd() async {
    final granted = await _nativeService.checkDndPermission();
    setState(() {
      _dndGranted = granted;
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
    await _loadSchedules();
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    setState(() {
      _schedules.removeWhere((s) => s.id == schedule.id);
    });
    await _prefsService.saveSchedules(_schedules);
    await _schedulerService.cancelSchedule(schedule);
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
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _schedulerService.scheduleTestAlarm();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test Alarm Scheduled! Wait 10 seconds...')),
                  );
                }
              },
              icon: const Icon(Icons.timer),
              label: const Text("Test Alarm (10s)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
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

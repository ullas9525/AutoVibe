import 'package:autovibe/services/native_service.dart';
import 'package:autovibe/services/preferences_service.dart';
import 'package:autovibe/services/scheduler_service.dart';
import 'package:autovibe/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('GENERAL', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.power_settings_new,
                  title: 'Auto-start on device boot',
                  subtitle: 'Launch the app automatically when you restart your phone.',
                  value: true, // TODO: Implement actual preference
                  onChanged: (v) {},
                ),
                const Divider(height: 1, color: Colors.white10),
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Show notifications',
                  subtitle: 'Receive a notification when your vibration mode changes.',
                  value: false, // TODO: Implement actual preference
                  onChanged: (v) {},
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.battery_alert, color: AppTheme.accentColor),
                  ),
                  title: const Text('Disable Battery Optimization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Required for reliable background scheduling.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () async {
                    final nativeService = NativeService(); // Ideally inject or use provider
                    await nativeService.requestBatteryOptimization();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('INFORMATION', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildLinkTile(Icons.info_outline, 'About & Version Info'),
                const Divider(height: 1, color: Colors.white10),
                _buildLinkTile(Icons.feedback_outlined, 'Send Feedback'),
                const Divider(height: 1, color: Colors.white10),
                _buildLinkTile(Icons.star_rate_rounded, 'Rate App'),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bug_report, color: Colors.orange),
                  ),
                  title: const Text('Debug Logs', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () => _showLogs(context),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sync, color: Colors.blue),
                  ),
                  title: const Text('Force Schedule Sync', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Re-schedule all active alarms', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  onTap: () async {
                    final prefs = PreferencesService();
                    final scheduler = SchedulerService();
                    final schedules = await prefs.loadSchedules();
                    await scheduler.scheduleAlarms(schedules);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Schedules Synced! Check Logs.')),
                      );
                    }
                  },
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timer, color: Colors.amber),
                  ),
                  title: const Text('Test Alarm (10s)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Verify AlarmClock', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  onTap: () async {
                    final scheduler = SchedulerService();
                    await scheduler.scheduleTestAlarm();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test Alarm Scheduled! Wait 10s...')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogs(BuildContext context) async {
    // Lazy load logs
    // Ideally create a separate screen, but dialog is quick for v2
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Debug Logs', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<String>>(
            future: _getLogs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final logs = snapshot.data!;
              if (logs.isEmpty) return const Text("No logs found.", style: TextStyle(color: Colors.white70));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: logs.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(logs[index], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _clearLogs();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getLogs() async {
    // We need to import LoggerService, but to avoid import mess in this snippet,
    // we'll use SharedPreferences directly or assume import is added.
    // Let's assume we add the import.
    // Wait, I can't easily add import with replace_file_content if it's at top.
    // I will use SharedPreferences directly here for simplicity or add import in a separate call.
    // Let's add import in a separate call or just use dynamic loading? No.
    // I'll use SharedPreferences directly here.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('app_logs') ?? [];
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_logs');
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.accentColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildLinkTile(IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.accentColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}

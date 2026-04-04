import 'package:autovibe/models/schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _schedulesKey = 'schedules';
  static const String _activeAlarmIdsKey = 'active_alarm_ids';

  Future<void> saveSchedules(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = schedules.map((s) => s.toJson()).toList();
    await prefs.setStringList(_schedulesKey, jsonList);
  }

  Future<List<Schedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_schedulesKey);
    
    if (jsonList == null) return [];

    return jsonList.map((json) => Schedule.fromJson(json)).toList();
  }

  /// Saves the list of all currently active alarm IDs registered with AndroidAlarmManager.
  /// This allows us to cancel stale alarms even after their parent Schedule is deleted.
  Future<void> saveActiveAlarmIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> idStrings = ids.map((id) => id.toString()).toList();
    await prefs.setStringList(_activeAlarmIdsKey, idStrings);
  }

  /// Loads the list of all previously registered alarm IDs.
  Future<List<int>> loadActiveAlarmIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? idStrings = prefs.getStringList(_activeAlarmIdsKey);
    if (idStrings == null) return [];
    return idStrings.map((s) => int.parse(s)).toList();
  }
}

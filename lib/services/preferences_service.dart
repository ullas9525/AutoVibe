import 'package:autovibe/models/schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _schedulesKey = 'schedules';

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
}

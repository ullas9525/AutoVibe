import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LoggerService {
  static const String _logKey = 'app_logs';

  static Future<void> log(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_logKey) ?? [];
      final timestamp = DateFormat('MM-dd HH:mm:ss').format(DateTime.now());
      logs.insert(0, "[$timestamp] $message"); // Prepend
      if (logs.length > 50) {
        logs.removeLast(); // Keep last 50
      }
      await prefs.setStringList(_logKey, logs);
      print("LOG: $message");
    } catch (e) {
      print("Logging failed: $e");
    }
  }

  static Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_logKey) ?? [];
  }

  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
  }
}

import 'package:native_ringer/native_ringer.dart';

class NativeService {
  final NativeRinger _ringer = NativeRinger();

  Future<bool> checkDndPermission() async {
    return await _ringer.checkDndPermission();
  }

  Future<void> requestDndPermission() async {
    await _ringer.requestDndPermission();
  }

  Future<void> requestBatteryOptimization() async {
    await _ringer.requestBatteryOptimization();
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    return await _ringer.isIgnoringBatteryOptimizations();
  }

  Future<void> setRingerMode(bool vibrate) async {
    await _ringer.setRingerMode(vibrate);
  }
}

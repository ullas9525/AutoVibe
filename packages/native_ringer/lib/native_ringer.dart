
import 'native_ringer_platform_interface.dart';

class NativeRinger {
  Future<bool> checkDndPermission() async {
    final bool? result = await NativeRingerPlatform.instance.checkDndPermission();
    return result ?? false;
  }

  Future<void> requestDndPermission() async {
    await NativeRingerPlatform.instance.requestDndPermission();
  }

  Future<void> requestBatteryOptimization() async {
    await NativeRingerPlatform.instance.requestBatteryOptimization();
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    final bool? result = await NativeRingerPlatform.instance.isIgnoringBatteryOptimizations();
    return result ?? true; // Default to true if platform doesn't support (e.g. old Android)
  }

  Future<void> setRingerMode(bool vibrate) async {
    await NativeRingerPlatform.instance.setRingerMode(vibrate);
  }
}

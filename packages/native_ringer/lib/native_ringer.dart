
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

  Future<void> setRingerMode(bool vibrate) async {
    await NativeRingerPlatform.instance.setRingerMode(vibrate);
  }
}

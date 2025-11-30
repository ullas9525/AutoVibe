import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_ringer_platform_interface.dart';

/// An implementation of [NativeRingerPlatform] that uses method channels.
class MethodChannelNativeRinger extends NativeRingerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_ringer');

  @override
  Future<bool?> checkDndPermission() async {
    final version = await methodChannel.invokeMethod<bool>('checkDndPermission');
    return version;
  }

  @override
  Future<void> requestDndPermission() async {
    await methodChannel.invokeMethod<void>('requestDndPermission');
  }

  @override
  Future<void> requestBatteryOptimization() async {
    await methodChannel.invokeMethod<void>('requestBatteryOptimization');
  }

  @override
  Future<bool?> isIgnoringBatteryOptimizations() async {
    return await methodChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
  }

  @override
  Future<void> setRingerMode(bool vibrate) async {
    await methodChannel.invokeMethod<void>('setRingerMode', {
      'mode': vibrate ? 'vibrate' : 'normal',
    });
  }
}

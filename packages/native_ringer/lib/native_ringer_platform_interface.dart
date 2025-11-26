import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_ringer_method_channel.dart';

abstract class NativeRingerPlatform extends PlatformInterface {
  /// Constructs a NativeRingerPlatform.
  NativeRingerPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeRingerPlatform _instance = MethodChannelNativeRinger();

  /// The default instance of [NativeRingerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeRinger].
  static NativeRingerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeRingerPlatform] when
  /// they register themselves.
  static set instance(NativeRingerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> checkDndPermission() {
    throw UnimplementedError('checkDndPermission() has not been implemented.');
  }

  Future<void> requestDndPermission() {
    throw UnimplementedError('requestDndPermission() has not been implemented.');
  }

  Future<void> requestBatteryOptimization() {
    throw UnimplementedError('requestBatteryOptimization() has not been implemented.');
  }

  Future<void> setRingerMode(bool vibrate) {
    throw UnimplementedError('setRingerMode() has not been implemented.');
  }
}

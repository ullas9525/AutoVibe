import 'package:flutter_test/flutter_test.dart';
import 'package:native_ringer/native_ringer.dart';
import 'package:native_ringer/native_ringer_platform_interface.dart';
import 'package:native_ringer/native_ringer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeRingerPlatform
    with MockPlatformInterfaceMixin
    implements NativeRingerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeRingerPlatform initialPlatform = NativeRingerPlatform.instance;

  test('$MethodChannelNativeRinger is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeRinger>());
  });

  test('getPlatformVersion', () async {
    NativeRinger nativeRingerPlugin = NativeRinger();
    MockNativeRingerPlatform fakePlatform = MockNativeRingerPlatform();
    NativeRingerPlatform.instance = fakePlatform;

    expect(await nativeRingerPlugin.getPlatformVersion(), '42');
  });
}

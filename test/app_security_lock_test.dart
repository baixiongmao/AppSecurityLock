import 'package:flutter_test/flutter_test.dart';
import 'package:app_security_lock/app_security_lock.dart';
import 'package:app_security_lock/app_security_lock_platform_interface.dart';
import 'package:app_security_lock/app_security_lock_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppSecurityLockPlatform
    with MockPlatformInterfaceMixin
    implements AppSecurityLockPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AppSecurityLockPlatform initialPlatform = AppSecurityLockPlatform.instance;

  test('$MethodChannelAppSecurityLock is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppSecurityLock>());
  });

  test('getPlatformVersion', () async {
    AppSecurityLock appSecurityLockPlugin = AppSecurityLock();
    MockAppSecurityLockPlatform fakePlatform = MockAppSecurityLockPlatform();
    AppSecurityLockPlatform.instance = fakePlatform;

    expect(await appSecurityLockPlugin.getPlatformVersion(), '42');
  });
}

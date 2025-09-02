import 'package:flutter_test/flutter_test.dart';
import 'package:app_security_lock/app_security_lock.dart';
import 'package:app_security_lock/app_security_lock_platform_interface.dart';
import 'package:app_security_lock/app_security_lock_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppSecurityLockPlatform
    with MockPlatformInterfaceMixin
    implements AppSecurityLockPlatform {

  @override
  Future<void> init({
    bool? isScreenLockEnabled,
    bool? isBackgroundLockEnabled,
    double? backgroundTimeout,
  }) => Future.value();

  @override
  Future<void> setLockEnabled(bool enabled) => Future.value();

  @override
  void setBackgroundLockEnabled(bool enabled) {}

  @override
  Future<void> setBackgroundTimeout(double timeoutSeconds) => Future.value();

  @override
  void setScreenLockEnabled(bool enabled) {}

  @override
  void setOnEnterForegroundCallback(AppLifecycleCallback? callback) {}

  @override
  void setOnEnterBackgroundCallback(AppLifecycleCallback? callback) {}

  @override
  void setOnAppLockedCallback(AppLockedCallback? callback) {}

  @override
  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {}
}

void main() {
  final AppSecurityLockPlatform initialPlatform = AppSecurityLockPlatform.instance;

  test('$MethodChannelAppSecurityLock is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppSecurityLock>());
  });

  test('init method works correctly', () async {
    AppSecurityLock appSecurityLockPlugin = AppSecurityLock();
    MockAppSecurityLockPlatform fakePlatform = MockAppSecurityLockPlatform();
    AppSecurityLockPlatform.instance = fakePlatform;

    // Test that init method can be called without throwing
    expect(() => appSecurityLockPlugin.init(), returnsNormally);
  });

  test('setLockEnabled method works', () async {
    AppSecurityLock appSecurityLockPlugin = AppSecurityLock();
    MockAppSecurityLockPlatform fakePlatform = MockAppSecurityLockPlatform();
    AppSecurityLockPlatform.instance = fakePlatform;

    // Test that setLockEnabled method can be called without throwing
    expect(() => appSecurityLockPlugin.setLockEnabled(true), returnsNormally);
  });
}

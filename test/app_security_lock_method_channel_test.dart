import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_security_lock/app_security_lock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAppSecurityLock platform = MethodChannelAppSecurityLock();
  const MethodChannel channel = MethodChannel('app_security_lock');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return null; // Most methods return void
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('init method', () async {
    // Test that init method doesn't throw
    expect(() => platform.init(), returnsNormally);
  });

  test('setLockEnabled method', () async {
    // Test that setLockEnabled method doesn't throw
    expect(() => platform.setLockEnabled(true), returnsNormally);
  });
}

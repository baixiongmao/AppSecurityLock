import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_security_lock_platform_interface.dart';

/// An implementation of [AppSecurityLockPlatform] that uses method channels.
class MethodChannelAppSecurityLock extends AppSecurityLockPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('app_security_lock');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

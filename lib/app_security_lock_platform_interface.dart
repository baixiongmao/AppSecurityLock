import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'app_security_lock_method_channel.dart';

abstract class AppSecurityLockPlatform extends PlatformInterface {
  /// Constructs a AppSecurityLockPlatform.
  AppSecurityLockPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppSecurityLockPlatform _instance = MethodChannelAppSecurityLock();

  /// The default instance of [AppSecurityLockPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppSecurityLock].
  static AppSecurityLockPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppSecurityLockPlatform] when
  /// they register themselves.
  static set instance(AppSecurityLockPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

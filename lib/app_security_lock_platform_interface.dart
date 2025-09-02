import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'app_security_lock_method_channel.dart';

typedef AppLifecycleCallback = void Function();
typedef AppLockedCallback = void Function();
typedef AppUnlockedCallback = void Function();

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

  Future<void> init({
    bool? isScreenLockEnabled,
    bool? isBackgroundLockEnabled,
    double? backgroundTimeout,
  }) {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// 设置应用进入前台的回调
  void setOnEnterForegroundCallback(AppLifecycleCallback? callback) {
    throw UnimplementedError(
        'setOnEnterForegroundCallback() has not been implemented.');
  }

  /// 设置应用进入后台的回调
  void setOnEnterBackgroundCallback(AppLifecycleCallback? callback) {
    throw UnimplementedError(
        'setOnEnterBackgroundCallback() has not been implemented.');
  }

  ///锁定回调
  void setOnAppLockedCallback(AppLockedCallback? callback) {
    throw UnimplementedError(
        'setOnAppLockedCallback() has not been implemented.');
  }

  // 通知解锁
  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {
    throw UnimplementedError(
        'setOnAppUnlockedCallback() has not been implemented.');
  }

  /// 设置锁定状态
  Future<void> setLockEnabled(bool enabled) {
    throw UnimplementedError('setLockEnabled() has not been implemented.');
  }

  /// 设置后台超时时间（秒）
  Future<void> setBackgroundTimeout(double timeoutSeconds) {
    throw UnimplementedError(
        'setBackgroundTimeout() has not been implemented.');
  }

  /// 更新后台锁定状态
  void setBackgroundLockEnabled(bool enabled) {
    throw UnimplementedError(
        'setBackgroundLockEnabled() has not been implemented.');
  }

  /// 更新屏幕锁定状态
  void setScreenLockEnabled(bool enabled) {
    throw UnimplementedError(
        'setScreenLockEnabled() has not been implemented.');
  }
}

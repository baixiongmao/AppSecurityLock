import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'app_security_lock_method_channel.dart';

typedef AppLifecycleCallback = void Function();
typedef AuthenticationCallback = void Function(bool success, String? error);
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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> init({
    bool? isFaceIDEnabled,
    bool? isPasscodeEnabled,
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

  // 解锁回调
  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {
    throw UnimplementedError(
        'setOnAppUnlockedCallback() has not been implemented.');
  }

  /// 设置锁定状态
  Future<void> setLockEnabled(bool enabled) {
    throw UnimplementedError('setLockEnabled() has not been implemented.');
  }

  /// 设置面容ID启用状态
  Future<void> setFaceIDEnabled(bool enabled) {
    throw UnimplementedError('setFaceIDEnabled() has not been implemented.');
  }

  /// 设置密码解锁启用状态
  Future<void> setPasscodeEnabled(bool enabled) {
    throw UnimplementedError('setPasscodeEnabled() has not been implemented.');
  }

  /// 设置后台超时时间（秒）
  Future<void> setBackgroundTimeout(double timeoutSeconds) {
    throw UnimplementedError(
        'setBackgroundTimeout() has not been implemented.');
  }

  /// 检查生物识别是否可用
  Future<bool> isBiometricAvailable() {
    throw UnimplementedError(
        'isBiometricAvailable() has not been implemented.');
  }

  /// 获取生物识别类型
  Future<String> getBiometricType() {
    throw UnimplementedError('getBiometricType() has not been implemented.');
  }

  /// 使用生物识别进行认证
  Future<bool> authenticateWithBiometric() {
    throw UnimplementedError(
        'authenticateWithBiometric() has not been implemented.');
  }

  /// 设置认证回调
  void setOnAuthenticationCallback(AuthenticationCallback? callback) {
    throw UnimplementedError(
        'setOnAuthenticationCallback() has not been implemented.');
  }

  void setBackgroundLockEnabled(bool enabled) {
    throw UnimplementedError(
        'setBackgroundLockEnabled() has not been implemented.');
  }

  void setScreenLockEnabled(bool enabled) {
    throw UnimplementedError(
        'setScreenLockEnabled() has not been implemented.');
  }
}

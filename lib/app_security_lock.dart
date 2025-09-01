// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'app_security_lock_platform_interface.dart';

class AppSecurityLock {
  Future<String?> getPlatformVersion() {
    return AppSecurityLockPlatform.instance.getPlatformVersion();
  }

  Future<void> init() {
    return AppSecurityLockPlatform.instance.init();
  }

  /// 设置应用进入前台时的回调函数
  void setOnEnterForegroundCallback(AppLifecycleCallback? callback) {
    AppSecurityLockPlatform.instance.setOnEnterForegroundCallback(callback);
  }

  /// 设置应用进入后台时的回调函数
  void setOnEnterBackgroundCallback(AppLifecycleCallback? callback) {
    AppSecurityLockPlatform.instance.setOnEnterBackgroundCallback(callback);
  }

  /// 设置锁定状态
  Future<void> setLockEnabled(bool enabled) {
    return AppSecurityLockPlatform.instance.setLockEnabled(enabled);
  }

  /// 设置面容ID启用状态
  Future<void> setFaceIDEnabled(bool enabled) {
    return AppSecurityLockPlatform.instance.setFaceIDEnabled(enabled);
  }

  /// 设置密码解锁启用状态
  Future<void> setPasscodeEnabled(bool enabled) {
    return AppSecurityLockPlatform.instance.setPasscodeEnabled(enabled);
  }

  /// 设置后台超时时间（秒）
  /// [timeoutSeconds] 后台超时时间，单位为秒
  Future<void> setBackgroundTimeout(double timeoutSeconds) {
    return AppSecurityLockPlatform.instance
        .setBackgroundTimeout(timeoutSeconds);
  }

  /// 检查生物识别是否可用
  Future<bool> isBiometricAvailable() {
    return AppSecurityLockPlatform.instance.isBiometricAvailable();
  }

  /// 获取生物识别类型 (faceID, touchID, opticID, none)
  Future<String> getBiometricType() {
    return AppSecurityLockPlatform.instance.getBiometricType();
  }

  /// 使用生物识别进行认证
  Future<bool> authenticateWithBiometric() {
    return AppSecurityLockPlatform.instance.authenticateWithBiometric();
  }

  /// 设置认证回调
  void setOnAuthenticationCallback(AuthenticationCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAuthenticationCallback(callback);
  }

  void setOnAppLockedCallback(AppLockedCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAppLockedCallback(callback);
  }

  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAppUnlockedCallback(callback);
  }
}

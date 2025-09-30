// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'app_security_lock_platform_interface.dart';

class AppSecurityLock {
  /// 初始化插件
  /// [isScreenLockEnabled] 是否启用屏幕锁定检测
  /// [isBackgroundLockEnabled] 是否启用后台锁定
  /// [backgroundTimeout] 后台超时时间（秒）
  /// [isTouchTimeoutEnabled] 是否启用触摸超时锁定
  /// [touchTimeout] 触摸超时时间（秒）
  ///
  Future<void> init({
    bool? isScreenLockEnabled,
    bool? isBackgroundLockEnabled,
    double? backgroundTimeout,
    bool? isTouchTimeoutEnabled,
    double? touchTimeout,
    bool? debug,
  }) {
    return AppSecurityLockPlatform.instance.init(
      isScreenLockEnabled: isScreenLockEnabled,
      isBackgroundLockEnabled: isBackgroundLockEnabled,
      backgroundTimeout: backgroundTimeout,
      isTouchTimeoutEnabled: isTouchTimeoutEnabled,
      touchTimeout: touchTimeout,
      debug: debug,
    );
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

  /// 设置后台超时时间（秒）
  /// [timeoutSeconds] 后台超时时间，单位为秒
  Future<void> setBackgroundTimeout(double timeoutSeconds) {
    return AppSecurityLockPlatform.instance
        .setBackgroundTimeout(timeoutSeconds);
  }

  /// 设置应用锁定回调
  void setOnAppLockedCallback(AppLockedCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAppLockedCallback(callback);
  }

  ///通知解锁
  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAppUnlockedCallback(callback);
  }

  /// 更新后台锁定功能状态
  void setBackgroundLockEnabled(bool enabled) {
    AppSecurityLockPlatform.instance.setBackgroundLockEnabled(enabled);
  }

  /// 更新屏幕锁定功能状态
  void setScreenLockEnabled(bool enabled) {
    AppSecurityLockPlatform.instance.setScreenLockEnabled(enabled);
  }

  /// 更新触摸超时启用状态
  /// [enabled] 是否启用触摸超时锁定
  Future<void> setTouchTimeoutEnabled(bool enabled) {
    return AppSecurityLockPlatform.instance.setTouchTimeoutEnabled(enabled);
  }

  /// 设置触摸超时时间
  /// [timeoutSeconds] 触摸超时时间，单位为秒
  Future<void> setTouchTimeout(double timeoutSeconds) {
    return AppSecurityLockPlatform.instance.setTouchTimeout(timeoutSeconds);
  }

  /// 重启触摸定时器
  void restartTouchTimer() {
    AppSecurityLockPlatform.instance.restartTouchTimer();
  }
}

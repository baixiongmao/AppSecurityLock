import 'dart:ui';

import 'app_security_lock_platform_interface.dart';

// 导出 LockReason 供外部使用
export 'app_security_lock_platform_interface.dart'
    show LockReason, LockCallback;

/// 应用安全锁插件
///
/// 提供应用锁定、后台超时锁定、触摸超时锁定等功能
///
/// 使用示例：
/// ```dart
/// final lock = AppSecurityLock()
///   ..onLock((reason) => print('应用已锁定，原因: $reason'))
///   ..onUnlock(() => print('请解锁应用'))
///   ..onForeground(() => print('进入前台'))
///   ..onBackground(() => print('进入后台'));
///
/// await lock.init(
///   isScreenLockEnabled: true,
///   isBackgroundLockEnabled: true,
///   backgroundTimeout: 30.0,
/// );
/// ```
class AppSecurityLock {
  /// 初始化插件
  ///
  /// [isScreenLockEnabled] 是否启用屏幕锁定检测（设备锁屏时触发锁定）
  /// [isBackgroundLockEnabled] 是否启用后台锁定（应用进入后台超时后触发锁定）
  /// [backgroundTimeout] 后台超时时间（秒）
  /// [isTouchTimeoutEnabled] 是否启用触摸超时锁定（无操作超时后触发锁定）
  /// [touchTimeout] 触摸超时时间（秒）
  /// [debug] 是否开启调试日志（日志输出在原生控制台）
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

  // ============ 事件回调（支持链式调用） ============

  /// 当应用被锁定时触发
  ///
  /// [callback] 回调函数，参数 [LockReason] 表示锁定原因：
  /// - [LockReason.screenLock] 设备屏幕锁定
  /// - [LockReason.backgroundTimeout] 后台超时
  /// - [LockReason.touchTimeout] 触摸超时（无操作超时）
  /// - [LockReason.manual] 手动锁定
  /// - [LockReason.unknown] 未知原因
  ///
  /// 通常用于显示解锁界面
  AppSecurityLock onLock(LockCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAppLockedCallback(callback);
    return this;
  }

  /// 当应用需要解锁时触发（从锁定状态回到前台）
  ///
  /// 通常用于提示用户进行身份验证
  AppSecurityLock onUnlock(VoidCallback? callback) {
    AppSecurityLockPlatform.instance.setOnAppUnlockedCallback(callback);
    return this;
  }

  /// 当应用进入前台时触发
  AppSecurityLock onForeground(VoidCallback? callback) {
    AppSecurityLockPlatform.instance.setOnEnterForegroundCallback(callback);
    return this;
  }

  /// 当应用进入后台时触发
  AppSecurityLock onBackground(VoidCallback? callback) {
    AppSecurityLockPlatform.instance.setOnEnterBackgroundCallback(callback);
    return this;
  }

  // ============ 锁定状态控制 ============

  /// 手动设置锁定状态
  ///
  /// [enabled] true 表示锁定，false 表示解锁
  Future<AppSecurityLock> setLocked(bool enabled) async {
    await AppSecurityLockPlatform.instance.setLockEnabled(enabled);
    return this;
  }

  /// 锁定应用
  Future<AppSecurityLock> lock() => setLocked(true);

  /// 解锁应用
  Future<AppSecurityLock> unlock() => setLocked(false);

  // ============ 屏幕锁定设置 ============

  /// 启用/禁用屏幕锁定检测
  ///
  /// 启用后，当设备屏幕锁定时会自动锁定应用
  AppSecurityLock screenLockEnabled(bool enabled) {
    AppSecurityLockPlatform.instance.setScreenLockEnabled(enabled);
    return this;
  }

  // ============ 后台锁定设置 ============

  /// 启用/禁用后台超时锁定
  ///
  /// 启用后，应用进入后台超过指定时间会自动锁定
  AppSecurityLock backgroundLockEnabled(bool enabled) {
    AppSecurityLockPlatform.instance.setBackgroundLockEnabled(enabled);
    return this;
  }

  /// 设置后台超时时间
  ///
  /// [seconds] 超时时间，单位为秒
  Future<AppSecurityLock> backgroundTimeout(double seconds) async {
    await AppSecurityLockPlatform.instance.setBackgroundTimeout(seconds);
    return this;
  }

  // ============ 触摸超时设置 ============

  /// 启用/禁用触摸超时锁定
  ///
  /// 启用后，用户无操作超过指定时间会自动锁定
  Future<AppSecurityLock> touchTimeoutEnabled(bool enabled) async {
    await AppSecurityLockPlatform.instance.setTouchTimeoutEnabled(enabled);
    return this;
  }

  /// 设置触摸超时时间
  ///
  /// [seconds] 超时时间，单位为秒
  Future<AppSecurityLock> touchTimeout(double seconds) async {
    await AppSecurityLockPlatform.instance.setTouchTimeout(seconds);
    return this;
  }

  /// 重置触摸计时器
  ///
  /// 手动重置无操作计时，延长超时时间
  AppSecurityLock resetTouchTimer() {
    AppSecurityLockPlatform.instance.restartTouchTimer();
    return this;
  }

  // ============ 录屏防护设置 ============

  /// 启用/禁用录屏防护
  ///
  /// 启用后，将禁止对应用进行屏幕录制
  /// [warningMessage] 屏幕录制时显示的警告文本，默认为"屏幕正在被录制"
  Future<AppSecurityLock> screenRecordingProtectionEnabled(
    bool enabled, {
    String? warningMessage,
  }) async {
    await AppSecurityLockPlatform.instance.setScreenRecordingProtectionEnabled(
      enabled,
      warningMessage: warningMessage,
    );
    return this;
  }

  // ============ 兼容旧 API（已废弃） ============

  @Deprecated('使用 onLock() 代替，新版本回调包含锁定原因')
  void setOnAppLockedCallback(VoidCallback? callback) {
    if (callback != null) {
      onLock((_) => callback());
    } else {
      onLock(null);
    }
  }

  @Deprecated('使用 onUnlock() 代替')
  void setOnAppUnlockedCallback(VoidCallback? callback) => onUnlock(callback);

  @Deprecated('使用 onForeground() 代替')
  void setOnEnterForegroundCallback(VoidCallback? callback) =>
      onForeground(callback);

  @Deprecated('使用 onBackground() 代替')
  void setOnEnterBackgroundCallback(VoidCallback? callback) =>
      onBackground(callback);

  @Deprecated('使用 setLocked() 代替')
  Future<void> setLockEnabled(bool enabled) =>
      AppSecurityLockPlatform.instance.setLockEnabled(enabled);

  @Deprecated('使用 backgroundTimeout() 代替')
  Future<void> setBackgroundTimeout(double timeoutSeconds) =>
      AppSecurityLockPlatform.instance.setBackgroundTimeout(timeoutSeconds);

  @Deprecated('使用 backgroundLockEnabled() 代替')
  void setBackgroundLockEnabled(bool enabled) =>
      AppSecurityLockPlatform.instance.setBackgroundLockEnabled(enabled);

  @Deprecated('使用 screenLockEnabled() 代替')
  void setScreenLockEnabled(bool enabled) =>
      AppSecurityLockPlatform.instance.setScreenLockEnabled(enabled);

  @Deprecated('使用 touchTimeoutEnabled() 代替')
  Future<void> setTouchTimeoutEnabled(bool enabled) =>
      AppSecurityLockPlatform.instance.setTouchTimeoutEnabled(enabled);

  @Deprecated('使用 touchTimeout() 代替')
  Future<void> setTouchTimeout(double timeoutSeconds) =>
      AppSecurityLockPlatform.instance.setTouchTimeout(timeoutSeconds);

  @Deprecated('使用 resetTouchTimer() 代替')
  void restartTouchTimer() => resetTouchTimer();
}

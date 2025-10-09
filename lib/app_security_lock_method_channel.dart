import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_security_lock_platform_interface.dart';

/// An implementation of [AppSecurityLockPlatform] that uses method channels.
class MethodChannelAppSecurityLock extends AppSecurityLockPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('app_security_lock');

  AppLifecycleCallback? _onEnterForegroundCallback;
  AppLifecycleCallback? _onEnterBackgroundCallback;
  AppLockedCallback? _onAppLockedCallback;
  AppUnlockedCallback? _onAppUnlockedCallback;

  MethodChannelAppSecurityLock() {
    // 设置方法调用处理器来接收来自原生端的回调
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onEnterForeground':
        _onEnterForegroundCallback?.call();
        break;
      case 'onEnterBackground':
        _onEnterBackgroundCallback?.call();
        break;
      case 'onAppLocked':
        _onAppLockedCallback?.call();
        break;
      case 'onAppUnlocked':
        _onAppUnlockedCallback?.call();
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'app_security_lock for method ${call.method} is not implemented',
        );
    }
  }

  @override
  Future<void> init({
    bool? isScreenLockEnabled,
    bool? isBackgroundLockEnabled,
    double? backgroundTimeout,
    bool? isTouchTimeoutEnabled,
    double? touchTimeout,
    bool? debug,
  }) {
    final Map<String, dynamic> arguments = {};

    if (isScreenLockEnabled != null) {
      arguments['isScreenLockEnabled'] = isScreenLockEnabled;
    }
    if (isBackgroundLockEnabled != null) {
      arguments['isBackgroundLockEnabled'] = isBackgroundLockEnabled;
    }
    if (backgroundTimeout != null) {
      arguments['backgroundTimeout'] = backgroundTimeout;
    }
    if (isTouchTimeoutEnabled != null) {
      arguments['isTouchTimeoutEnabled'] = isTouchTimeoutEnabled;
    }
    if (touchTimeout != null) {
      arguments['touchTimeout'] = touchTimeout;
    }
    if (debug != null) {
      arguments['debug'] = debug;
    }
    return methodChannel.invokeMethod(
        'init', arguments.isEmpty ? null : arguments);
  }

  /// 设置应用进入前台的回调
  @override
  void setOnEnterForegroundCallback(AppLifecycleCallback? callback) {
    _onEnterForegroundCallback = callback;
  }

  /// 设置应用进入后台的回调
  @override
  void setOnEnterBackgroundCallback(AppLifecycleCallback? callback) {
    _onEnterBackgroundCallback = callback;
  }

  ///锁定回调
  @override
  void setOnAppLockedCallback(AppLockedCallback? callback) {
    _onAppLockedCallback = callback;
  }

  // 通知前台解锁
  @override
  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {
    _onAppUnlockedCallback = callback;
  }

  /// 设置锁定状态
  @override
  Future<void> setLockEnabled(bool enabled) {
    return methodChannel.invokeMethod('setLockEnabled', {'enabled': enabled});
  }

  /// 设置后台超时时间（秒）
  @override
  Future<void> setBackgroundLockEnabled(bool enabled) {
    return methodChannel
        .invokeMethod('setBackgroundLockEnabled', {'enabled': enabled});
  }

  /// 更新后台锁定功能状态
  @override
  Future<void> setBackgroundTimeout(double timeoutSeconds) {
    return methodChannel
        .invokeMethod('setBackgroundTimeout', {'timeout': timeoutSeconds});
  }

  /// 更新屏幕锁定功能状态
  @override
  Future<void> setScreenLockEnabled(bool enabled) {
    return methodChannel
        .invokeMethod('setScreenLockEnabled', {'enabled': enabled});
  }

  /// 设置触摸超时启用状态
  @override
  Future<void> setTouchTimeoutEnabled(bool enabled) {
    return methodChannel
        .invokeMethod('setTouchTimeoutEnabled', {'enabled': enabled});
  }

  /// 设置触摸超时时间（秒）
  @override
  Future<void> setTouchTimeout(double timeoutSeconds) {
    return methodChannel
        .invokeMethod('setTouchTimeout', {'timeout': timeoutSeconds});
  }

  /// 重启触摸定时器
  @override
  void restartTouchTimer() {
    methodChannel.invokeMethod('restartTouchTimer');
  }
}

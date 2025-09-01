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
  AuthenticationCallback? _onAuthenticationCallback;

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
      case 'onAuthentication':
        final arguments = call.arguments as Map<String, dynamic>?;
        final success = arguments?['success'] as bool? ?? false;
        if (success) {
          final type = arguments?['type'] as String?;
          _onAuthenticationCallback?.call(true, type);
        } else {
          final error = arguments?['error'] as String?;
          _onAuthenticationCallback?.call(false, error);
        }
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
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> init({
    bool? isFaceIDEnabled,
    bool? isPasscodeEnabled,
    bool? isScreenLockEnabled,
    bool? isBackgroundLockEnabled,
    double? backgroundTimeout,
  }) {
    final Map<String, dynamic> arguments = {};

    if (isFaceIDEnabled != null) {
      arguments['isFaceIDEnabled'] = isFaceIDEnabled;
    }
    if (isPasscodeEnabled != null) {
      arguments['isPasscodeEnabled'] = isPasscodeEnabled;
    }
    if (isScreenLockEnabled != null) {
      arguments['isScreenLockEnabled'] = isScreenLockEnabled;
    }
    if (isBackgroundLockEnabled != null) {
      arguments['isBackgroundLockEnabled'] = isBackgroundLockEnabled;
    }
    if (backgroundTimeout != null) {
      arguments['backgroundTimeout'] = backgroundTimeout;
    }
    return methodChannel.invokeMethod(
        'init', arguments.isEmpty ? null : arguments);
  }

  @override
  void setOnEnterForegroundCallback(AppLifecycleCallback? callback) {
    _onEnterForegroundCallback = callback;
  }

  @override
  void setOnEnterBackgroundCallback(AppLifecycleCallback? callback) {
    _onEnterBackgroundCallback = callback;
  }

  @override
  void setOnAppLockedCallback(AppLockedCallback? callback) {
    _onAppLockedCallback = callback;
  }

  @override
  void setOnAppUnlockedCallback(AppUnlockedCallback? callback) {
    // 这里可以添加解锁回调的处理逻辑
    // 当前我们主要通过 setOnAuthenticationCallback 来处理解锁逻辑
  }

  @override
  Future<void> setLockEnabled(bool enabled) {
    return methodChannel.invokeMethod('setLockEnabled', {'enabled': enabled});
  }

  @override
  Future<void> setFaceIDEnabled(bool enabled) {
    return methodChannel.invokeMethod('setFaceIDEnabled', {'enabled': enabled});
  }

  @override
  Future<void> setPasscodeEnabled(bool enabled) {
    return methodChannel
        .invokeMethod('setPasscodeEnabled', {'enabled': enabled});
  }

  @override
  Future<void> setBackgroundLockEnabled(bool enabled) {
    return methodChannel
        .invokeMethod('setBackgroundLockEnabled', {'enabled': enabled});
  }

  @override
  Future<void> setBackgroundTimeout(double timeoutSeconds) {
    return methodChannel
        .invokeMethod('setBackgroundTimeout', {'timeout': timeoutSeconds});
  }

  @override
  Future<void> setScreenLockEnabled(bool enabled) {
    return methodChannel
        .invokeMethod('setScreenLockEnabled', {'enabled': enabled});
  }

  @override
  Future<bool> isBiometricAvailable() async {
    final result =
        await methodChannel.invokeMethod<bool>('isBiometricAvailable');
    return result ?? false;
  }

  @override
  Future<String> getBiometricType() async {
    final result = await methodChannel.invokeMethod<String>('getBiometricType');
    return result ?? 'none';
  }

  @override
  Future<bool> authenticateWithBiometric() async {
    try {
      final result =
          await methodChannel.invokeMethod<bool>('authenticateWithBiometric');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  void setOnAuthenticationCallback(AuthenticationCallback? callback) {
    _onAuthenticationCallback = callback;
  }
}

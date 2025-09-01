# 插件初始化配置说明

## 概述

现在 `AppSecurityLock` 插件支持在初始化时传递配置参数，让您可以一次性设置所有安全功能的默认状态。

## 新的初始化方法

### 方法签名

```dart
Future<void> init({
  bool? isFaceIDEnabled,
  bool? isPasscodeEnabled, 
  bool? isScreenLockEnabled,
  double? backgroundTimeout,
})
```

### 参数说明

- `isFaceIDEnabled`: 是否启用面容ID/指纹识别（可选）
- `isPasscodeEnabled`: 是否启用密码解锁（可选）
- `isScreenLockEnabled`: 是否启用屏幕锁定检测（可选）
- `backgroundTimeout`: 后台超时时间，单位为秒（可选）

## 使用示例

### 1. 基本初始化（无参数）

```dart
final appSecurityLock = AppSecurityLock();

// 使用默认设置初始化
await appSecurityLock.init();
```

### 2. 带配置参数的初始化

```dart
final appSecurityLock = AppSecurityLock();

// 使用自定义配置初始化
await appSecurityLock.init(
  isFaceIDEnabled: true,        // 启用生物识别
  isPasscodeEnabled: true,      // 启用密码解锁
  isScreenLockEnabled: true,    // 启用屏幕锁定检测
  isBackgroundLockEnabled:true,
  backgroundTimeout: 120.0,     // 设置后台超时为2分钟
);
```

### 3. 部分配置初始化

```dart
final appSecurityLock = AppSecurityLock();

// 只设置部分参数，其他使用默认值
await appSecurityLock.init(
  isFaceIDEnabled: true,
  backgroundTimeout: 300.0,     // 5分钟超时
);
```

## 完整示例

```dart
import 'package:app_security_lock/app_security_lock.dart';

class SecurityService {
  final AppSecurityLock _appSecurityLock = AppSecurityLock();
  
  Future<void> initializeSecurity() async {
    // 设置回调
    _setupCallbacks();
    
    // 初始化插件并配置安全选项
    await _appSecurityLock.init(
      isFaceIDEnabled: true,        // 启用生物识别
      isPasscodeEnabled: true,      // 启用密码作为备选
      isScreenLockEnabled: true,    // 启用屏幕锁定检测
      backgroundTimeout: 180.0,     // 3分钟后台超时
    );
    
    // 启用安全锁（这会触发锁定检查）
    await _appSecurityLock.setLockEnabled(true);
    
    print('安全服务已初始化');
  }
  
  void _setupCallbacks() {
    // 生命周期回调
    _appSecurityLock.setOnEnterForegroundCallback(() {
      print('应用进入前台');
    });
    
    _appSecurityLock.setOnEnterBackgroundCallback(() {
      print('应用进入后台，开始安全检查');
    });
    
    // 锁定/解锁回调
    _appSecurityLock.setOnAppLockedCallback(() {
      print('应用已被锁定');
      // 显示锁屏界面
    });
    
    // 认证回调
    _appSecurityLock.setOnAuthenticationCallback((success, message) {
      if (success) {
        print('认证成功: $message');
        // 隐藏锁屏界面
      } else {
        print('认证失败: $message');
        // 显示错误信息
      }
    });
  }
}
```

## 动态更新配置

如果您需要在运行时更改配置，有两种方式：

### 1. 使用单独的设置方法

```dart
// 单独更改设置
await appSecurityLock.setFaceIDEnabled(false);
await appSecurityLock.setPasscodeEnabled(true);
await appSecurityLock.setBackgroundTimeout(240.0);
```

### 2. 重新初始化（推荐）

```dart
// 重新初始化以应用新配置
await appSecurityLock.init(
  isFaceIDEnabled: false,
  isPasscodeEnabled: true,
  isScreenLockEnabled: true,
  backgroundTimeout: 240.0,
);
```

## 默认值

如果在初始化时不提供某个参数，将使用以下默认值：

- `isFaceIDEnabled`: `false`
- `isPasscodeEnabled`: `false`
- `isScreenLockEnabled`: `false`
- `backgroundTimeout`: `60.0` 秒

## 最佳实践

1. **在应用启动时初始化**: 在 `main()` 函数或应用的初始化阶段调用 `init()`
2. **先设置回调，再初始化**: 确保在调用 `init()` 之前设置所有回调函数
3. **根据用户偏好配置**: 可以将用户的安全设置保存到本地存储，并在初始化时使用这些设置
4. **启用安全锁**: 记住在初始化后调用 `setLockEnabled(true)` 来实际启用安全功能

## 注意事项

- 所有参数都是可选的，您可以只设置需要的参数
- 重新调用 `init()` 会覆盖之前的设置
- 生物识别功能的可用性仍然需要通过 `isBiometricAvailable()` 检查
- 屏幕锁定检测功能当前主要在iOS平台实现

这种新的初始化方式让您的应用安全配置更加简洁和集中化。

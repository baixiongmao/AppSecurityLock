# 后台超时功能使用说明

## 功能描述

后台超时功能允许您设置应用在后台运行多长时间后自动锁定。当应用进入后台并超过设定的时间后，应用会自动锁定，下次回到前台时需要进行身份验证。

## 使用方法

### 1. 设置后台超时时间

```dart
final appSecurityLock = AppSecurityLock();

// 设置后台超时时间为60秒
await appSecurityLock.setBackgroundTimeout(60.0);

// 设置后台超时时间为2分钟
await appSecurityLock.setBackgroundTimeout(120.0);

// 设置后台超时时间为5分钟
await appSecurityLock.setBackgroundTimeout(300.0);
```

### 2. 监听锁定事件

```dart
// 监听应用被锁定的事件
appSecurityLock.setOnAppLockedCallback(() {
  print('应用已被锁定');
  // 可以在这里处理锁定后的UI逻辑
});
```

### 3. 监听认证结果

```dart
// 监听认证结果（成功或失败）
appSecurityLock.setOnAuthenticationCallback((success, message) {
  if (success) {
    print('认证成功: $message');
    // 处理认证成功的逻辑
  } else {
    print('认证失败: $message');
    // 处理认证失败的逻辑
  }
});
```

## 完整示例

```dart
import 'package:app_security_lock/app_security_lock.dart';

class SecurityManager {
  final AppSecurityLock _appSecurityLock = AppSecurityLock();
  
  Future<void> initializeSecurity() async {
    // 初始化插件
    await _appSecurityLock.init();
    
    // 启用安全锁
    await _appSecurityLock.setLockEnabled(true);
    
    // 启用生物识别
    await _appSecurityLock.setFaceIDEnabled(true);
    
    // 启用密码解锁作为备选方案
    await _appSecurityLock.setPasscodeEnabled(true);
    
    // 设置后台超时时间为2分钟
    await _appSecurityLock.setBackgroundTimeout(120.0);
    
    // 设置回调
    _setupCallbacks();
  }
  
  void _setupCallbacks() {
    // 生命周期回调
    _appSecurityLock.setOnEnterForegroundCallback(() {
      print('应用进入前台');
    });
    
    _appSecurityLock.setOnEnterBackgroundCallback(() {
      print('应用进入后台，开始计时');
    });
    
    // 锁定回调
    _appSecurityLock.setOnAppLockedCallback(() {
      print('应用已被锁定');
      // 可以显示锁屏界面
    });
    
    // 认证回调
    _appSecurityLock.setOnAuthenticationCallback((success, message) {
      if (success) {
        print('解锁成功: $message');
        // 隐藏锁屏界面，恢复正常使用
      } else {
        print('解锁失败: $message');
        // 显示错误信息
      }
    });
  }
}
```

## 注意事项

1. **时间范围**: 建议设置的超时时间在30秒到5分钟之间
2. **用户体验**: 过短的超时时间可能影响用户体验，过长的超时时间可能降低安全性
3. **电池优化**: 该功能使用定时器，在应用进入前台时会自动停止，不会持续消耗电池
4. **兼容性**: 目前仅支持iOS平台，Android平台的支持正在开发中

## 工作原理

1. 当应用进入后台时，插件开始一个定时器
2. 定时器到期后，应用状态被设置为锁定
3. 当应用重新进入前台时：
   - 如果应用已被锁定，会自动触发身份验证
   - 如果用户通过了身份验证，应用解锁
   - 如果身份验证失败，应用保持锁定状态

这个功能为您的应用提供了额外的安全保护，确保在设备离开用户视线一段时间后，敏感信息得到保护。

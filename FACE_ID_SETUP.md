# Face ID 设置指南

## iOS 配置

### 1. 添加权限说明

在您的 iOS 应用的 `Info.plist` 文件中添加以下权限说明：

```xml
<key>NSFaceIDUsageDescription</key>
<string>此应用使用面容ID来进行身份验证以保护您的隐私和安全</string>
```

### 2. 确保导入正确的框架

插件已经自动导入了 `LocalAuthentication` 框架，无需额外配置。

## 使用方法

### 1. 基本设置

```dart
import 'package:app_security_lock/app_security_lock.dart';

final appSecurityLock = AppSecurityLock();

// 初始化插件
await appSecurityLock.init();
```

### 2. 检查生物识别支持

```dart
// 检查设备是否支持生物识别
bool isAvailable = await appSecurityLock.isBiometricAvailable();

// 获取生物识别类型
String type = await appSecurityLock.getBiometricType();
// 返回值: "faceID", "touchID", "opticID", "none"
```

### 3. 配置安全锁

```dart
// 启用安全锁功能
await appSecurityLock.setLockEnabled(true);

// 启用面容ID/指纹识别
await appSecurityLock.setFaceIDEnabled(true);

// 启用密码解锁作为备选方案
await appSecurityLock.setPasscodeEnabled(true);
```

### 4. 设置认证回调

```dart
// 设置认证成功回调
appSecurityLock.setOnAuthenticationSuccessCallback((success, type) {
  print('认证成功，类型: $type');
  // 处理认证成功逻辑
});

// 设置认证失败回调
appSecurityLock.setOnAuthenticationFailedCallback((success, error) {
  print('认证失败: $error');
  // 处理认证失败逻辑
});
```

### 5. 手动触发生物识别

```dart
try {
  bool result = await appSecurityLock.authenticateWithBiometric();
  if (result) {
    print('认证成功');
  } else {
    print('认证失败');
  }
} catch (e) {
  print('认证错误: $e');
}
```

### 6. 监听应用生命周期

```dart
// 设置应用进入前台回调
appSecurityLock.setOnEnterForegroundCallback(() {
  print('应用进入前台');
  // 当启用安全锁时，会自动触发认证
});

// 设置应用进入后台回调
appSecurityLock.setOnEnterBackgroundCallback(() {
  print('应用进入后台');
});
```

## 工作流程

1. 当应用从后台返回前台时，如果启用了安全锁 (`setLockEnabled(true)`)
2. 插件会检查是否启用了生物识别 (`setFaceIDEnabled(true)`)
3. 如果启用，会自动弹出生物识别提示
4. 如果生物识别失败或不可用，会尝试密码认证（如果启用）
5. 认证结果通过回调函数通知应用

## 错误处理

常见的认证错误类型：

- `用户取消了认证`: 用户主动取消认证
- `用户选择了其他认证方式`: 用户选择使用密码
- `生物识别不可用`: 设备不支持或未设置生物识别
- `未设置生物识别`: 用户未在设备上设置面容ID或指纹
- `生物识别被锁定`: 多次失败后被系统锁定

## 注意事项

1. 确保在真机上测试，模拟器可能不支持生物识别
2. 用户必须在设备上设置了面容ID或指纹才能使用
3. 建议提供密码认证作为备选方案
4. 认证对话框的文本会根据系统语言自动本地化

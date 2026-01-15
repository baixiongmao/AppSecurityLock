## 0.3.2
. 修复 deinit 中的崩溃问题
问题原因：
在 deinit 中调用 setScreenRecordingProtectionEnabled(false) 会触发异步操作
showSecurityOverlay() 和 hideSecurityOverlay() 使用了 DispatchQueue.main.async { [weak self] }
对象正在释放时，weak 引用可能失效，导致崩溃
修复方案：
在 deinit 中直接同步清理资源，不再调用可能触发异步操作的方法
直接同步移除安全覆盖视图，不使用异步操作
直接移除观察者，避免调用其他方法
2. 优化异步操作
将 showSecurityOverlay() 和 hideSecurityOverlay() 拆分为同步和异步版本
添加 performShowSecurityOverlay() 和 performHideSecurityOverlay() 方法，确保在主线程执行
在正常使用时使用异步，在 deinit 中使用同步清理
3. 修复观察者重复注册问题
移除了 setupScreenRecordingProtection() 中重复的 willEnterForegroundNotification 观察者
在 onEnterForeground() 中检查录屏状态，避免重复注册
确保观察者的添加和移除成对出现
## 0.3.1

### 🛠️ 关键修复

#### 应用后台清理崩溃问题修复
本版本修复了一个严重的稳定性问题：当用户手动从最近任务列表中清理应用时，系统会错误地提示应用已崩溃。

### 🔧 修复内容

#### Android 平台修复
- **Flutter 引擎销毁异常处理**: 在 `invokeMethod()` 中添加双层异常捕获，防止 Flutter 引擎销毁后尝试通信导致的崩溃
- **完善资源清理**: 在 `onActivityDestroyed()` 中添加完整的定时器和监听器清理逻辑
- **增强插件分离清理**: 改进 `onDetachedFromEngine()` 的资源清理流程，安全处理生命周期回调注销
- **强化计时器清理**: 对所有计时器清理方法添加异常捕获，包括后台超时和触摸超时
- **屏幕状态监听器**: 改进广播接收器的清理，正确处理 `IllegalArgumentException`

#### iOS 平台修复
- **安全方法调用**: 添加 `safeInvokeMethod()` 包装器，防止在插件销毁时调用已释放的方法通道
- **通知观察者清理**: 强化 `deinit` 方法，分别注销各个通知观察者避免竞态条件
- **UI 元素引用清理**: 清空所有 UI 元素引用，包括手势识别器和覆盖视图
- **方法调用安全**: 将所有 `lifecycleChannel?.invokeMethod()` 调用替换为安全调用

### ⚡ 稳定性改进

- **异常容错**: 所有可能产生异常的操作都添加了 try-catch 保护
- **内存泄漏防护**: 确保所有定时器、监听器和引用在适当时机被正确清理
- **竞态条件处理**: 处理多线程环境下的资源清理竞态条件

### 🧪 测试建议

为验证修复效果，请按以下步骤测试：

1. **Android 测试**: 启用后台锁定功能 → 将应用发送到后台 → 从最近任务列表滑动清除应用 → 验证不出现崩溃提示
2. **iOS 测试**: 启用后台锁定和触摸超时 → 将应用发送到后台 → 从任务列表向上滑动移除应用 → 验证不出现崩溃
3. **Debug 验证**: 在 `init()` 时传入 `debug: true`，通过原生日志查看清理过程

## 0.3.0

### 🎬 屏幕录制防护功能

本版本新增了强大的屏幕录制防护功能，确保应用内容不被非法录屏。

### ✨ 新特性

- **屏幕录制防护**: 禁止对应用进行屏幕录制
- **自定义警告文本**: 支持自定义录屏时显示的警告提示文本 **仅限IOS**
- **iOS 模糊覆盖视图**: 检测到录屏时显示带有模糊效果的安全覆盖层
- **Android FLAG_SECURE**: 使用系统级别的FLAG_SECURE标志禁止屏幕录制

### 📱 平台实现

#### iOS
- 监听屏幕录制状态变化通知 (`UIScreen.capturedDidChangeNotification`)
- 检测到录屏时显示模糊效果的安全覆盖视图
- 覆盖视图上显示自定义的警告文本
- 拦截所有触摸事件防止操作被录制

#### Android
- 使用 `WindowManager.LayoutParams.FLAG_SECURE` 标志禁止屏幕录制
- 防止应用内容在屏幕录制中出现

### 🔧 新增 API

```dart
// 启用/禁用录屏防护，支持自定义警告文本
Future<AppSecurityLock> screenRecordingProtectionEnabled(
  bool enabled, {
  String? warningMessage,
})
```

### 💡 使用示例

```dart
// 启用录屏防护并显示自定义文本
await lock.screenRecordingProtectionEnabled(
  true,
  warningMessage: '⚠️ 检测到屏幕录制，该操作已被阻止',
);

// 禁用录屏防护
await lock.screenRecordingProtectionEnabled(false);

// 也可以使用链式调用
await lock.screenRecordingProtectionEnabled(
  true,
  warningMessage: '屏幕正在被录制',
);
```

## 0.2.0

### 🎉 API 重构 & 链式调用支持

本版本对 API 进行了全面重构，提供更简洁、更直观的使用方式。

### ✨ 新特性

- **链式调用支持**: 所有方法现在支持链式调用，代码更简洁
- **锁定原因回调**: `onLock` 回调现在包含 `LockReason` 参数，可以知道是什么导致了锁定
- **新增 LockReason 枚举**: 
  - `LockReason.screenLock` - 设备屏幕锁定
  - `LockReason.backgroundTimeout` - 后台超时
  - `LockReason.touchTimeout` - 触摸超时（无操作超时）
  - `LockReason.unknown` - 未知原因

### 🔄 API 变更

| 旧 API | 新 API | 说明 |
|---------|---------|------|
| `setOnAppLockedCallback(callback)` | `onLock((reason) => ...)` | 支持链式调用，包含锁定原因 |
| `setOnAppUnlockedCallback(callback)` | `onUnlock(callback)` | 支持链式调用 |
| `setOnEnterForegroundCallback(callback)` | `onForeground(callback)` | 支持链式调用 |
| `setOnEnterBackgroundCallback(callback)` | `onBackground(callback)` | 支持链式调用 |
| `setLockEnabled(enabled)` | `setLocked(enabled)` / `lock()` / `unlock()` | 更语义化 |
| `setScreenLockEnabled(enabled)` | `screenLockEnabled(enabled)` | 支持链式调用 |
| `setBackgroundLockEnabled(enabled)` | `backgroundLockEnabled(enabled)` | 支持链式调用 |
| `setBackgroundTimeout(seconds)` | `backgroundTimeout(seconds)` | 支持链式调用 |
| `setTouchTimeoutEnabled(enabled)` | `touchTimeoutEnabled(enabled)` | 支持链式调用 |
| `setTouchTimeout(seconds)` | `touchTimeout(seconds)` | 支持链式调用 |
| `restartTouchTimer()` | `resetTouchTimer()` | 更语义化 |

### 📝 使用示例

```dart
// 新的链式调用方式
final lock = AppSecurityLock()
  ..onLock((reason) {
    print('应用已锁定，原因: ${reason.name}');
    // reason: screenLock / backgroundTimeout / touchTimeout / unknown
  })
  ..onUnlock(() => print('请解锁应用'))
  ..onForeground(() => print('进入前台'))
  ..onBackground(() => print('进入后台'));

await lock.init(
  isScreenLockEnabled: true,
  isBackgroundLockEnabled: true,
  backgroundTimeout: 30.0,
);
```

### ⚙️ 向后兼容

- 旧 API 仍然可用，但已标记为 `@Deprecated`
- 建议尽快迁移到新 API

## 0.1.1
添加安卓web_view 触摸检测支持
## 0.1.0
新增debug倒计时
## 0.0.9
降级示例代码的SDK版本，删除测试文件
## 0.0.8
降级flutter 版本和dart版本要求，以适配老项目
## 0.0.7-fix.1
修复ios 构建错误
## 0.0.7-fix
添加安卓缺失的括号

## 0.0.7

### Debug Logging Enhancement

* **New Debug Field**: Added debug parameter to control log output for better development experience
* **Configurable Logging**: Developers can now enable/disable plugin logs based on debug mode
* **Development Support**: Enhanced debugging capabilities for easier troubleshooting during development

### New Features

- ✅ **Debug Control**: New debug field parameter to toggle log output
- ✅ **Conditional Logging**: Logs are now shown only when debug mode is enabled
- ✅ **Developer Experience**: Improved debugging workflow with controllable log verbosity
- ✅ **Production Ready**: Clean log output in production builds when debug is disabled

### Technical Improvements

- 🔧 Added debug parameter support across all platform implementations
- 🔧 Enhanced logging system with conditional output
- 🔧 Improved development workflow with debug controls
- 🔧 Optimized log management for production builds

## 0.0.6

### Enhanced iOS Screen Lock Detection

* **Improved Production Reliability**: Fixed iOS screen lock detection not working in production builds
* **Native iOS Notification System**: Replaced unreliable brightness detection with system-level `protectedData` notifications
* **Superior Lock Detection**: Uses `UIApplication.protectedDataWillBecomeUnavailableNotification` and `protectedDataDidBecomeAvailableNotification` for accurate screen lock events
* **Production-Ready**: Eliminates brightness threshold issues that caused failures in release builds

### iOS Implementation Changes

- ✅ **New Lock Detection Method**: Implemented `protectedData` notification observers for reliable screen lock detection
- ✅ **Removed Brightness Detection**: Completely removed unreliable brightness-based screen lock detection
- ✅ **System-Level Integration**: Uses iOS native notification center for optimal performance
- ✅ **Production Build Compatible**: Resolves screen lock detection failures in production/release builds

### Technical Improvements

- 🔧 Added `screenLocked()` and `screenUnlocked()` callback methods
- 🔧 Enhanced `startListen()` method with protectedData notification observers
- 🔧 Cleaned up brightness timer and related detection methods
- 🔧 Improved iOS app lifecycle integration
- 🔧 Optimized notification center observer management

### Bug Fixes

- 🐛 Fixed screen lock detection not working in iOS production builds
- 🐛 Resolved brightness threshold reliability issues
- 🐛 Improved app state monitoring accuracy
- 🐛 Enhanced notification system performance

## 0.0.4

### Touch Timeout Lock Feature

* **New Touch Timeout Functionality**: Added touch event monitoring with configurable timeout lock
* **Cross-Platform Touch Detection**: Implemented touch event listeners for both iOS and Android
* **Gesture Recognition System**: iOS uses UITapGestureRecognizer and UIPanGestureRecognizer for comprehensive touch detection
* **Configurable Touch Timeout**: Support for custom touch timeout duration and enable/disable state
* **Touch Timer Management**: Smart touch timer restart mechanism with infinite loop prevention
* **Enhanced Security**: App automatically locks after period of user inactivity

### New APIs

- ✅ `setTouchTimeoutEnabled(bool enabled)` - Enable/disable touch timeout functionality
- ✅ `setTouchTimeout(double timeoutSeconds)` - Configure touch timeout duration
- ✅ `restartTouchTimer()` - Manual restart of touch timeout timer
- ✅ Support for touch timeout parameters in `init()` method

### Platform Updates

- ✅ **iOS**: Comprehensive gesture recognizer implementation with UIWindow-based touch detection
- ✅ **Android**: Touch timeout timer management with Handler and Runnable
- ✅ **iOS**: Upgraded minimum version to iOS 13.0 for enhanced functionality
- ✅ Fixed infinite loop issues in touch event listener setup
- ✅ Improved touch timer lifecycle management

### Bug Fixes

- 🐛 Fixed touch event listener infinite loop during screen interactions
- 🐛 Resolved touch timer not restarting properly after unlock
- 🐛 Fixed touch event listeners not being set up correctly on init
- 🐛 Improved touch timer state management during app lifecycle changes

## 0.0.3

### Swift Package Manager Support

* **Added Swift Package Manager Support**: Package now supports iOS Swift Package Manager
* **Full pub.dev Score Compliance**: Added `ios/app_security_lock/Package.swift` for complete pub.dev compatibility
* **Future-proof iOS Integration**: Ensures maximum compatibility with modern iOS development workflows

### Changes

- ✅ Added `Package.swift` file for Swift Package Manager support
- ✅ Configured iOS platform minimum version (iOS 11.0+)
- ✅ Enhanced pub.dev scoring compliance
- ✅ Improved iOS integration options for developers

## 0.0.2

### Improvements & Bug Fixes

* **Enhanced Documentation**: Improved README with better usage examples and API documentation
* **Better pub.dev Score**: Optimized package metadata for higher pub.dev analysis score
* **Improved Example App**: Enhanced example app with better UI and event logging
* **Test Coverage**: Fixed and improved unit tests for better reliability
* **Code Quality**: Resolved all dart analyze warnings and issues
* **Repository Links**: Added proper repository, issue tracker, and documentation URLs

### Changes

- ✅ Updated pubspec.yaml with complete repository information
- ✅ Enhanced CHANGELOG with detailed release notes
- ✅ Improved example app UI with event logs display
- ✅ Fixed all dart analyze issues (0 warnings)
- ✅ Updated test files to match current API
- ✅ Better error handling and code documentation

## 0.0.1

### Initial Release

* **Screen Lock Detection**: Monitor when device screen is locked/unlocked
* **Background Timeout**: Automatically lock app when backgrounded for specified duration
* **Lifecycle Monitoring**: Track app lifecycle events (foreground/background)
* **Biometric Authentication**: Support for fingerprint and face recognition
* **Cross-platform Support**: Works on both iOS and Android
* **Configurable Settings**: Customizable timeout periods and feature toggles

### Features

- ✅ Screen lock/unlock detection
- ✅ Background timeout with configurable duration
- ✅ Application lifecycle monitoring
- ✅ Biometric authentication integration
- ✅ iOS and Android platform support
- ✅ Easy integration with existing Flutter apps

### Platform Support

- **iOS**: iOS 11.0 or later
- **Android**: API level 21 (Android 5.0) or later

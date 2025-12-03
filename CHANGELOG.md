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

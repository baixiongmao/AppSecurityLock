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

# App Security Lock

A comprehensive Flutter plugin for implementing app security features including screen lock detection, background timeout, touch timeout monitoring, and lifecycle management.

## Features

- **Screen Lock Detection**: Automatically locks the app when the device screen is turned off
- **Background Timeout**: Locks the app after a specified time in the background  
- **Touch Timeout Lock**: Locks the app after period of user inactivity
- **Lifecycle Monitoring**: Tracks app foreground/background state changes
- **Cross-platform**: Supports both iOS and Android
- **Customizable**: Flexible configuration options for different security needs

## Platform Support

| Platform | Support |
|----------|---------|
| iOS      | ✅      |
| Android  | ✅      |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  app_security_lock: ^0.0.5
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

```dart
import 'package:app_security_lock/app_security_lock.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppSecurityLock _appSecurityLock = AppSecurityLock();

  @override
  void initState() {
    super.initState();
    _initializeSecurityLock();
  }

  void _initializeSecurityLock() async {
    // Initialize the plugin with security settings
    await _appSecurityLock.init(
      isScreenLockEnabled: true,
      isBackgroundLockEnabled: true,
      backgroundTimeout: 30.0, // 30 seconds
      isTouchTimeoutEnabled: true,
      touchTimeout: 60.0, // 60 seconds
    );

    // Set up lifecycle callbacks
    _appSecurityLock.setOnAppLockedCallback(() {
      print('App is locked - show authentication screen');
      _showAuthenticationScreen();
    });

    _appSecurityLock.setOnAppUnlockedCallback(() {
      print('App is unlocked');
    });
  }

  void _showAuthenticationScreen() {
    // Implement your authentication UI here
    // For example, navigate to a biometric authentication screen
  }
}
```

### Configuration Options

```dart
// Initialize with all options
await _appSecurityLock.init(
  isScreenLockEnabled: true,     // Lock app when screen turns off
  isBackgroundLockEnabled: true, // Lock app after background timeout
  backgroundTimeout: 60.0,       // Background timeout in seconds
  isTouchTimeoutEnabled: true,   // Lock app after touch inactivity
  touchTimeout: 30.0,            // Touch timeout in seconds
);
```
### Dynamic Configuration

```dart
// Enable/disable screen lock detection
_appSecurityLock.setScreenLockEnabled(true);

// Enable/disable background lock
_appSecurityLock.setBackgroundLockEnabled(true);

// Update background timeout (in seconds)
_appSecurityLock.setBackgroundTimeout(45.0);

// Enable/disable touch timeout
_appSecurityLock.setTouchTimeoutEnabled(true);

// Update touch timeout (in seconds)
_appSecurityLock.setTouchTimeout(30.0);

// Manually restart touch timer
_appSecurityLock.restartTouchTimer();

// Manually lock the app
_appSecurityLock.setLockEnabled(true);
```

### Lifecycle Callbacks

```dart
// App gets locked
_appSecurityLock.setOnAppLockedCallback(() {
  // Show authentication screen
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => AuthenticationScreen()),
  );
});

// App gets unlocked  
_appSecurityLock.setOnAppUnlockedCallback(() {
  // App is now accessible
});

// App enters foreground (optional)
_appSecurityLock.setOnEnterForegroundCallback(() {
  // Handle foreground event
});

// App enters background (optional)
_appSecurityLock.setOnEnterBackgroundCallback(() {
  // Handle background event
});
```

## API Reference

### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `init()` | Initialize the plugin | `isScreenLockEnabled`, `isBackgroundLockEnabled`, `backgroundTimeout`, `isTouchTimeoutEnabled`, `touchTimeout` |
| `setLockEnabled()` | Manually lock/unlock the app | `bool enabled` |
| `setScreenLockEnabled()` | Enable/disable screen lock detection | `bool enabled` |
| `setBackgroundLockEnabled()` | Enable/disable background lock | `bool enabled` |
| `setBackgroundTimeout()` | Set background timeout duration | `double timeoutSeconds` |
| `setTouchTimeoutEnabled()` | Enable/disable touch timeout lock | `bool enabled` |
| `setTouchTimeout()` | Set touch timeout duration | `double timeoutSeconds` |
| `restartTouchTimer()` | Manually restart touch timeout timer | - |

### Callbacks

| Callback | Description |
|----------|-------------|
| `setOnAppLockedCallback()` | Called when app gets locked |
| `setOnAppUnlockedCallback()` | Called when app gets unlocked |
| `setOnEnterForegroundCallback()` | Called when app enters foreground |
| `setOnEnterBackgroundCallback()` | Called when app enters background |

## Platform-Specific Behavior

### iOS
- Uses `UIApplication` lifecycle notifications
- Monitors screen brightness changes for lock detection
- Touch events monitored via `UIGestureRecognizer` (UITapGestureRecognizer & UIPanGestureRecognizer)
- Supports background timeout with timers

### Android
- Uses `Application.ActivityLifecycleCallbacks`
- Monitors screen state with broadcast receivers (`ACTION_SCREEN_OFF`, `ACTION_SCREEN_ON`, `ACTION_USER_PRESENT`)
- Touch events monitored via `OnTouchListener`
- Enhanced screen monitoring that stays active regardless of lock state
- Supports background timeout with handlers

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

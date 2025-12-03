# App Security Lock

A comprehensive Flutter plugin for implementing app security features including screen lock detection, background timeout, touch timeout and lifecycle monitoring. **Supports chain calls and lock reason callbacks.**

## Features

- **Screen Lock Detection**: Automatically locks the app when the device screen is turned off
- **Background Timeout**: Locks the app after a specified time in the background
- **Touch Timeout**: Locks the app after a period of user inactivity
- **Lock Reason Callback**: Know exactly why the app was locked (screen lock, background timeout, or touch timeout)
- **Chain Calls**: Fluent API design for cleaner code
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
  app_security_lock: ^0.2.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup (Recommended - Chain Calls)

```dart
import 'package:app_security_lock/app_security_lock.dart';

class _MyAppState extends State<MyApp> {
  late final AppSecurityLock _lock;

  @override
  void initState() {
    super.initState();
    
    // Use chain calls to set up all callbacks
    _lock = AppSecurityLock()
      ..onLock((reason) {
        print('App locked, reason: ${reason.name}');
        // reason: screenLock / backgroundTimeout / touchTimeout / unknown
        _showAuthenticationScreen();
      })
      ..onUnlock(() => print('Please unlock the app'))
      ..onForeground(() => print('App entered foreground'))
      ..onBackground(() => print('App entered background'));

    // Initialize the plugin
    _lock.init(
      isScreenLockEnabled: true,
      isBackgroundLockEnabled: true,
      backgroundTimeout: 30.0,
      isTouchTimeoutEnabled: false,
      touchTimeout: 60.0,
      debug: true, // Enable debug logs in native console
    );
  }

  void _showAuthenticationScreen() {
    // Implement your authentication UI here
  }
}
```

### Lock Reason

The `onLock` callback now includes a `LockReason` parameter:

```dart
_lock.onLock((reason) {
  switch (reason) {
    case LockReason.screenLock:
      print('Locked due to device screen lock');
      break;
    case LockReason.backgroundTimeout:
      print('Locked due to background timeout');
      break;
    case LockReason.touchTimeout:
      print('Locked due to inactivity timeout');
      break;
    case LockReason.unknown:
      print('Locked for unknown reason');
      break;
  }
});
```

### Configuration Options

```dart
// Initialize with all options
await _lock.init(
  isScreenLockEnabled: true,      // Lock app when screen turns off
  isBackgroundLockEnabled: true,  // Lock app after background timeout
  backgroundTimeout: 60.0,        // Background timeout in seconds
  isTouchTimeoutEnabled: true,    // Lock app after inactivity
  touchTimeout: 120.0,            // Inactivity timeout in seconds
  debug: false,                   // Enable debug logs (native console)
);
```

### Dynamic Configuration (Chain Calls)

```dart
// All methods support chain calls
_lock
  ..screenLockEnabled(true)
  ..backgroundLockEnabled(true);

// Async methods also support chain calls
await _lock.backgroundTimeout(45.0);
await _lock.touchTimeout(90.0);
await _lock.touchTimeoutEnabled(true);

// Lock/Unlock the app
await _lock.lock();    // Lock the app
await _lock.unlock();  // Unlock the app

// Or use setLocked
await _lock.setLocked(true);

// Reset touch timer (extend inactivity timeout)
_lock.resetTouchTimer();
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:app_security_lock/app_security_lock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppSecurityLock _lock;
  bool _isLocked = false;
  LockReason? _lockReason;

  @override
  void initState() {
    super.initState();
    
    _lock = AppSecurityLock()
      ..onLock((reason) {
        setState(() {
          _isLocked = true;
          _lockReason = reason;
        });
      })
      ..onUnlock(() {
        // Prompt for authentication
      })
      ..onForeground(() => print('Foreground'))
      ..onBackground(() => print('Background'));

    _lock.init(
      isScreenLockEnabled: true,
      isBackgroundLockEnabled: true,
      backgroundTimeout: 30.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('App is Locked', style: TextStyle(fontSize: 24)),
                if (_lockReason != null)
                  Text('Reason: ${_lockReason!.name}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await _lock.unlock();
                    setState(() => _isLocked = false);
                  },
                  child: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('App Security Lock Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => _lock.lock(),
            child: const Text('Lock App'),
          ),
        ),
      ),
    );
  }
}
```

## API Reference

### Initialization

| Method | Description |
|--------|-------------|
| `init()` | Initialize the plugin with configuration options |

### Event Callbacks (Chain Calls Supported)

| Method | Description |
|--------|-------------|
| `onLock((LockReason reason) => ...)` | Called when app gets locked, includes lock reason |
| `onUnlock(() => ...)` | Called when app needs to be unlocked |
| `onForeground(() => ...)` | Called when app enters foreground |
| `onBackground(() => ...)` | Called when app enters background |

### Lock Reason

| Value | Description |
|-------|-------------|
| `LockReason.screenLock` | Device screen was locked |
| `LockReason.backgroundTimeout` | App was in background too long |
| `LockReason.touchTimeout` | No user interaction for too long |
| `LockReason.unknown` | Unknown reason |

### Lock Control (Chain Calls Supported)

| Method | Description |
|--------|-------------|
| `lock()` | Lock the app |
| `unlock()` | Unlock the app |
| `setLocked(bool)` | Set lock state |

### Screen Lock Settings

| Method | Description |
|--------|-------------|
| `screenLockEnabled(bool)` | Enable/disable screen lock detection |

### Background Lock Settings

| Method | Description |
|--------|-------------|
| `backgroundLockEnabled(bool)` | Enable/disable background lock |
| `backgroundTimeout(double)` | Set background timeout (seconds) |

### Touch Timeout Settings

| Method | Description |
|--------|-------------|
| `touchTimeoutEnabled(bool)` | Enable/disable touch timeout |
| `touchTimeout(double)` | Set touch timeout (seconds) |
| `resetTouchTimer()` | Reset the inactivity timer |

## Migration from v0.1.x

If you're upgrading from v0.1.x, here's how to migrate:

```dart
// Old API (deprecated but still works)
_lock.setOnAppLockedCallback(() => print('locked'));
_lock.setOnEnterForegroundCallback(() => print('foreground'));
_lock.setBackgroundTimeout(30.0);

// New API (recommended)
_lock
  ..onLock((reason) => print('locked: ${reason.name}'))
  ..onForeground(() => print('foreground'));
await _lock.backgroundTimeout(30.0);
```

## Platform-Specific Behavior

### iOS
- Uses `UIApplication` lifecycle notifications
- Uses `protectedData` notifications for reliable screen lock detection
- Supports background timeout with timers
- Touch detection via gesture recognizers

### Android
- Uses `Application.ActivityLifecycleCallbacks`
- Monitors screen state with broadcast receivers (`ACTION_SCREEN_OFF`, `ACTION_SCREEN_ON`, `ACTION_USER_PRESENT`)
- Supports background timeout with handlers
- Touch detection via Window.Callback

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

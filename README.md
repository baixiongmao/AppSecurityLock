# App Security Lock

A comprehensive Flutter plugin for implementing app security features including screen lock detection, background timeout, and lifecycle monitoring.

## Features

- **Screen Lock Detection**: Automatically locks the app when the device screen is turned off
- **Background Timeout**: Locks the app after a specified time in the background
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
  app_security_lock: ^0.0.1
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
    );

    // Set up lifecycle callbacks
    _appSecurityLock.setOnEnterForegroundCallback(() {
      print('App entered foreground');
    });

    _appSecurityLock.setOnEnterBackgroundCallback(() {
      print('App entered background');
    });

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
  isScreenLockEnabled: true,    // Lock app when screen turns off
  isBackgroundLockEnabled: true, // Lock app after background timeout
  backgroundTimeout: 60.0,      // Background timeout in seconds
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

// Manually lock the app
_appSecurityLock.setLockEnabled(true);
```

### Lifecycle Callbacks

```dart
// App enters foreground
_appSecurityLock.setOnEnterForegroundCallback(() {
  // Handle foreground event
});

// App enters background
_appSecurityLock.setOnEnterBackgroundCallback(() {
  // Handle background event
});

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
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:app_security_lock/app_security_lock.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppSecurityLock _appSecurityLock = AppSecurityLock();
  bool _isLocked = false;
  bool _isScreenLockEnabled = true;
  bool _isBackgroundLockEnabled = true;
  double _backgroundTimeout = 30.0;

  @override
  void initState() {
    super.initState();
    _setupSecurityLock();
  }

  void _setupSecurityLock() async {
    // Initialize with default settings
    await _appSecurityLock.init(
      isScreenLockEnabled: _isScreenLockEnabled,
      isBackgroundLockEnabled: _isBackgroundLockEnabled,
      backgroundTimeout: _backgroundTimeout,
    );

    // Setup callbacks
    _appSecurityLock.setOnAppLockedCallback(() {
      setState(() {
        _isLocked = true;
      });
    });

    _appSecurityLock.setOnAppUnlockedCallback(() {
      setState(() {
        _isLocked = false;
      });
    });
  }

  void _toggleScreenLock() {
    setState(() {
      _isScreenLockEnabled = !_isScreenLockEnabled;
    });
    _appSecurityLock.setScreenLockEnabled(_isScreenLockEnabled);
  }

  void _toggleBackgroundLock() {
    setState(() {
      _isBackgroundLockEnabled = !_isBackgroundLockEnabled;
    });
    _appSecurityLock.setBackgroundLockEnabled(_isBackgroundLockEnabled);
  }

  void _updateTimeout(double value) {
    setState(() {
      _backgroundTimeout = value;
    });
    _appSecurityLock.setBackgroundTimeout(_backgroundTimeout);
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
                Icon(Icons.lock, size: 64, color: Colors.red),
                Text('App is Locked', style: TextStyle(fontSize: 24)),
                ElevatedButton(
                  onPressed: () {
                    _appSecurityLock.setLockEnabled(false);
                  },
                  child: Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('App Security Lock Demo')),
        body: Padding(
          padding: EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text('Screen Lock Detection'),
              subtitle: Text('Lock app when screen turns off'),
              value: _isScreenLockEnabled,
              onChanged: (value) => _toggleScreenLock(),
            ),
            SwitchListTile(
              title: Text('Background Lock'),
              subtitle: Text('Lock app after background timeout'),
              value: _isBackgroundLockEnabled,
              onChanged: (value) => _toggleBackgroundLock(),
            ),
            ListTile(
              title: Text('Background Timeout'),
              subtitle: Slider(
                value: _backgroundTimeout,
                min: 5.0,
                max: 300.0,
                divisions: 59,
                label: '${_backgroundTimeout.round()}s',
                onChanged: _updateTimeout,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _appSecurityLock.setLockEnabled(true);
              },
              child: Text('Lock App Manually'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `init()` | Initialize the plugin | `isScreenLockEnabled`, `isBackgroundLockEnabled`, `backgroundTimeout` |
| `setLockEnabled()` | Manually lock/unlock the app | `bool enabled` |
| `setScreenLockEnabled()` | Enable/disable screen lock detection | `bool enabled` |
| `setBackgroundLockEnabled()` | Enable/disable background lock | `bool enabled` |
| `setBackgroundTimeout()` | Set background timeout duration | `double timeoutSeconds` |

### Callbacks

| Callback | Description |
|----------|-------------|
| `setOnEnterForegroundCallback()` | Called when app enters foreground |
| `setOnEnterBackgroundCallback()` | Called when app enters background |
| `setOnAppLockedCallback()` | Called when app gets locked |
| `setOnAppUnlockedCallback()` | Called when app gets unlocked |

## Platform-Specific Behavior

### iOS
- Uses `UIApplication` lifecycle notifications
- Monitors screen brightness changes for lock detection
- Supports background timeout with timers

### Android
- Uses `Application.ActivityLifecycleCallbacks`
- Monitors screen state with broadcast receivers (`ACTION_SCREEN_OFF`, `ACTION_SCREEN_ON`, `ACTION_USER_PRESENT`)
- Supports background timeout with handlers

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

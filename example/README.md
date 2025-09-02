# App Security Lock Example

This example demonstrates how to use the app_security_lock plugin.

## Features Demonstrated

- Screen lock detection
- Background timeout configuration
- Lifecycle monitoring
- Biometric authentication

## Running the Example

1. Clone the repository
2. Navigate to the example directory
3. Run `flutter pub get`
4. Run `flutter run`

## Code Structure

- `lib/main.dart` - Main example application
- `android/` - Android-specific configuration
- `ios/` - iOS-specific configuration

The example shows how to:
- Initialize the plugin with custom settings
- Handle security events
- Implement biometric authentication
- Monitor app lifecycle changes

## Platform Requirements

### iOS
- iOS 11.0 or later
- Biometric authentication requires iOS 11.0+

### Android
- API level 21 (Android 5.0) or later
- Biometric authentication requires API level 23+

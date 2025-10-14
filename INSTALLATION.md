# Installation Guide

## Table of Contents
1. [For Bare React Native Projects](#bare-react-native)
2. [For Expo Projects](#expo-projects)
3. [iOS Configuration](#ios-configuration)
4. [Android Configuration](#android-configuration)
5. [Troubleshooting](#troubleshooting)

## Bare React Native

### 1. Install the Package

```bash
npm install react-native-call-keeper
# or
yarn add react-native-call-keeper
```

### 2. Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

### 3. iOS Configuration

Add these entries to your `ios/YourApp/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>voip</string>
  <string>audio</string>
</array>
```

### 4. Android Configuration

The required permissions are automatically added by the library. However, you need to request runtime permissions in your app:

```typescript
import { PermissionsAndroid, Platform } from 'react-native';

if (Platform.OS === 'android') {
  const granted = await PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
    PermissionsAndroid.PERMISSIONS.CALL_PHONE,
    PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
    PermissionsAndroid.PERMISSIONS.READ_CALL_LOG,
    PermissionsAndroid.PERMISSIONS.WRITE_CALL_LOG,
  ]);
}
```

### 5. Rebuild Your App

```bash
# iOS
npm run ios

# Android
npm run android
```

## Expo Projects

### 1. Install the Package

```bash
npx expo install react-native-call-keeper
```

### 2. Add Config Plugin

Add the plugin to your `app.json` or `app.config.js`:

**app.json:**
```json
{
  "expo": {
    "name": "your-app-name",
    "plugins": [
      "react-native-call-keeper"
    ]
  }
}
```

**app.config.js:**
```javascript
export default {
  expo: {
    name: 'your-app-name',
    plugins: ['react-native-call-keeper'],
  },
};
```

### 3. Prebuild and Run

```bash
# Generate native projects
npx expo prebuild

# Run on iOS
npx expo run:ios

# Run on Android
npx expo run:android
```

### 4. Request Permissions (Android)

Add this to your app (typically in `App.tsx` or a permission helper):

```typescript
import { PermissionsAndroid, Platform } from 'react-native';

async function requestCallPermissions() {
  if (Platform.OS === 'android') {
    const permissions = [
      PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
      PermissionsAndroid.PERMISSIONS.CALL_PHONE,
      PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
      PermissionsAndroid.PERMISSIONS.READ_CALL_LOG,
      PermissionsAndroid.PERMISSIONS.WRITE_CALL_LOG,
    ];

    const granted = await PermissionsAndroid.requestMultiple(permissions);
    
    const allGranted = Object.values(granted).every(
      status => status === PermissionsAndroid.RESULTS.GRANTED
    );

    return allGranted;
  }
  return true;
}
```

## iOS Configuration

### Background Modes

The library requires VoIP and audio background modes. These are automatically added by the Expo config plugin, but for bare React Native projects, add them manually to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>voip</string>
  <string>audio</string>
</array>
```

### VoIP Push Notifications (Optional)

If you want to receive incoming calls when the app is closed, you need to set up VoIP push notifications:

1. Enable Push Notifications capability in Xcode
2. Enable Background Modes > Voice over IP
3. Implement PushKit in your app
4. Register for VoIP notifications

Example:
```typescript
import PushNotificationIOS from '@react-native-community/push-notification-ios';
import VoipPushNotification from 'react-native-voip-push-notification';

// Setup VoIP Push
VoipPushNotification.addEventListener('register', (token) => {
  // Send token to your server
  console.log('VoIP token:', token);
});

VoipPushNotification.addEventListener('notification', (notification) => {
  // Display incoming call
  CallKeeper.displayIncomingCall(
    notification.uuid,
    notification.callerNumber,
    notification.callerName,
    'number',
    false
  );
});

VoipPushNotification.registerVoipToken();
```

## Android Configuration

### Permissions

The following permissions are automatically added by the library:

- `BIND_TELECOM_CONNECTION_SERVICE` - Required for ConnectionService
- `FOREGROUND_SERVICE` - For foreground service
- `READ_PHONE_STATE` - Read phone state
- `CALL_PHONE` - Make phone calls
- `RECORD_AUDIO` - Audio recording
- `WAKE_LOCK` - Keep device awake
- `READ_CALL_LOG` - Read call log
- `WRITE_CALL_LOG` - Write to call log
- `MANAGE_OWN_CALLS` - Manage own calls

### Runtime Permission Request

You must request these permissions at runtime:

```typescript
import { PermissionsAndroid } from 'react-native';

const permissions = [
  PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
  PermissionsAndroid.PERMISSIONS.CALL_PHONE,
  PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
  PermissionsAndroid.PERMISSIONS.READ_CALL_LOG,
  PermissionsAndroid.PERMISSIONS.WRITE_CALL_LOG,
];

const results = await PermissionsAndroid.requestMultiple(permissions);
```

### Phone Account Registration

Android requires registering a phone account for ConnectionService. This is automatically done when you call `setup()`:

```typescript
await CallKeeper.setup({
  appName: 'MyApp',
  supportsVideo: true,
});
```

### Self-Managed Connection

This library uses Android's self-managed connection mode (API 26+), which means:
- Your app handles all call UI
- Calls don't show in the native dialer
- Better privacy and control
- Works great for VoIP apps

## New Architecture

### Enabling New Architecture

This library fully supports React Native's New Architecture (Fabric/TurboModules).

**For Android** (`android/gradle.properties`):
```properties
newArchEnabled=true
```

**For iOS** (in your Podfile):
```ruby
ENV['RCT_NEW_ARCH_ENABLED'] = '1'
```

Then rebuild your app:
```bash
cd ios && pod install && cd ..
npm run ios

# For Android
npm run android
```

The library will automatically detect and use the appropriate architecture.

## Troubleshooting

### iOS: Module not found

If you see "module 'CallKeeper' not found":
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
npm run ios
```

### Android: Build errors

If you encounter build errors:
```bash
cd android
./gradlew clean
cd ..
npm run android
```

### Expo: Module not registered

If using Expo and seeing "Native module cannot be null":
```bash
npx expo prebuild --clean
npx expo run:ios  # or run:android
```

### Permissions not working on Android

Make sure you're requesting permissions at runtime, not just declaring them in AndroidManifest.xml. Android 6.0+ requires runtime permission requests.

### CallKit not showing on iOS

Verify that:
1. Background modes are enabled in Info.plist
2. You're testing on a real device (simulator has limitations)
3. Do Not Disturb is not enabled
4. The app has proper entitlements

### Need Help?

- Check the [main README](./README.md) for usage examples
- Review the [example app](./example/App.tsx)
- Open an issue on GitHub
- Check existing issues for solutions

## Minimum Requirements

- **React Native**: 0.70.0 or higher
- **iOS**: 13.0 or higher
- **Android**: API level 23 (Android 6.0) or higher
- **Node.js**: 18.0.0 or higher
- **Xcode**: 14.0 or higher (for iOS development)
- **Android Studio**: 2022.1 or higher (for Android development)

## Next Steps

After installation, check out:
- [Usage Examples](./README.md#usage)
- [API Reference](./README.md#api-reference)
- [Example App](./example/App.tsx)


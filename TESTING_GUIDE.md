# CallKeeper Testing Guide

This guide helps you test the `react-native-call-keeper` package to ensure it's working correctly.

## Prerequisites

### iOS
- iOS 10+ device or simulator
- Xcode 12+
- CocoaPods installed

### Android
- Android 6.0+ (API 23+) device or emulator  
- Android Studio

## Quick Test

### 1. Install the Package

```bash
npm install react-native-call-keeper@latest
```

For iOS:
```bash
cd ios && pod install && cd ..
```

### 2. iOS Configuration

Add to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

### 3. Android Configuration

Add to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BIND_TELECOM_CONNECTION_SERVICE"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
```

### 4. Use the Test Component

Copy the example test component:

```tsx
import TestCallKeeper from 'react-native-call-keeper/example/TestCallKeeper';

export default function App() {
  return <TestCallKeeper />;
}
```

Or use the minimal test:

```typescript
import CallKeeper from 'react-native-call-keeper';

// 1. Setup
await CallKeeper.setup({
  appName: 'MyApp',
  supportsVideo: true,
});

// 2. Display incoming call
await CallKeeper.displayIncomingCall(
  'unique-call-uuid',
  '+1234567890',
  'John Doe',
  'number',
  false
);

// 3. Listen for events
CallKeeper.addEventListener('answerCall', (event) => {
  console.log('User answered call:', event.callUUID);
});

CallKeeper.addEventListener('endCall', (event) => {
  console.log('Call ended:', event.callUUID);
});
```

## Debugging

### Check if Module is Loaded

Add this to your code:

```typescript
import { NativeModules } from 'react-native';

console.log('CallKeeper module:', NativeModules.CallKeeper);
```

If it returns `undefined`, the module isn't linked properly.

### iOS Debugging

Check Xcode console logs for `[RNCallKeep]` messages:

```
[RNCallKeep][setup] options = ...
[RNCallKeep][displayIncomingCall] ...
```

### Android Debugging

Use `adb logcat` to see logs:

```bash
adb logcat | grep CallKeeper
```

## Common Issues

### iOS: Module not found

**Solution**: 
1. Clean build folder: `cd ios && rm -rf build && cd ..`
2. Reinstall pods: `cd ios && pod deintegrate && pod install && cd ..`
3. Rebuild: `npx react-native run-ios`

### Android: SecurityException

**Error**: `Self-managed ConnectionServices cannot also be call capable`

**Solution**: Already fixed in v2.0.1+. Make sure you're using the latest version.

### Events not firing

**Check**:
1. Are you calling `setup()` before using other methods?
2. Are event listeners registered before triggering actions?
3. Check console for any error messages

```typescript
// ✅ Correct order
await CallKeeper.setup({ appName: 'MyApp' });
CallKeeper.addEventListener('answerCall', handler);
await CallKeeper.displayIncomingCall(...);

// ❌ Wrong order
await CallKeeper.displayIncomingCall(...); // setup not called!
```

## Expected Behavior

### iOS
- ✅ Full-screen native call UI
- ✅ Shows in system call history (if `includesCallsInRecents: true`)
- ✅ Audio session automatically managed
- ✅ Integrates with CarPlay

### Android
- ✅ Native call notification
- ✅ System call UI
- ✅ Bluetooth and speaker controls
- ✅ Self-managed connection service

## Test Checklist

- [ ] Module loads without errors
- [ ] `setup()` completes successfully
- [ ] Incoming call displays native UI
- [ ] `answerCall` event fires when answered
- [ ] `endCall` event fires when ended
- [ ] Outgoing calls work
- [ ] Mute/unmute works
- [ ] Hold/unhold works
- [ ] Multiple calls can be managed
- [ ] App works in background

## Getting Help

If the package still isn't working:

1. Check the version: `npm list react-native-call-keeper`
2. Check React Native version compatibility
3. Review the logs for error messages
4. Create an issue with:
   - RN version
   - iOS/Android version
   - Error logs
   - Steps to reproduce

## Version History

- **v2.0.3**: Fixed iOS event names compatibility
- **v2.0.2**: Fixed iOS crash with nil appName
- **v2.0.1**: Fixed Android SecurityException
- **v2.0.0**: Complete refactor with TurboModule support


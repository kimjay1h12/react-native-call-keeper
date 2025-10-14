# Quick Start Guide

Get up and running with `react-native-call-keeper` in 5 minutes!

## 📦 Installation

### For Expo Projects (Recommended)

```bash
npx expo install react-native-call-keeper
```

Add to your `app.json`:
```json
{
  "expo": {
    "plugins": ["react-native-call-keeper"]
  }
}
```

Build and run:
```bash
npx expo prebuild
npx expo run:ios  # or run:android
```

### For Bare React Native

```bash
npm install react-native-call-keeper
cd ios && pod install && cd ..
```

## 🚀 Basic Usage

### 1. Setup (Do this once on app start)

```typescript
import CallKeeper from 'react-native-call-keeper';
import { PermissionsAndroid, Platform } from 'react-native';

// Request permissions (Android only)
if (Platform.OS === 'android') {
  await PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
    PermissionsAndroid.PERMISSIONS.CALL_PHONE,
    PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
  ]);
}

// Setup CallKeeper
await CallKeeper.setup({
  appName: 'MyApp',
  supportsVideo: false,
});

// Add event listeners
CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
  console.log('Call answered:', callUUID);
  // Connect your VoIP call here
});

CallKeeper.addEventListener('endCall', ({ callUUID }) => {
  console.log('Call ended:', callUUID);
  // Disconnect your VoIP call here
});
```

### 2. Display Incoming Call

```typescript
import { v4 as uuidv4 } from 'uuid'; // npm install uuid

const callUUID = uuidv4();

await CallKeeper.displayIncomingCall(
  callUUID,
  '+1234567890',      // Phone number
  'John Doe',         // Caller name
  'number',           // Handle type
  false               // Has video
);
```

### 3. Start Outgoing Call

```typescript
const callUUID = uuidv4();

await CallKeeper.startCall(
  callUUID,
  '+1234567890',
  'Jane Smith',
  'number',
  false
);
```

### 4. End Call

```typescript
await CallKeeper.endCall(callUUID);
```

### 5. Call Controls

```typescript
// Mute
await CallKeeper.setMutedCall(callUUID, true);

// Hold
await CallKeeper.setOnHold(callUUID, true);

// Report connected (for outgoing calls)
await CallKeeper.reportConnectedOutgoingCall(callUUID);
```

## 📱 Complete Example Component

```typescript
import React, { useEffect, useState } from 'react';
import { View, Button, Alert } from 'react-native';
import CallKeeper from 'react-native-call-keeper';
import { v4 as uuidv4 } from 'uuid';

export default function CallScreen() {
  const [callUUID, setCallUUID] = useState<string | null>(null);

  useEffect(() => {
    // Setup
    setupCallKeeper();

    // Cleanup
    return () => CallKeeper.removeAllListeners();
  }, []);

  const setupCallKeeper = async () => {
    await CallKeeper.setup({ appName: 'MyApp' });

    CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
      Alert.alert('Call Answered', 'Start your VoIP session');
    });

    CallKeeper.addEventListener('endCall', ({ callUUID }) => {
      Alert.alert('Call Ended', 'Clean up your VoIP session');
      setCallUUID(null);
    });
  };

  const handleIncomingCall = async () => {
    const uuid = uuidv4();
    setCallUUID(uuid);
    
    await CallKeeper.displayIncomingCall(
      uuid,
      '+1234567890',
      'John Doe',
      'number',
      false
    );
  };

  const handleEndCall = async () => {
    if (callUUID) {
      await CallKeeper.endCall(callUUID);
      setCallUUID(null);
    }
  };

  return (
    <View style={{ padding: 20, gap: 10 }}>
      <Button title="Incoming Call" onPress={handleIncomingCall} />
      <Button 
        title="End Call" 
        onPress={handleEndCall}
        disabled={!callUUID}
      />
    </View>
  );
}
```

## 🎯 Key Events to Listen For

```typescript
// User answers call
CallKeeper.addEventListener('answerCall', (event) => {
  // Connect your VoIP session
});

// User ends call
CallKeeper.addEventListener('endCall', (event) => {
  // Disconnect your VoIP session
});

// User starts outgoing call
CallKeeper.addEventListener('didReceiveStartCallAction', (event) => {
  // Initiate your VoIP call
});

// User mutes/unmutes
CallKeeper.addEventListener('didPerformSetMutedCallAction', (event) => {
  // Handle mute state: event.muted
});

// User holds/resumes
CallKeeper.addEventListener('didToggleHoldAction', (event) => {
  // Handle hold state: event.hold
});
```

## 🔧 Common Use Cases

### Accept Incoming Call Programmatically
```typescript
await CallKeeper.answerIncomingCall(callUUID);
```

### Reject Incoming Call
```typescript
await CallKeeper.rejectCall(callUUID);
```

### End All Calls
```typescript
await CallKeeper.endAllCalls();
```

### Update Call Display
```typescript
await CallKeeper.updateDisplay(
  callUUID,
  'Updated Name',
  'updated-handle'
);
```

### Check Permissions
```typescript
const hasPermissions = await CallKeeper.checkPermissions();
```

### Check Active Calls
```typescript
const hasActiveCalls = await CallKeeper.checkIsInManagedCall();
```

## 📋 iOS Info.plist Requirements

Add these to `ios/YourApp/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>voip</string>
  <string>audio</string>
</array>
```

> **Note:** Expo config plugin adds these automatically!

## 🤖 Android Permissions

These are automatically added, but you must request them at runtime:

```typescript
import { PermissionsAndroid } from 'react-native';

const granted = await PermissionsAndroid.requestMultiple([
  PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
  PermissionsAndroid.PERMISSIONS.CALL_PHONE,
  PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
  PermissionsAndroid.PERMISSIONS.READ_CALL_LOG,
  PermissionsAndroid.PERMISSIONS.WRITE_CALL_LOG,
]);
```

## 🆕 New Architecture Support

This package fully supports React Native's New Architecture!

Enable it in your project:

**Android** (`android/gradle.properties`):
```properties
newArchEnabled=true
```

**iOS** (Podfile):
```ruby
ENV['RCT_NEW_ARCH_ENABLED'] = '1'
```

The package automatically adapts to the architecture in use.

## 💡 Tips

1. **Always generate unique UUIDs** for each call
2. **Clean up listeners** when components unmount
3. **Test on real devices** - simulators have limitations
4. **Request permissions early** - before making/receiving calls
5. **Handle all events** - especially answerCall and endCall
6. **Report call state changes** to keep UI in sync

## 📚 Next Steps

- Read the [full documentation](./README.md)
- Check out the [example app](./example/App.tsx)
- Review the [API reference](./README.md#api-reference)
- See [installation details](./INSTALLATION.md)

## ❓ Need Help?

- Check [existing issues](https://github.com/yourusername/react-native-call-keeper/issues)
- Read the [troubleshooting guide](./INSTALLATION.md#troubleshooting)
- Open a new issue if needed

## 🎉 You're Ready!

Start building your VoIP calling app with native call UI support!


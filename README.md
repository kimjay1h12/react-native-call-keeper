# react-native-call-keeper

A modern React Native module for handling VoIP calls with CallKit (iOS) and ConnectionService (Android) support. Built with the New Architecture (TurboModules) and fully compatible with Expo.

## Features

- ✅ **CallKit** integration for iOS
- ✅ **ConnectionService** integration for Android
- ✅ **New Architecture** (TurboModules) support
- ✅ **Expo** compatible with config plugin
- ✅ Full **TypeScript** support
- ✅ Display incoming call UI
- ✅ Start outgoing calls
- ✅ Answer/Reject calls
- ✅ Mute/Hold functionality
- ✅ DTMF support
- ✅ Video call support
- ✅ Event-driven architecture

## Installation

### For bare React Native projects:

```bash
npm install react-native-call-keeper
# or
yarn add react-native-call-keeper
```

For iOS, install pods:

```bash
cd ios && pod install
```

### For Expo projects:

```bash
npx expo install react-native-call-keeper
```

Add the plugin to your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "plugins": ["react-native-call-keeper"]
  }
}
```

Then rebuild your development client:

```bash
npx expo prebuild
npx expo run:ios
# or
npx expo run:android
```

## Platform-specific Setup

### iOS Setup

Add the following to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>voip</string>
  <string>audio</string>
</array>
```

> Note: If using the Expo config plugin, this is done automatically.

### Android Setup

The required permissions and service declarations are automatically added by the library. However, you need to request runtime permissions in your app:

```typescript
import { PermissionsAndroid, Platform } from 'react-native';

if (Platform.OS === 'android') {
  await PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
    PermissionsAndroid.PERMISSIONS.CALL_PHONE,
    PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
    PermissionsAndroid.PERMISSIONS.READ_CALL_LOG,
    PermissionsAndroid.PERMISSIONS.WRITE_CALL_LOG,
  ]);
}
```

## Usage

### Setup

First, initialize the module with your app configuration:

```typescript
import CallKeeper from 'react-native-call-keeper';

await CallKeeper.setup({
  appName: 'MyApp',
  imageName: 'logo', // iOS only: image name in your asset catalog
  ringtoneSound: 'ringtone.mp3', // iOS only
  includesCallsInRecents: true,
  supportsVideo: true,
  maximumCallGroups: 1,
  maximumCallsPerCallGroup: 1,
});
```

### Display Incoming Call

```typescript
import CallKeeper from 'react-native-call-keeper';

const callUUID = 'unique-call-id'; // Generate with uuid library

await CallKeeper.displayIncomingCall(
  callUUID,
  '+1234567890', // caller handle
  'John Doe', // caller name
  'number', // handleType: 'generic' | 'number' | 'email'
  false // hasVideo
);
```

### Start Outgoing Call

```typescript
await CallKeeper.startCall(
  callUUID,
  '+1234567890',
  'John Doe',
  'number',
  false
);
```

### Answer Call

```typescript
await CallKeeper.answerIncomingCall(callUUID);
```

### End Call

```typescript
await CallKeeper.endCall(callUUID);
```

### Mute/Unmute

```typescript
await CallKeeper.setMutedCall(callUUID, true); // mute
await CallKeeper.setMutedCall(callUUID, false); // unmute
```

### Hold/Unhold

```typescript
await CallKeeper.setOnHold(callUUID, true); // hold
await CallKeeper.setOnHold(callUUID, false); // unhold
```

### Report Call Status

```typescript
// Report outgoing call connected
await CallKeeper.reportConnectedOutgoingCall(callUUID);

// Report call ended with reason
// Reasons: 1=failed, 2=remote ended, 3=unanswered, 4=answered elsewhere, 5=declined elsewhere
await CallKeeper.reportEndCallWithUUID(callUUID, 2);
```

## Events

Listen to call events:

```typescript
import CallKeeper from 'react-native-call-keeper';

// Answer call event
CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
  console.log('Call answered:', callUUID);
  // Start your VoIP session here
});

// End call event
CallKeeper.addEventListener('endCall', ({ callUUID }) => {
  console.log('Call ended:', callUUID);
  // Clean up your VoIP session
});

// Start call event (outgoing)
CallKeeper.addEventListener('didReceiveStartCallAction', ({ callUUID, handle }) => {
  console.log('Starting call to:', handle);
  // Initiate your VoIP call
});

// Mute event
CallKeeper.addEventListener('didPerformSetMutedCallAction', ({ callUUID, muted }) => {
  console.log('Mute changed:', muted);
});

// Hold event
CallKeeper.addEventListener('didToggleHoldAction', ({ callUUID, hold }) => {
  console.log('Hold changed:', hold);
});

// Audio session activated (iOS)
CallKeeper.addEventListener('didActivateAudioSession', () => {
  console.log('Audio session activated');
});

// DTMF event
CallKeeper.addEventListener('didPerformDTMFAction', ({ callUUID, digits }) => {
  console.log('DTMF digits:', digits);
});
```

### Cleanup

Remember to remove event listeners when your component unmounts:

```typescript
// Remove specific listener
CallKeeper.removeEventListener('answerCall');

// Remove all listeners
CallKeeper.removeAllListeners();
```

## Complete Example

```typescript
import React, { useEffect } from 'react';
import { View, Button } from 'react-native';
import CallKeeper from 'react-native-call-keeper';
import { v4 as uuidv4 } from 'uuid';

function App() {
  const [callUUID, setCallUUID] = React.useState<string | null>(null);

  useEffect(() => {
    // Setup CallKeeper
    CallKeeper.setup({
      appName: 'MyApp',
      supportsVideo: false,
      includesCallsInRecents: true,
    });

    // Setup event listeners
    CallKeeper.addEventListener('answerCall', handleAnswerCall);
    CallKeeper.addEventListener('endCall', handleEndCall);
    CallKeeper.addEventListener('didReceiveStartCallAction', handleStartCall);

    return () => {
      CallKeeper.removeAllListeners();
    };
  }, []);

  const handleAnswerCall = ({ callUUID }: { callUUID: string }) => {
    console.log('User answered call:', callUUID);
    // Connect your VoIP session
  };

  const handleEndCall = ({ callUUID }: { callUUID: string }) => {
    console.log('Call ended:', callUUID);
    setCallUUID(null);
    // Disconnect your VoIP session
  };

  const handleStartCall = ({ callUUID, handle }: { callUUID: string; handle: string }) => {
    console.log('Starting call to:', handle);
    // Initiate your VoIP connection
  };

  const displayIncomingCall = async () => {
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

  const startOutgoingCall = async () => {
    const uuid = uuidv4();
    setCallUUID(uuid);
    
    await CallKeeper.startCall(
      uuid,
      '+1234567890',
      'John Doe',
      'number',
      false
    );
  };

  const endCurrentCall = async () => {
    if (callUUID) {
      await CallKeeper.endCall(callUUID);
      setCallUUID(null);
    }
  };

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
      <Button title="Display Incoming Call" onPress={displayIncomingCall} />
      <Button title="Start Outgoing Call" onPress={startOutgoingCall} />
      <Button title="End Call" onPress={endCurrentCall} disabled={!callUUID} />
    </View>
  );
}

export default App;
```

## API Reference

### Methods

#### `setup(options: CallKeeperOptions): Promise<void>`

Initialize the CallKeeper module.

**Options:**
- `appName` (string, required): Your app name
- `imageName` (string, optional): iOS only - icon name from asset catalog
- `ringtoneSound` (string, optional): iOS only - ringtone filename
- `includesCallsInRecents` (boolean, optional): Add calls to recents
- `supportsVideo` (boolean, optional): Enable video call support
- `maximumCallGroups` (number, optional): Max concurrent call groups
- `maximumCallsPerCallGroup` (number, optional): Max calls per group

#### `displayIncomingCall(callUUID, handle, localizedCallerName?, handleType?, hasVideo?): Promise<void>`

Display an incoming call notification.

#### `startCall(callUUID, handle, contactIdentifier?, handleType?, hasVideo?): Promise<void>`

Start an outgoing call.

#### `endCall(callUUID): Promise<void>`

End a specific call.

#### `endAllCalls(): Promise<void>`

End all active calls.

#### `answerIncomingCall(callUUID): Promise<void>`

Answer an incoming call programmatically.

#### `rejectCall(callUUID): Promise<void>`

Reject an incoming call.

#### `setMutedCall(callUUID, muted): Promise<void>`

Set mute status for a call.

#### `setOnHold(callUUID, onHold): Promise<void>`

Put a call on hold or resume.

#### `reportConnectedOutgoingCall(callUUID): Promise<void>`

Report that an outgoing call has connected.

#### `reportEndCallWithUUID(callUUID, reason): Promise<void>`

Report that a call has ended with a specific reason.

#### `updateDisplay(callUUID, displayName, handle): Promise<void>`

Update the display information for an active call.

#### `checkPermissions(): Promise<boolean>`

Check if the app has necessary permissions.

#### `checkIsInManagedCall(): Promise<boolean>`

Check if there's an active managed call.

#### `backToForeground(): Promise<void>`

Bring the app to foreground.

### Events

- `didReceiveStartCallAction` - Outgoing call started
- `answerCall` - Incoming call answered
- `endCall` - Call ended
- `didActivateAudioSession` - Audio session activated (iOS)
- `didDisplayIncomingCall` - Incoming call displayed
- `didPerformSetMutedCallAction` - Mute status changed
- `didToggleHoldAction` - Hold status changed
- `didPerformDTMFAction` - DTMF tone played
- `didResetProvider` - Provider reset (iOS)

## New Architecture Support

This library is built with full support for React Native's New Architecture (TurboModules). The module will automatically use the new architecture if your app has it enabled.

### Enable New Architecture

For React Native 0.70+, set in your `android/gradle.properties`:
```properties
newArchEnabled=true
```

And in your Podfile:
```ruby
ENV['RCT_NEW_ARCH_ENABLED'] = '1'
```

## Troubleshooting

### iOS: Calls not showing up

Make sure you have added the required background modes to your Info.plist and have configured VoIP push notifications properly.

### Android: Missing permissions

Request runtime permissions before using the module. Check the Android Setup section for required permissions.

### Expo: Module not found

Make sure you have run `npx expo prebuild` after installing the package and adding the plugin to your app.json.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

MIT

## Credits

Built with ❤️ for the React Native community

# react-native-call-keeper

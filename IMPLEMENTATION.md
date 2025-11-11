# Expo Call Keep - Complete Implementation Guide

> Comprehensive guide for implementing VoIP calling with native UI integration in React Native and Expo projects.

## 📦 Package Information

- **Package Name:** `expo-call-keep`
- **Version:** 1.0.0
- **Built With:** Kotlin (Android) & Swift (iOS)
- **Architecture:** New Architecture (TurboModules) & Old Architecture compatible
- **Platforms:** iOS 13.0+, Android 6.0+ (API 23+)
- **NPM:** https://www.npmjs.com/package/expo-call-keep

---

## 🚀 Quick Start

### Installation

#### For Expo Projects:

**Step 1: Install the package**

```bash
npx expo install expo-call-keep
```

**Step 2: Add the config plugin**

Add the plugin to your `app.json` or `app.config.js`:

**Using `app.json`:**

```json
{
  "expo": {
    "plugins": ["expo-call-keep"]
  }
}
```

**Using `app.config.js`:**

```javascript
export default {
  expo: {
    plugins: ['expo-call-keep'],
  },
};
```

**What the config plugin does:**

- ✅ Automatically adds iOS background modes (audio, voip) to Info.plist
- ✅ Automatically adds Android permissions to AndroidManifest.xml
- ✅ Registers the ConnectionService for Android
- ✅ Configures CallKit for iOS

**Step 3: Rebuild your development client**

After adding the plugin, you must rebuild your native code:

```bash
# For development builds
npx expo prebuild --clean

# Or if using EAS Build
eas build --profile development --platform ios
eas build --profile development --platform android
```

**Important Notes:**

- The config plugin runs automatically during `expo prebuild` or EAS Build
- You only need to add the plugin once - it persists in your config
- If you're using Expo Go, this package requires a **development build** (Expo Go doesn't support custom native code)

#### For Bare React Native:

```bash
npm install expo-call-keep
# or
yarn add expo-call-keep
```

For iOS:

```bash
cd ios && pod install && cd ..
```

---

## ⚙️ Configuration

### Expo Configuration (Automatic)

The Expo config plugin (`expo-call-keep`) automatically configures both iOS and Android when you add it to your `app.json` or `app.config.js`. No manual configuration is needed for Expo projects!

**What gets configured automatically:**

**iOS:**

- ✅ Background modes: `audio` and `voip` added to Info.plist
- ✅ CallKit framework integration
- ✅ Info.plist updates

**Android:**

- ✅ Required permissions added to AndroidManifest.xml:
  - `BIND_TELECOM_CONNECTION_SERVICE`
  - `FOREGROUND_SERVICE`
  - `READ_PHONE_STATE`
  - `CALL_PHONE`
  - `RECORD_AUDIO`
  - `WAKE_LOCK`
  - `READ_CALL_LOG`
  - `WRITE_CALL_LOG`
  - `MANAGE_OWN_CALLS`
- ✅ ConnectionService registration

**Verifying the configuration:**

After running `npx expo prebuild`, you can verify:

**iOS:** Check `ios/YourApp/Info.plist` for:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
</array>
```

**Android:** Check `android/app/src/main/AndroidManifest.xml` for the permissions listed above.

### Manual Configuration (Bare React Native Only)

If you're using bare React Native (not Expo), you need to configure manually:

#### iOS Configuration

**Manual Setup:**

1. Enable Background Modes in Xcode:
   - Open `ios/YourApp.xcworkspace`
   - Select target → Signing & Capabilities
   - Add "Background Modes"
   - Enable "Audio, AirPlay, and Picture in Picture" + "Voice over IP"

2. Verify Info.plist contains:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
</array>
```

#### Android Configuration

**Manual Setup (Bare React Native only):**

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BIND_TELECOM_CONNECTION_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**Request Runtime Permissions:**

```typescript
import { PermissionsAndroid, Platform } from 'react-native';

async function requestPermissions() {
  if (Platform.OS === 'android') {
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
        PermissionsAndroid.PERMISSIONS.CALL_PHONE,
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
      ]);

      const allGranted = Object.values(granted).every(
        (result) => result === PermissionsAndroid.RESULTS.GRANTED
      );

      if (!allGranted) {
        console.warn('⚠️ Some permissions were denied');
        return false;
      }

      return true;
    } catch (err) {
      console.error('❌ Permission request error:', err);
      return false;
    }
  }
  return true; // iOS doesn't need runtime permissions for CallKit
}
```

---

## 💻 Step-by-Step Implementation

### Step 1: Initialize CallKeeper

Create a hook or utility to initialize CallKeeper on app start:

```typescript
import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import CallKeeper from 'expo-call-keep';
import { requestPermissions } from './permissions'; // Your permission helper

export function useCallKeeperSetup() {
  const [isReady, setIsReady] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    initializeCallKeeper();
  }, []);

  async function initializeCallKeeper() {
    try {
      // Step 1: Request Android permissions first
      if (Platform.OS === 'android') {
        const hasPermissions = await requestPermissions();
        if (!hasPermissions) {
          throw new Error('Required permissions were denied');
        }
      }

      // Step 2: Setup CallKeeper
      await CallKeeper.setup({
        appName: 'MyVoIPApp', // Required: Display name in call UI
        supportsVideo: true, // Optional: Enable video calls
        includesCallsInRecents: true, // Optional: Show in call history
        maximumCallGroups: 1, // Optional: Max call groups
        maximumCallsPerCallGroup: 1, // Optional: Max calls per group
        imageName: 'call_icon', // Optional: Custom icon name
        ringtoneSound: 'ringtone.mp3', // Optional: Custom ringtone
      });

      setIsReady(true);
      console.log('✅ CallKeeper initialized successfully');
    } catch (err: any) {
      const errorMessage = err?.message || 'Failed to initialize CallKeeper';
      setError(errorMessage);
      console.error('❌ CallKeeper setup failed:', errorMessage);
    }
  }

  return { isReady, error, retry: initializeCallKeeper };
}
```

### Step 2: Setup Event Listeners

Create a hook to handle all CallKeeper events:

```typescript
import { useEffect } from 'react';
import CallKeeper from 'expo-call-keep';

export function useCallKeeperEvents() {
  useEffect(() => {
    // User answered the call
    CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
      console.log('📞 Call answered:', callUUID);
      // TODO: Connect your VoIP audio/video here
      // Example: connectVoIPCall(callUUID);
      CallKeeper.setCurrentCallActive(callUUID);
    });

    // User ended the call
    CallKeeper.addEventListener('endCall', ({ callUUID }) => {
      console.log('📵 Call ended:', callUUID);
      // TODO: Disconnect your VoIP connection here
      // Example: disconnectVoIPCall(callUUID);
    });

    // User started outgoing call from native UI
    CallKeeper.addEventListener(
      'didReceiveStartCallAction',
      ({ callUUID, handle }) => {
        console.log('📱 Starting call to:', handle);
        // TODO: Initiate your VoIP connection here
        // Example: startVoIPCall(callUUID, handle);
      }
    );

    // Audio session activated (ready for audio)
    CallKeeper.addEventListener('didActivateAudioSession', () => {
      console.log('🔊 Audio session ready');
      // TODO: Configure your audio session here
      // Example: configureAudioSession();
    });

    // Incoming call was displayed
    CallKeeper.addEventListener('didDisplayIncomingCall', ({ callUUID }) => {
      console.log('📲 Incoming call displayed:', callUUID);
    });

    // User toggled mute
    CallKeeper.addEventListener(
      'didPerformSetMutedCallAction',
      ({ callUUID, muted }) => {
        console.log(`🔇 Call ${muted ? 'muted' : 'unmuted'}:`, callUUID);
        // TODO: Update your VoIP mute state
        // Example: setVoIPMute(callUUID, muted);
      }
    );

    // User toggled hold
    CallKeeper.addEventListener('didToggleHoldAction', ({ callUUID, hold }) => {
      console.log(`⏸️ Call ${hold ? 'on hold' : 'resumed'}:`, callUUID);
      // TODO: Update your VoIP hold state
      // Example: setVoIPHold(callUUID, hold);
    });

    // User pressed DTMF key
    CallKeeper.addEventListener(
      'didPerformDTMFAction',
      ({ callUUID, digits }) => {
        console.log('🔢 DTMF pressed:', digits, 'for call:', callUUID);
        // TODO: Send DTMF to your VoIP server
        // Example: sendDTMF(callUUID, digits);
      }
    );

    // Provider was reset (iOS only)
    CallKeeper.addEventListener('didResetProvider', () => {
      console.log('🔄 CallKit provider reset');
      // TODO: Clean up any active calls
      // Example: cleanupAllCalls();
    });

    // Cleanup on unmount
    return () => {
      CallKeeper.removeAllListeners();
    };
  }, []);
}
```

### Step 3: Display Incoming Call

When you receive an incoming call notification from your VoIP server:

```typescript
import { v4 as uuidv4 } from 'uuid'; // npm install uuid @types/uuid
import CallKeeper from 'expo-call-keep';

interface IncomingCallData {
  callerId: string;
  callerName?: string;
  hasVideo?: boolean;
}

async function handleIncomingCall(data: IncomingCallData) {
  const callUUID = uuidv4(); // Generate unique ID for this call

  try {
    await CallKeeper.displayIncomingCall(
      callUUID, // Unique call identifier
      data.callerId, // Phone number or handle
      data.callerName || 'Unknown', // Display name
      'number', // Handle type: 'number' | 'email' | 'generic'
      data.hasVideo || false // Video call flag
    );

    console.log('✅ Incoming call displayed:', callUUID);

    // Store callUUID for later reference
    // Example: storeActiveCall(callUUID, data);

    return callUUID;
  } catch (error) {
    console.error('❌ Failed to display incoming call:', error);
    return null;
  }
}

// Usage example:
// When your VoIP server sends push notification:
handleIncomingCall({
  callerId: '+1234567890',
  callerName: 'John Doe',
  hasVideo: false,
});
```

### Step 4: Start Outgoing Call

When user initiates a call from your app:

```typescript
import { v4 as uuidv4 } from 'uuid';
import CallKeeper from 'expo-call-keep';

interface OutgoingCallData {
  recipientId: string;
  recipientName?: string;
  hasVideo?: boolean;
}

async function startOutgoingCall(data: OutgoingCallData) {
  const callUUID = uuidv4();

  try {
    // Step 1: Show native call UI
    await CallKeeper.startCall(
      callUUID,
      data.recipientId,
      data.recipientName || data.recipientId,
      'number',
      data.hasVideo || false
    );

    console.log('✅ Outgoing call started:', callUUID);

    // Step 2: Initiate your VoIP connection
    // Example: await initiateVoIPCall(callUUID, data.recipientId);

    // Step 3: When call connects, report it
    // This should be called when your VoIP connection is established
    setTimeout(async () => {
      try {
        await CallKeeper.reportConnectedOutgoingCall(callUUID);
        console.log('✅ Call connected');
      } catch (error) {
        console.error('❌ Failed to report connected call:', error);
      }
    }, 2000); // Replace with actual connection callback

    return callUUID;
  } catch (error) {
    console.error('❌ Failed to start outgoing call:', error);
    return null;
  }
}

// Usage example:
startOutgoingCall({
  recipientId: '+0987654321',
  recipientName: 'Jane Smith',
  hasVideo: false,
});
```

### Step 5: Handle Call Actions

```typescript
import CallKeeper from 'expo-call-keep';

// Answer a call
async function answerCall(callUUID: string) {
  try {
    await CallKeeper.answerIncomingCall(callUUID);
    await CallKeeper.setCurrentCallActive(callUUID);
    console.log('✅ Call answered');
  } catch (error) {
    console.error('❌ Failed to answer call:', error);
  }
}

// Reject a call
async function rejectCall(callUUID: string) {
  try {
    await CallKeeper.rejectCall(callUUID);
    await CallKeeper.reportEndCallWithUUID(callUUID, 5); // 5 = declined
    console.log('✅ Call rejected');
  } catch (error) {
    console.error('❌ Failed to reject call:', error);
  }
}

// End a call
async function endCall(callUUID: string) {
  try {
    await CallKeeper.endCall(callUUID);
    await CallKeeper.reportEndCallWithUUID(callUUID, 3); // 3 = local ended
    console.log('✅ Call ended');
  } catch (error) {
    console.error('❌ Failed to end call:', error);
  }
}

// Mute/Unmute
async function toggleMute(callUUID: string, muted: boolean) {
  try {
    await CallKeeper.setMutedCall(callUUID, muted);
    console.log(`✅ Call ${muted ? 'muted' : 'unmuted'}`);
  } catch (error) {
    console.error('❌ Failed to toggle mute:', error);
  }
}

// Hold/Resume
async function toggleHold(callUUID: string, onHold: boolean) {
  try {
    await CallKeeper.setOnHold(callUUID, onHold);
    console.log(`✅ Call ${onHold ? 'on hold' : 'resumed'}`);
  } catch (error) {
    console.error('❌ Failed to toggle hold:', error);
  }
}

// Update call display info
async function updateCallInfo(
  callUUID: string,
  displayName: string,
  handle: string
) {
  try {
    await CallKeeper.updateDisplay(callUUID, displayName, handle);
    console.log('✅ Call info updated');
  } catch (error) {
    console.error('❌ Failed to update call info:', error);
  }
}
```

---

## 📚 Complete Example: Full-Featured Call Screen

```typescript
import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  Button,
  StyleSheet,
  Alert,
  Platform,
} from 'react-native';
import CallKeeper from 'expo-call-keep';
import { v4 as uuidv4 } from 'uuid';
import { useCallKeeperSetup, useCallKeeperEvents } from './hooks/callKeeper';

interface CallState {
  callUUID: string | null;
  isConnected: boolean;
  isMuted: boolean;
  isOnHold: boolean;
  callerName: string;
  callerNumber: string;
}

export default function CallScreen() {
  const { isReady, error: setupError } = useCallKeeperSetup();
  useCallKeeperEvents();

  const [callState, setCallState] = useState<CallState>({
    callUUID: null,
    isConnected: false,
    isMuted: false,
    isOnHold: false,
    callerName: '',
    callerNumber: '',
  });

  // Setup event listeners
  useEffect(() => {
    if (!isReady) return;

    const answerListener = CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
      setCallState(prev => ({ ...prev, callUUID, isConnected: true }));
      CallKeeper.setCurrentCallActive(callUUID);
    });

    const endListener = CallKeeper.addEventListener('endCall', ({ callUUID }) => {
      if (callUUID === callState.callUUID) {
        setCallState({
          callUUID: null,
          isConnected: false,
          isMuted: false,
          isOnHold: false,
          callerName: '',
          callerNumber: '',
        });
      }
    });

    const muteListener = CallKeeper.addEventListener(
      'didPerformSetMutedCallAction',
      ({ callUUID, muted }) => {
        if (callUUID === callState.callUUID) {
          setCallState(prev => ({ ...prev, isMuted: muted }));
        }
      }
    );

    const holdListener = CallKeeper.addEventListener(
      'didToggleHoldAction',
      ({ callUUID, hold }) => {
        if (callUUID === callState.callUUID) {
          setCallState(prev => ({ ...prev, isOnHold: hold }));
        }
      }
    );

    return () => {
      answerListener.remove();
      endListener.remove();
      muteListener.remove();
      holdListener.remove();
    };
  }, [isReady, callState.callUUID]);

  async function handleIncomingCall() {
    if (!isReady) {
      Alert.alert('Error', 'CallKeeper not ready');
      return;
    }

    const callUUID = uuidv4();
    const callerNumber = '+1234567890';
    const callerName = 'John Doe';

    try {
      await CallKeeper.displayIncomingCall(
        callUUID,
        callerNumber,
        callerName,
        'number',
        false
      );

      setCallState({
        callUUID,
        isConnected: false,
        isMuted: false,
        isOnHold: false,
        callerName,
        callerNumber,
      });
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to display call');
    }
  }

  async function handleOutgoingCall() {
    if (!isReady) {
      Alert.alert('Error', 'CallKeeper not ready');
      return;
    }

    const callUUID = uuidv4();
    const recipientNumber = '+0987654321';
    const recipientName = 'Jane Smith';

    try {
      await CallKeeper.startCall(
        callUUID,
        recipientNumber,
        recipientName,
        'number',
        false
      );

      setCallState({
        callUUID,
        isConnected: false,
        isMuted: false,
        isOnHold: false,
        callerName: recipientName,
        callerNumber: recipientNumber,
      });

      // Simulate connection
      setTimeout(async () => {
        await CallKeeper.reportConnectedOutgoingCall(callUUID);
        setCallState(prev => ({ ...prev, isConnected: true }));
      }, 2000);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to start call');
    }
  }

  async function handleEndCall() {
    if (!callState.callUUID) return;

    try {
      await CallKeeper.endCall(callState.callUUID);
      await CallKeeper.reportEndCallWithUUID(callState.callUUID, 3);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to end call');
    }
  }

  async function handleToggleMute() {
    if (!callState.callUUID) return;

    try {
      const newMuted = !callState.isMuted;
      await CallKeeper.setMutedCall(callState.callUUID, newMuted);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to toggle mute');
    }
  }

  async function handleToggleHold() {
    if (!callState.callUUID) return;

    try {
      const newHold = !callState.isOnHold;
      await CallKeeper.setOnHold(callState.callUUID, newHold);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to toggle hold');
    }
  }

  if (setupError) {
    return (
      <View style={styles.container}>
        <Text style={styles.error}>Setup Error: {setupError}</Text>
        <Button title="Retry" onPress={() => window.location.reload()} />
      </View>
    );
  }

  if (!isReady) {
    return (
      <View style={styles.container}>
        <Text>Initializing CallKeeper...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>CallKeeper Demo</Text>

      {callState.callUUID && (
        <View style={styles.callInfo}>
          <Text style={styles.callerName}>{callState.callerName}</Text>
          <Text style={styles.callerNumber}>{callState.callerNumber}</Text>
          <Text style={styles.status}>
            {callState.isConnected ? 'Connected' : 'Connecting...'}
          </Text>
        </View>
      )}

      <View style={styles.buttonGroup}>
        <Button
          title="📞 Incoming Call"
          onPress={handleIncomingCall}
          disabled={!!callState.callUUID}
        />
        <Button
          title="📱 Outgoing Call"
          onPress={handleOutgoingCall}
          disabled={!!callState.callUUID}
        />
      </View>

      {callState.callUUID && (
        <View style={styles.buttonGroup}>
          <Button
            title={callState.isMuted ? '🔇 Unmute' : '🔊 Mute'}
            onPress={handleToggleMute}
          />
          <Button
            title={callState.isOnHold ? '▶️ Resume' : '⏸️ Hold'}
            onPress={handleToggleHold}
          />
          <Button title="❌ End Call" onPress={handleEndCall} />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 30,
    textAlign: 'center',
  },
  callInfo: {
    alignItems: 'center',
    marginBottom: 30,
    padding: 20,
    backgroundColor: '#f5f5f5',
    borderRadius: 10,
  },
  callerName: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  callerNumber: {
    fontSize: 16,
    color: '#666',
    marginBottom: 10,
  },
  status: {
    fontSize: 14,
    color: '#999',
  },
  buttonGroup: {
    marginVertical: 10,
    gap: 10,
  },
  error: {
    color: 'red',
    textAlign: 'center',
    marginBottom: 20,
  },
});
```

---

## 🎯 Complete API Reference

### Setup Options

```typescript
interface CallKeeperOptions {
  appName: string; // Required: Display name in call UI
  imageName?: string; // Optional: Custom icon name
  ringtoneSound?: string; // Optional: Custom ringtone file name
  includesCallsInRecents?: boolean; // Optional: Show in call history (default: false)
  supportsVideo?: boolean; // Optional: Enable video calls (default: false)
  maximumCallGroups?: number; // Optional: Max call groups (default: 1)
  maximumCallsPerCallGroup?: number; // Optional: Max calls per group (default: 1)
}
```

### Methods

| Method                          | Description                | Parameters                                       | Returns            |
| ------------------------------- | -------------------------- | ------------------------------------------------ | ------------------ |
| `setup(options)`                | Initialize CallKeeper      | `CallKeeperOptions`                              | `Promise<void>`    |
| `displayIncomingCall()`         | Show incoming call UI      | `callUUID, handle, name?, type?, hasVideo?`      | `Promise<void>`    |
| `startCall()`                   | Start outgoing call        | `callUUID, handle, contactId?, type?, hasVideo?` | `Promise<void>`    |
| `endCall()`                     | End specific call          | `callUUID: string`                               | `Promise<void>`    |
| `endAllCalls()`                 | End all active calls       | -                                                | `Promise<void>`    |
| `answerIncomingCall()`          | Answer a call              | `callUUID: string`                               | `Promise<void>`    |
| `rejectCall()`                  | Reject a call              | `callUUID: string`                               | `Promise<void>`    |
| `setMutedCall()`                | Mute/unmute                | `callUUID: string, muted: boolean`               | `Promise<void>`    |
| `setOnHold()`                   | Hold/resume                | `callUUID: string, onHold: boolean`              | `Promise<void>`    |
| `reportConnectedOutgoingCall()` | Report call connected      | `callUUID: string`                               | `Promise<void>`    |
| `reportEndCallWithUUID()`       | Report call ended          | `callUUID: string, reason: number`               | `Promise<void>`    |
| `updateDisplay()`               | Update call info           | `callUUID, displayName, handle`                  | `Promise<void>`    |
| `checkPermissions()`            | Check permissions          | -                                                | `Promise<boolean>` |
| `checkIsInManagedCall()`        | Check if in call           | -                                                | `Promise<boolean>` |
| `setAvailable()`                | Set availability (Android) | `available: boolean`                             | `Promise<void>`    |
| `setCurrentCallActive()`        | Set call active            | `callUUID: string`                               | `Promise<void>`    |
| `backToForeground()`            | Bring app to front         | -                                                | `Promise<void>`    |

### Events

| Event                          | When Fired                 | Event Data                             |
| ------------------------------ | -------------------------- | -------------------------------------- |
| `answerCall`                   | User answered call         | `{ callUUID: string }`                 |
| `endCall`                      | User ended call            | `{ callUUID: string }`                 |
| `didReceiveStartCallAction`    | User started outgoing call | `{ callUUID: string, handle: string }` |
| `didActivateAudioSession`      | Audio session ready        | `{}`                                   |
| `didDisplayIncomingCall`       | Incoming call shown        | `{ callUUID: string }`                 |
| `didPerformSetMutedCallAction` | Mute toggled               | `{ callUUID: string, muted: boolean }` |
| `didToggleHoldAction`          | Hold toggled               | `{ callUUID: string, hold: boolean }`  |
| `didPerformDTMFAction`         | DTMF key pressed           | `{ callUUID: string, digits: string }` |
| `didResetProvider`             | Provider reset (iOS)       | `{}`                                   |

### End Call Reason Codes

| Code | Reason             | Description                     |
| ---- | ------------------ | ------------------------------- |
| 1    | Failed             | Call failed to connect          |
| 2    | Remote ended       | Remote party ended the call     |
| 3    | Local ended        | Local user ended the call       |
| 4    | Answered elsewhere | Call answered on another device |
| 5    | Declined elsewhere | Call declined on another device |
| 6    | Missed             | Call was missed (not answered)  |

### Handle Types

| Type        | Description        | Example              |
| ----------- | ------------------ | -------------------- |
| `'number'`  | Phone number       | `'+1234567890'`      |
| `'email'`   | Email address      | `'user@example.com'` |
| `'generic'` | Generic identifier | `'user123'`          |

---

## 🔧 Advanced Usage

### Integrating with VoIP SDK

```typescript
import CallKeeper from 'expo-call-keep';
import { YourVoIPSDK } from 'your-voip-sdk';

// Initialize VoIP SDK
const voipSDK = new YourVoIPSDK();

// Setup CallKeeper
await CallKeeper.setup({ appName: 'MyApp' });

// When VoIP SDK receives incoming call
voipSDK.onIncomingCall((call) => {
  const callUUID = uuidv4();

  // Display native call UI
  CallKeeper.displayIncomingCall(
    callUUID,
    call.callerId,
    call.callerName,
    'number',
    call.hasVideo
  );

  // Store mapping
  callMapping.set(callUUID, call);
});

// When user answers
CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
  const voipCall = callMapping.get(callUUID);
  if (voipCall) {
    voipSDK.answerCall(voipCall.id);
    CallKeeper.setCurrentCallActive(callUUID);
  }
});

// When user ends call
CallKeeper.addEventListener('endCall', ({ callUUID }) => {
  const voipCall = callMapping.get(callUUID);
  if (voipCall) {
    voipSDK.endCall(voipCall.id);
    callMapping.delete(callUUID);
  }
});
```

### Handling Push Notifications

```typescript
import * as Notifications from 'expo-notifications';
import CallKeeper from 'expo-call-keep';

// Setup push notification handler
Notifications.setNotificationHandler({
  handleNotification: async (notification) => {
    const { data } = notification.request.content;

    if (data.type === 'incoming_call') {
      // Display native call UI instead of notification
      await CallKeeper.displayIncomingCall(
        data.callUUID,
        data.callerId,
        data.callerName,
        'number',
        data.hasVideo || false
      );

      return {
        shouldShowAlert: false, // Don't show notification
        shouldPlaySound: false, // CallKit handles sound
        shouldSetBadge: false,
      };
    }

    return {
      shouldShowAlert: true,
      shouldPlaySound: true,
      shouldSetBadge: true,
    };
  },
});
```

### Managing Multiple Calls

```typescript
import CallKeeper from 'expo-call-keep';

class CallManager {
  private activeCalls = new Map<string, CallInfo>();

  async addCall(callUUID: string, info: CallInfo) {
    this.activeCalls.set(callUUID, info);
  }

  async removeCall(callUUID: string) {
    this.activeCalls.delete(callUUID);
  }

  getActiveCall(): CallInfo | null {
    if (this.activeCalls.size === 0) return null;
    return Array.from(this.activeCalls.values())[0];
  }

  async endAllCalls() {
    await CallKeeper.endAllCalls();
    this.activeCalls.clear();
  }
}
```

---

## 🔧 Troubleshooting

### Module not found

```bash
# Clean and rebuild
cd ios && rm -rf build && pod deintegrate && pod install && cd ..
npx react-native run-ios

# For Android
cd android && ./gradlew clean && cd ..
npx react-native run-android
```

### Events not firing

- ✅ Ensure `setup()` is called before any other methods
- ✅ Register event listeners BEFORE triggering actions
- ✅ Check console for errors
- ✅ Verify native module is linked correctly

### Android permissions

- ✅ Verify all permissions in AndroidManifest.xml
- ✅ Request runtime permissions before using CallKeeper
- ✅ Check `checkPermissions()` result
- ✅ Ensure `BIND_TELECOM_CONNECTION_SERVICE` is declared

### iOS crash on init

- ✅ Ensure `appName` is provided in setup options
- ✅ Verify background modes are enabled
- ✅ Check Xcode console for errors
- ✅ Ensure CallKit framework is linked

### Call not showing

- ✅ Verify `displayIncomingCall()` is called with valid UUID
- ✅ Check that setup was successful
- ✅ Ensure app has proper permissions
- ✅ Verify background modes are enabled (iOS)

### Audio not working

- ✅ Call `setCurrentCallActive()` after answering
- ✅ Listen for `didActivateAudioSession` event
- ✅ Configure audio session in your VoIP SDK
- ✅ Check microphone permissions

---

## ✅ Implementation Checklist

### Setup

- [ ] Package installed (`expo-call-keep`)
- [ ] iOS pods installed (if bare React Native)
- [ ] Expo plugin added to app.json (if Expo)
- [ ] iOS background modes enabled
- [ ] Android permissions added to AndroidManifest.xml
- [ ] Runtime permissions requested (Android)

### Code

- [ ] `setup()` called on app start
- [ ] Event listeners registered
- [ ] UUID library installed (`uuid`)
- [ ] Call state management implemented
- [ ] Error handling added

### Testing

- [ ] Tested incoming call display
- [ ] Tested outgoing call start
- [ ] Tested answer/end events
- [ ] Tested mute/hold functionality
- [ ] Tested on both iOS and Android
- [ ] VoIP connection integrated
- [ ] Audio working correctly

---

## 📞 Support & Resources

- **Package:** expo-call-keep
- **Version:** 1.0.0
- **NPM:** https://www.npmjs.com/package/expo-call-keep
- **Repository:** https://github.com/kimjay1h12/expo-call-keep
- **Issues:** https://github.com/kimjay1h12/expo-call-keep/issues

---

## 📝 License

MIT License - See LICENSE file for details

---

**Built with ❤️ using Kotlin and Swift**

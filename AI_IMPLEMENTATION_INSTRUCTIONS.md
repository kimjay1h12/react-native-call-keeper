# AI Assistant Instructions for Implementing react-native-call-keeper

> Copy this entire file and share it with an AI assistant to implement CallKeeper in your React Native project.

---

## Task: Implement VoIP Calling with Native UI

Implement the `react-native-call-keeper@2.1.1` package to enable native VoIP calling with system UI integration for both iOS and Android.

---

## Instructions

### 1. Install Package

```bash
npm install react-native-call-keeper@2.1.1 --save
cd ios && pod install && cd ..
```

### 2. iOS Configuration

Add to `ios/[ProjectName]/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

### 3. Android Configuration  

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BIND_TELECOM_CONNECTION_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
```

### 4. Create CallKeeper Service

Create a new file `src/services/CallKeeperService.ts`:

```typescript
import { Platform, PermissionsAndroid } from 'react-native';
import CallKeeper from 'react-native-call-keeper';
import { v4 as uuidv4 } from 'uuid'; // Install: npm install uuid

class CallKeeperService {
  private static instance: CallKeeperService;
  private currentCallId: string | null = null;

  static getInstance(): CallKeeperService {
    if (!CallKeeperService.instance) {
      CallKeeperService.instance = new CallKeeperService();
    }
    return CallKeeperService.instance;
  }

  async initialize() {
    try {
      // Request Android permissions
      if (Platform.OS === 'android') {
        await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
          PermissionsAndroid.PERMISSIONS.CALL_PHONE,
        ]);
      }

      // Setup CallKeeper
      await CallKeeper.setup({
        appName: 'MyApp', // Change to your app name
        supportsVideo: true,
        includesCallsInRecents: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      });

      this.setupEventListeners();
      console.log('✅ CallKeeper initialized');
    } catch (error) {
      console.error('❌ CallKeeper setup failed:', error);
    }
  }

  private setupEventListeners() {
    // User answered the call
    CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
      console.log('📞 Call answered:', callUUID);
      this.currentCallId = callUUID;
      
      // TODO: Connect your VoIP audio/video here
      CallKeeper.setCurrentCallActive(callUUID);
    });

    // User ended the call
    CallKeeper.addEventListener('endCall', ({ callUUID }) => {
      console.log('📵 Call ended:', callUUID);
      this.currentCallId = null;
      
      // TODO: Disconnect your VoIP connection here
    });

    // User started outgoing call
    CallKeeper.addEventListener('didReceiveStartCallAction', ({ callUUID, handle }) => {
      console.log('📱 Starting call to:', handle);
      this.currentCallId = callUUID;
      
      // TODO: Initiate your VoIP connection here
    });

    // Mute toggled
    CallKeeper.addEventListener('didPerformSetMutedCallAction', ({ callUUID, muted }) => {
      console.log(`🔇 Call ${muted ? 'muted' : 'unmuted'}`);
      
      // TODO: Update your VoIP mute state
    });

    // Hold toggled
    CallKeeper.addEventListener('didToggleHoldAction', ({ callUUID, hold }) => {
      console.log(`⏸️ Call ${hold ? 'on hold' : 'resumed'}`);
      
      // TODO: Update your VoIP hold state
    });
  }

  async showIncomingCall(callerName: string, callerNumber: string): Promise<string> {
    const callUUID = uuidv4();
    
    await CallKeeper.displayIncomingCall(
      callUUID,
      callerNumber,
      callerName,
      'number',
      false // Set to true for video calls
    );

    this.currentCallId = callUUID;
    return callUUID;
  }

  async startOutgoingCall(recipientName: string, recipientNumber: string): Promise<string> {
    const callUUID = uuidv4();
    
    await CallKeeper.startCall(
      callUUID,
      recipientNumber,
      recipientName,
      'number',
      false
    );

    this.currentCallId = callUUID;

    // Simulate connection after 2 seconds
    setTimeout(async () => {
      await CallKeeper.reportConnectedOutgoingCall(callUUID);
    }, 2000);

    return callUUID;
  }

  async endCurrentCall() {
    if (!this.currentCallId) return;

    await CallKeeper.endCall(this.currentCallId);
    await CallKeeper.reportEndCallWithUUID(this.currentCallId, 3); // 3 = local ended
    this.currentCallId = null;
  }

  async muteCall(muted: boolean) {
    if (!this.currentCallId) return;
    await CallKeeper.setMutedCall(this.currentCallId, muted);
  }

  async holdCall(hold: boolean) {
    if (!this.currentCallId) return;
    await CallKeeper.setOnHold(this.currentCallId, hold);
  }

  getCurrentCallId(): string | null {
    return this.currentCallId;
  }

  cleanup() {
    CallKeeper.removeAllListeners();
  }
}

export default CallKeeperService.getInstance();
```

### 5. Initialize in App.tsx

```typescript
import { useEffect } from 'react';
import CallKeeperService from './services/CallKeeperService';

function App() {
  useEffect(() => {
    // Initialize CallKeeper
    CallKeeperService.initialize();

    // Cleanup on unmount
    return () => {
      CallKeeperService.cleanup();
    };
  }, []);

  return (
    // Your app components
  );
}
```

### 6. Usage Example

Create a component to test calls:

```typescript
import React from 'react';
import { View, Button, Alert } from 'react-native';
import CallKeeperService from '../services/CallKeeperService';

export default function CallScreen() {
  async function handleIncomingCall() {
    try {
      const callId = await CallKeeperService.showIncomingCall(
        'John Doe',
        '+1234567890'
      );
      console.log('Incoming call displayed:', callId);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  async function handleOutgoingCall() {
    try {
      const callId = await CallKeeperService.startOutgoingCall(
        'Jane Smith',
        '+0987654321'
      );
      console.log('Outgoing call started:', callId);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  async function handleEndCall() {
    try {
      await CallKeeperService.endCurrentCall();
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  async function handleMute() {
    try {
      await CallKeeperService.muteCall(true);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  return (
    <View style={{ padding: 20, gap: 10 }}>
      <Button title="📞 Incoming Call" onPress={handleIncomingCall} />
      <Button title="📱 Outgoing Call" onPress={handleOutgoingCall} />
      <Button title="❌ End Call" onPress={handleEndCall} />
      <Button title="🔇 Mute" onPress={handleMute} />
    </View>
  );
}
```

---

## Important Notes

1. **Install uuid package**: `npm install uuid @types/uuid`

2. **iOS Background Modes**: Must enable in Xcode:
   - Open `ios/[Project].xcworkspace`
   - Select target → Signing & Capabilities
   - Add "Background Modes"
   - Enable "Audio, AirPlay, and Picture in Picture" + "Voice over IP"

3. **Android Permissions**: Request at runtime (already handled in CallKeeperService)

4. **Event Flow**:
   - Incoming: `displayIncomingCall()` → user answers → `answerCall` event → connect VoIP
   - Outgoing: `startCall()` → `didReceiveStartCallAction` event → connect VoIP → `reportConnectedOutgoingCall()`
   - End: `endCall()` → `endCall` event → disconnect VoIP

5. **Integration**: Replace TODO comments with your actual VoIP connection logic (WebRTC, SIP, etc.)

---

## Verification Checklist

- [ ] Package installed successfully
- [ ] iOS pods installed
- [ ] iOS background modes configured
- [ ] Android permissions added to manifest
- [ ] CallKeeperService created
- [ ] Service initialized in App.tsx
- [ ] Test incoming call - native UI appears ✅
- [ ] Test answering call - event fires ✅
- [ ] Test ending call - event fires ✅
- [ ] Test outgoing call - works ✅
- [ ] No console errors ✅

---

## Troubleshooting

**Module not found:**
```bash
cd ios && rm -rf build && pod deintegrate && pod install && cd ..
npx react-native run-ios
```

**Events not firing:**
- Ensure `initialize()` is called before any call actions
- Check event listeners are registered before triggering calls

**Android crash:**
- Verify all permissions are in AndroidManifest.xml
- Check permissions are granted at runtime

---

## Success Criteria

After implementation, you should have:
1. ✅ Native incoming call UI (full screen on iOS, notification on Android)
2. ✅ Native outgoing call UI
3. ✅ System call controls (mute, hold, end)
4. ✅ Event callbacks firing correctly
5. ✅ No errors in console

The package is fully functional on both iOS and Android as of v2.1.1.

---

**Package Version:** 2.1.1  
**Status:** Production Ready  
**Platform Support:** iOS 10+, Android 6.0+ (API 23+)


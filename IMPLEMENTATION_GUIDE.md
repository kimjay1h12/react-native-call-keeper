# React Native Call Keeper - Complete Implementation Guide

> **Version: 2.1.0** - A complete guide for AI assistants and developers to implement VoIP calling with native UI integration for both iOS and Android.

---

## 📋 Table of Contents
1. [Installation](#installation)
2. [iOS Configuration](#ios-configuration)
3. [Android Configuration](#android-configuration)
4. [Basic Implementation](#basic-implementation)
5. [Event Handling](#event-handling)
6. [Complete Example](#complete-example)
7. [Troubleshooting](#troubleshooting)

---

## 🚀 Installation

### Step 1: Install the Package

```bash
npm install react-native-call-keeper@2.1.0 --save
```

Or with yarn:

```bash
yarn add react-native-call-keeper@2.1.0
```

### Step 2: iOS Pod Installation

```bash
cd ios && pod install && cd ..
```

### Step 3: Rebuild the App

```bash
# iOS
npx react-native run-ios

# Android
npx react-native run-android
```

---

## 📱 iOS Configuration

### 1. Update Info.plist

Add these keys to `ios/YourApp/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

### 2. Enable Background Modes in Xcode

1. Open `ios/YourApp.xcworkspace` in Xcode
2. Select your app target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" → "Background Modes"
5. Enable:
   - ✅ Audio, AirPlay, and Picture in Picture
   - ✅ Voice over IP

### 3. (Optional) Add to AppDelegate for Push Notifications

If you need PushKit for VoIP push notifications, add to `AppDelegate.mm`:

```objc
#import <PushKit/PushKit.h>
#import <RNCallKeep.h>

// Add this method
- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
  restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler
{
  return [RNCallKeep application:application
            continueUserActivity:userActivity
              restorationHandler:restorationHandler];
}
```

---

## 🤖 Android Configuration

### 1. Update AndroidManifest.xml

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.BIND_TELECOM_CONNECTION_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    
    <application>
        <!-- Your app configuration -->
    </application>
</manifest>
```

### 2. Request Runtime Permissions

Add to your main app component:

```typescript
import { PermissionsAndroid, Platform } from 'react-native';

async function requestAndroidPermissions() {
  if (Platform.OS === 'android') {
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
        PermissionsAndroid.PERMISSIONS.CALL_PHONE,
      ]);
      
      const allGranted = Object.values(granted).every(
        result => result === PermissionsAndroid.RESULTS.GRANTED
      );
      
      return allGranted;
    } catch (err) {
      console.warn('Permission error:', err);
      return false;
    }
  }
  return true;
}

// Call this before using CallKeeper
await requestAndroidPermissions();
```

---

## 💻 Basic Implementation

### Step 1: Setup CallKeeper

Call this once when your app starts (e.g., in App.tsx):

```typescript
import CallKeeper from 'react-native-call-keeper';

async function setupCallKeeper() {
  try {
    await CallKeeper.setup({
      appName: 'MyApp',                    // Your app name
      supportsVideo: true,                 // Enable video calls
      includesCallsInRecents: true,        // iOS: Show in call history
      maximumCallGroups: 1,                // iOS: Max call groups
      maximumCallsPerCallGroup: 1,         // iOS: Max calls per group
    });
    
    console.log('✅ CallKeeper setup successful');
  } catch (error) {
    console.error('❌ CallKeeper setup failed:', error);
  }
}

// Call this in your app initialization
useEffect(() => {
  setupCallKeeper();
}, []);
```

### Step 2: Display an Incoming Call

```typescript
import { v4 as uuidv4 } from 'uuid'; // npm install uuid

async function showIncomingCall(callerName: string, callerNumber: string) {
  const callUUID = uuidv4(); // Generate unique ID
  
  try {
    await CallKeeper.displayIncomingCall(
      callUUID,           // Unique call ID
      callerNumber,       // Phone number or handle
      callerName,         // Display name
      'number',           // 'number' | 'email' | 'generic'
      false               // hasVideo: true for video calls
    );
    
    console.log('✅ Incoming call displayed:', callUUID);
    return callUUID;
  } catch (error) {
    console.error('❌ Failed to display incoming call:', error);
    return null;
  }
}

// Usage
const callId = await showIncomingCall('John Doe', '+1234567890');
```

### Step 3: Start an Outgoing Call

```typescript
async function startOutgoingCall(recipientName: string, recipientNumber: string) {
  const callUUID = uuidv4();
  
  try {
    await CallKeeper.startCall(
      callUUID,           // Unique call ID
      recipientNumber,    // Phone number or handle
      recipientName,      // Contact identifier
      'number',           // Handle type
      false               // hasVideo
    );
    
    // Simulate connection after 2 seconds
    setTimeout(async () => {
      await CallKeeper.reportConnectedOutgoingCall(callUUID);
      console.log('✅ Call connected');
    }, 2000);
    
    return callUUID;
  } catch (error) {
    console.error('❌ Failed to start call:', error);
    return null;
  }
}

// Usage
const callId = await startOutgoingCall('Jane Smith', '+0987654321');
```

### Step 4: End a Call

```typescript
async function endCall(callUUID: string) {
  try {
    await CallKeeper.endCall(callUUID);
    
    // Report the call ended with reason code
    await CallKeeper.reportEndCallWithUUID(
      callUUID,
      3  // Reason: 1=failed, 2=remote ended, 3=local ended, 4=answered elsewhere, 5=declined elsewhere, 6=missed
    );
    
    console.log('✅ Call ended:', callUUID);
  } catch (error) {
    console.error('❌ Failed to end call:', error);
  }
}

// Usage
await endCall(callId);
```

---

## 🎧 Event Handling

### Setup Event Listeners

Add these listeners in your main component:

```typescript
import { useEffect } from 'react';
import CallKeeper from 'react-native-call-keeper';

function useCallKeeperEvents() {
  useEffect(() => {
    // User answered the call
    CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
      console.log('📞 User answered call:', callUUID);
      
      // Start your VoIP connection here
      // e.g., connect to WebRTC, SIP, etc.
      CallKeeper.setCurrentCallActive(callUUID);
    });

    // User ended the call
    CallKeeper.addEventListener('endCall', ({ callUUID }) => {
      console.log('📵 User ended call:', callUUID);
      
      // Clean up your VoIP connection here
      // End WebRTC session, disconnect SIP, etc.
    });

    // User started an outgoing call
    CallKeeper.addEventListener('didReceiveStartCallAction', ({ callUUID, handle }) => {
      console.log('📱 Starting outgoing call to:', handle);
      
      // Initiate your VoIP connection here
    });

    // Audio session activated (iOS)
    CallKeeper.addEventListener('didActivateAudioSession', () => {
      console.log('🔊 Audio session activated');
      
      // You can now start audio playback/recording
    });

    // Call displayed successfully
    CallKeeper.addEventListener('didDisplayIncomingCall', ({ callUUID }) => {
      console.log('✅ Incoming call displayed:', callUUID);
    });

    // User muted/unmuted
    CallKeeper.addEventListener('didPerformSetMutedCallAction', ({ callUUID, muted }) => {
      console.log(`🔇 Call ${muted ? 'muted' : 'unmuted'}:`, callUUID);
      
      // Update your VoIP mute state
    });

    // User held/resumed call
    CallKeeper.addEventListener('didToggleHoldAction', ({ callUUID, hold }) => {
      console.log(`⏸️ Call ${hold ? 'on hold' : 'resumed'}:`, callUUID);
      
      // Update your VoIP hold state
    });

    // DTMF tones
    CallKeeper.addEventListener('didPerformDTMFAction', ({ callUUID, digits }) => {
      console.log('🔢 DTMF digit pressed:', digits);
    });

    // Provider reset (iOS) - rare, but handle it
    CallKeeper.addEventListener('didResetProvider', () => {
      console.log('🔄 Provider reset - end all calls');
      
      // End all active calls
      CallKeeper.endAllCalls();
    });

    // Cleanup on unmount
    return () => {
      CallKeeper.removeAllListeners();
    };
  }, []);
}

// Use in your component
function App() {
  useCallKeeperEvents();
  
  return (
    // Your app UI
  );
}
```

---

## 📦 Complete Example

Here's a complete working example:

```typescript
import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  Button,
  StyleSheet,
  Alert,
  PermissionsAndroid,
  Platform,
} from 'react-native';
import CallKeeper from 'react-native-call-keeper';
import { v4 as uuidv4 } from 'uuid';

export default function CallKeeperExample() {
  const [currentCallId, setCurrentCallId] = useState<string | null>(null);
  const [isSetup, setIsSetup] = useState(false);

  useEffect(() => {
    initializeCallKeeper();
    setupEventListeners();

    return () => {
      CallKeeper.removeAllListeners();
    };
  }, []);

  async function initializeCallKeeper() {
    try {
      // Request Android permissions
      if (Platform.OS === 'android') {
        const granted = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.READ_PHONE_STATE,
          PermissionsAndroid.PERMISSIONS.CALL_PHONE,
        ]);
        
        const allGranted = Object.values(granted).every(
          result => result === PermissionsAndroid.RESULTS.GRANTED
        );
        
        if (!allGranted) {
          Alert.alert('Permissions Required', 'Please grant phone permissions');
          return;
        }
      }

      // Setup CallKeeper
      await CallKeeper.setup({
        appName: 'MyVoIPApp',
        supportsVideo: true,
        includesCallsInRecents: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      });

      setIsSetup(true);
      console.log('✅ CallKeeper initialized');
    } catch (error) {
      console.error('❌ CallKeeper setup failed:', error);
      Alert.alert('Setup Failed', error.message);
    }
  }

  function setupEventListeners() {
    CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
      console.log('📞 Answered:', callUUID);
      setCurrentCallId(callUUID);
      
      // TODO: Connect your VoIP audio/video here
      CallKeeper.setCurrentCallActive(callUUID);
    });

    CallKeeper.addEventListener('endCall', ({ callUUID }) => {
      console.log('📵 Ended:', callUUID);
      setCurrentCallId(null);
      
      // TODO: Disconnect your VoIP connection here
    });

    CallKeeper.addEventListener('didReceiveStartCallAction', ({ callUUID, handle }) => {
      console.log('📱 Starting call to:', handle);
      setCurrentCallId(callUUID);
      
      // TODO: Initiate your VoIP call here
    });

    CallKeeper.addEventListener('didPerformSetMutedCallAction', ({ muted }) => {
      console.log('🔇 Muted:', muted);
      
      // TODO: Update your VoIP mute state
    });
  }

  async function handleIncomingCall() {
    const callUUID = uuidv4();
    
    try {
      await CallKeeper.displayIncomingCall(
        callUUID,
        '+1234567890',
        'John Doe',
        'number',
        false
      );
      
      setCurrentCallId(callUUID);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  async function handleOutgoingCall() {
    const callUUID = uuidv4();
    
    try {
      await CallKeeper.startCall(
        callUUID,
        '+0987654321',
        'Jane Smith',
        'number',
        false
      );
      
      setCurrentCallId(callUUID);

      // Simulate connection
      setTimeout(async () => {
        await CallKeeper.reportConnectedOutgoingCall(callUUID);
      }, 2000);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  async function handleEndCall() {
    if (!currentCallId) {
      Alert.alert('No Active Call');
      return;
    }

    try {
      await CallKeeper.endCall(currentCallId);
      await CallKeeper.reportEndCallWithUUID(currentCallId, 3);
      setCurrentCallId(null);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  async function handleMuteCall() {
    if (!currentCallId) {
      Alert.alert('No Active Call');
      return;
    }

    try {
      await CallKeeper.setMutedCall(currentCallId, true);
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>CallKeeper Example</Text>
      
      <Text style={styles.status}>
        Status: {isSetup ? '✅ Ready' : '⏳ Setting up...'}
      </Text>
      
      {currentCallId && (
        <Text style={styles.callId}>
          Active Call: {currentCallId.substring(0, 8)}...
        </Text>
      )}

      <View style={styles.buttonContainer}>
        <Button title="📞 Incoming Call" onPress={handleIncomingCall} />
        <Button title="📱 Outgoing Call" onPress={handleOutgoingCall} />
        <Button title="❌ End Call" onPress={handleEndCall} />
        <Button title="🔇 Mute Call" onPress={handleMuteCall} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  status: {
    fontSize: 16,
    marginBottom: 10,
    textAlign: 'center',
  },
  callId: {
    fontSize: 14,
    color: '#007AFF',
    marginBottom: 20,
    textAlign: 'center',
  },
  buttonContainer: {
    gap: 10,
  },
});
```

---

## 🔧 Troubleshooting

### Issue: Module not found error

**Error:** `'CallKeeper' could not be found`

**Solution:**
```bash
# Clean and rebuild
cd ios && rm -rf build && pod deintegrate && pod install && cd ..
npx react-native run-ios

# For Android
cd android && ./gradlew clean && cd ..
npx react-native run-android
```

### Issue: Events not firing

**Problem:** Event listeners not receiving events

**Solution:**
1. Make sure `setup()` is called before any other methods
2. Register event listeners BEFORE triggering actions
3. Check console for errors

```typescript
// ✅ Correct order
await CallKeeper.setup({ appName: 'MyApp' });
CallKeeper.addEventListener('answerCall', handler);
await CallKeeper.displayIncomingCall(...);
```

### Issue: Android SecurityException

**Error:** `Self-managed ConnectionServices cannot also be call capable`

**Solution:** Update to v2.0.1+ (already fixed in 2.1.0)

### Issue: iOS crash on initialization

**Error:** App crashes when CallKit initializes

**Solution:** Update to v2.0.2+ (already fixed in 2.1.0)

### Issue: No native UI appears

**Checklist:**
- ✅ Called `setup()` successfully?
- ✅ Permissions granted on Android?
- ✅ Background modes enabled on iOS?
- ✅ Using correct method parameters?

**Debug:**
```typescript
// Check if module is loaded
import { NativeModules } from 'react-native';
console.log('CallKeeper module:', NativeModules.CallKeeper);

// Check setup
const hasPermissions = await CallKeeper.checkPermissions();
console.log('Has permissions:', hasPermissions);
```

---

## 📚 API Reference

### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `setup(options)` | Initialize CallKeeper | `{ appName, supportsVideo?, ... }` |
| `displayIncomingCall()` | Show incoming call UI | `callUUID, handle, name?, type?, hasVideo?` |
| `startCall()` | Start outgoing call | `callUUID, handle, contactId?, type?, hasVideo?` |
| `answerIncomingCall()` | Answer a call | `callUUID` |
| `endCall()` | End specific call | `callUUID` |
| `endAllCalls()` | End all calls | - |
| `rejectCall()` | Reject a call | `callUUID` |
| `setMutedCall()` | Mute/unmute | `callUUID, muted` |
| `setOnHold()` | Hold/resume | `callUUID, onHold` |
| `reportConnectedOutgoingCall()` | Report call connected | `callUUID` |
| `reportEndCallWithUUID()` | Report call ended | `callUUID, reason` |
| `updateDisplay()` | Update call info | `callUUID, displayName, handle` |
| `checkPermissions()` | Check permissions | - |
| `checkIsInManagedCall()` | Check if in call | - |
| `setCurrentCallActive()` | Set call active | `callUUID` |
| `backToForeground()` | Bring app to front | - |

### Events

| Event | When Fired | Data |
|-------|------------|------|
| `answerCall` | User answered call | `{ callUUID }` |
| `endCall` | User ended call | `{ callUUID }` |
| `didReceiveStartCallAction` | User started outgoing call | `{ callUUID, handle }` |
| `didActivateAudioSession` | Audio session ready (iOS) | - |
| `didDisplayIncomingCall` | Incoming call shown | `{ callUUID }` |
| `didPerformSetMutedCallAction` | Mute toggled | `{ callUUID, muted }` |
| `didToggleHoldAction` | Hold toggled | `{ callUUID, hold }` |
| `didPerformDTMFAction` | DTMF key pressed | `{ callUUID, digits }` |
| `didResetProvider` | Provider reset (iOS) | - |

### End Call Reason Codes

| Code | Reason |
|------|--------|
| 1 | Failed |
| 2 | Remote ended |
| 3 | Local ended |
| 4 | Answered elsewhere |
| 5 | Declined elsewhere |
| 6 | Missed |

---

## ✅ Implementation Checklist

Use this checklist to ensure proper implementation:

- [ ] Package installed (`npm install react-native-call-keeper@2.1.0`)
- [ ] iOS pods installed (`cd ios && pod install`)
- [ ] iOS Info.plist updated with background modes
- [ ] iOS background modes enabled in Xcode
- [ ] Android manifest updated with permissions
- [ ] Android runtime permissions requested
- [ ] `setup()` called on app start
- [ ] Event listeners registered
- [ ] UUID library installed for generating call IDs
- [ ] Tested incoming call display
- [ ] Tested outgoing call start
- [ ] Tested answer/end call events
- [ ] Tested mute/hold functionality
- [ ] Error handling implemented
- [ ] VoIP connection integrated with events

---

## 🎯 Quick Start Template

Copy this to get started quickly:

```typescript
import { useEffect } from 'react';
import CallKeeper from 'react-native-call-keeper';
import { v4 as uuidv4 } from 'uuid';

// 1. Setup
async function init() {
  await CallKeeper.setup({ appName: 'MyApp', supportsVideo: true });
}

// 2. Events
function setupEvents() {
  CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
    // Connect VoIP
    CallKeeper.setCurrentCallActive(callUUID);
  });
  
  CallKeeper.addEventListener('endCall', ({ callUUID }) => {
    // Disconnect VoIP
  });
}

// 3. Usage
async function incomingCall() {
  const id = uuidv4();
  await CallKeeper.displayIncomingCall(id, '+1234567890', 'John', 'number', false);
}

async function outgoingCall() {
  const id = uuidv4();
  await CallKeeper.startCall(id, '+1234567890', 'John', 'number', false);
  setTimeout(() => CallKeeper.reportConnectedOutgoingCall(id), 2000);
}

async function endCall(callId: string) {
  await CallKeeper.endCall(callId);
  await CallKeeper.reportEndCallWithUUID(callId, 3);
}

// In component
useEffect(() => {
  init();
  setupEvents();
  return () => CallKeeper.removeAllListeners();
}, []);
```

---

## 📞 Support

- **Package Version:** 2.1.0
- **Min iOS:** 10.0
- **Min Android:** 6.0 (API 23)
- **React Native:** 0.60+

For issues, check:
1. This implementation guide
2. `TESTING_GUIDE.md` for debugging
3. `PLATFORM_STATUS.md` for platform details

---

**Last Updated:** v2.1.0  
**Status:** ✅ Production Ready - Both iOS and Android fully functional


# Platform Implementation Guide - expo-call-keep

> Complete implementation guide for iOS and Android platforms with New Architecture support

## 📦 Package Information

- **Package Name:** `expo-call-keep`
- **Current Version:** 1.0.3
- **Platforms:** iOS 13.0+, Android 6.0+ (API 23+)
- **Languages:** Swift (iOS), Kotlin (Android)
- **Architecture:** Both Old and New Architecture (TurboModules) supported
- **NPM:** https://www.npmjs.com/package/expo-call-keep

---

## 🏗️ Project Structure Overview

```
expo-call-keep/
├── src/                          # TypeScript source
│   ├── NativeCallKeeper.ts     # TurboModule spec
│   └── index.tsx                # Main export
│
├── ios/                         # iOS native code
│   └── RNCallKeep/
│       ├── RNCallKeep.h         # Objective-C header
│       ├── RNCallKeep.m         # Objective-C implementation
│       └── RNCallKeep.swift     # Swift implementation
│
├── android/                     # Android native code
│   └── src/
│       ├── main/kotlin/         # Shared code
│       │   ├── CallKeeperPackage.kt
│       │   └── VoiceConnectionService.kt
│       ├── oldarch/kotlin/      # Old Architecture
│       │   └── CallKeeperModule.kt
│       └── newarch/kotlin/      # New Architecture
│           └── CallKeeperModule.kt
│
└── app.plugin.js               # Expo config plugin
```

---

## 📱 iOS Implementation

### Architecture

iOS uses **CallKit** framework for native call UI integration.

#### File Structure

```
ios/RNCallKeep/
├── RNCallKeep.h                 # Objective-C header (bridging)
├── RNCallKeep.m                 # Objective-C implementation (1,452 lines)
└── RNCallKeep.swift             # Swift implementation (796 lines)
```

### Key Components

#### 1. Module Registration

**Objective-C (`RNCallKeep.m`):**
```objc
RCT_EXPORT_MODULE(CallKeeper)
```

**Swift (`RNCallKeep.swift`):**
```swift
@objc(CallKeeper)
class RNCallKeep: RCTEventEmitter, CXProviderDelegate {
    // Implementation
}
```

#### 2. CallKit Provider Setup

```swift
private func initCallKitProvider() {
    guard let settings = self.settings,
          let appName = settings["appName"] as? String,
          !appName.isEmpty else {
        // Fallback to bundle name
        let fallbackName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
        self.appName = fallbackName
        return
    }
    
    self.appName = appName
    let configuration = getProviderConfiguration()
    sharedProvider = CXProvider(configuration: configuration)
    sharedProvider?.setDelegate(self, queue: nil)
}
```

#### 3. Display Incoming Call

```swift
@objc func displayIncomingCall(
    _ callUUID: String,
    handle: String,
    localizedCallerName: String?,
    handleType: String?,
    hasVideo: NSNumber?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
) {
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: getHandleType(handleType), value: handle)
    update.localizedCallerName = localizedCallerName ?? handle
    update.hasVideo = hasVideo?.boolValue ?? false
    
    provider.reportNewIncomingCall(with: UUID(uuidString: callUUID)!, update: update) { error in
        if let error = error {
            reject("INCOMING_CALL_ERROR", error.localizedDescription, error)
        } else {
            self.sendEvent(withName: "didDisplayIncomingCall", body: ["callUUID": callUUID])
            resolve(nil)
        }
    }
}
```

#### 4. Event Emission

iOS emits events through `RCTEventEmitter`:

```swift
override func supportedEvents() -> [String]! {
    return [
        "answerCall",
        "endCall",
        "didReceiveStartCallAction",
        "didActivateAudioSession",
        "didDisplayIncomingCall",
        "didPerformSetMutedCallAction",
        "didToggleHoldAction",
        "didPerformDTMFAction",
        "didResetProvider",
        // Legacy names for backward compatibility
        "RNCallKeepPerformAnswerCallAction",
        "RNCallKeepPerformEndCallAction",
        // ... more events
    ]
}

private func sendEvent(withName name: String, body: [String: Any]?) {
    sendEvent(withName: name, body: body)
}
```

#### 5. CallKit Delegate Methods

```swift
func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    action.fulfill()
    sendEvent(withName: "answerCall", body: ["callUUID": action.callUUID.uuidString])
}

func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    action.fulfill()
    sendEvent(withName: "endCall", body: ["callUUID": action.callUUID.uuidString])
}

func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
    action.fulfill()
    sendEvent(withName: "didPerformSetMutedCallAction", body: [
        "callUUID": action.callUUID.uuidString,
        "muted": action.isMuted
    ])
}
```

### iOS Configuration

#### Info.plist Requirements

The Expo config plugin automatically adds:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

#### Capabilities

Required capabilities (handled by Expo plugin):
- **Background Modes:**
  - Audio, AirPlay, and Picture in Picture
  - Voice over IP

#### Podspec Configuration

```ruby
Pod::Spec.new do |s|
  s.name         = "expo-call-keep"
  s.version      = "1.0.3"
  s.source_files = "ios/RNCallKeep/**/*.{h,m,swift}"
  s.dependency "React-Core"
  s.frameworks = "CallKit", "AVFoundation"
end
```

### iOS-Specific Features

1. **CallKit Integration**
   - Native incoming call UI
   - Lock screen integration
   - Call history
   - CarPlay support

2. **Audio Session Management**
   - Automatic audio routing
   - Bluetooth support
   - Speaker/earpiece switching

3. **Background Execution**
   - VoIP push notifications
   - Background audio
   - Call state persistence

---

## 🤖 Android Implementation

### Architecture

Android uses **ConnectionService** API for native call UI integration.

#### File Structure

```
android/src/
├── main/kotlin/com/callkeeper/
│   ├── CallKeeperPackage.kt          # Package registration
│   └── VoiceConnectionService.kt     # ConnectionService
│
├── oldarch/kotlin/com/callkeeper/    # Old Architecture
│   ├── CallKeeperModule.kt
│   └── CallKeeperSpec.kt
│
└── newarch/kotlin/com/callkeeper/    # New Architecture
    ├── CallKeeperModule.kt
    └── CallKeeperSpec.kt
```

### Key Components

#### 1. Module Registration

**Old Architecture:**
```kotlin
class CallKeeperModule(reactContext: ReactApplicationContext) : CallKeeperSpec(reactContext) {
    override fun getName(): String = "CallKeeper"
}
```

**New Architecture:**
```kotlin
class CallKeeperModule(reactContext: ReactApplicationContext) : CallKeeperSpec(reactContext) {
    // Extends NativeCallKeeperSpec (auto-generated from TypeScript)
}
```

#### 2. Package Registration

```kotlin
class CallKeeperPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        return try {
            listOf(CallKeeperModule(reactContext)) // Old arch
        } catch (e: Exception) {
            emptyList() // New arch - auto-registered
        }
    }
}
```

#### 3. Setup & PhoneAccount Registration

```kotlin
override fun setup(options: ReadableMap, promise: Promise) {
    try {
        settings = options
        val appName = options.getString("appName") ?: "App"
        
        // Set ReactContext for event sending
        VoiceConnectionService.setReactContext(reactApplicationContext)
        
        // Register PhoneAccount
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val componentName = android.content.ComponentName(context, VoiceConnectionService::class.java)
        phoneAccountHandle = PhoneAccountHandle(componentName, appName)

        val phoneAccount = PhoneAccount.builder(phoneAccountHandle!!, appName)
            .setCapabilities(PhoneAccount.CAPABILITY_SELF_MANAGED)
            .setShortDescription(appName)
            .build()

        telecomManager.registerPhoneAccount(phoneAccount)
        promise.resolve(null)
    } catch (e: Exception) {
        promise.reject("SETUP_ERROR", "Failed to setup CallKeeper: ${e.message}", e)
    }
}
```

#### 4. Display Incoming Call

```kotlin
override fun displayIncomingCall(
    callUUID: String,
    handle: String,
    localizedCallerName: String?,
    handleType: String?,
    hasVideo: Boolean?,
    promise: Promise
) {
    try {
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val phoneAccountHandle = this.phoneAccountHandle
            ?: throw IllegalStateException("CallKeeper not initialized. Call setup() first.")

        val extras = Bundle().apply {
            putString("callUUID", callUUID)
            putString("handle", handle)
            putString("localizedCallerName", localizedCallerName ?: handle)
            putBoolean("hasVideo", hasVideo ?: false)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            telecomManager.addNewIncomingCall(phoneAccountHandle, extras)
        }

        val params = Arguments.createMap().apply {
            putString("callUUID", callUUID)
        }
        sendEvent("didDisplayIncomingCall", params)
        promise.resolve(null)
    } catch (e: Exception) {
        promise.reject("INCOMING_CALL_ERROR", "Failed to display incoming call: ${e.message}", e)
    }
}
```

#### 5. ConnectionService Implementation

```kotlin
class VoiceConnectionService : ConnectionService() {
    companion object {
        private val activeConnections = ConcurrentHashMap<String, VoiceConnection>()
        private var reactContext: ReactApplicationContext? = null

        fun setReactContext(context: ReactApplicationContext?) {
            reactContext = context
        }

        private fun sendEvent(eventName: String, params: WritableMap?) {
            reactContext?.let { context ->
                context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                    .emit(eventName, params)
            }
        }
    }

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        val extras = request?.extras ?: Bundle()
        val callUUID = extras.getString("callUUID") ?: return Connection.createFailedConnection(
            DisconnectCause(DisconnectCause.ERROR)
        )

        val connection = VoiceConnection(callUUID)
        connection.setInitializing()
        activeConnections[callUUID] = connection
        return connection
    }

    private inner class VoiceConnection(private val callUUID: String) : Connection() {
        override fun onAnswer() {
            super.onAnswer()
            setActive()
            activate()
            sendEvent("answerCall", Arguments.createMap().apply {
                putString("callUUID", callUUID)
            })
        }

        override fun onReject() {
            super.onReject()
            setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
            sendEvent("endCall", Arguments.createMap().apply {
                putString("callUUID", callUUID)
            })
            activeConnections.remove(callUUID)
        }

        override fun onDisconnect() {
            super.onDisconnect()
            setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            sendEvent("endCall", Arguments.createMap().apply {
                putString("callUUID", callUUID)
            })
            activeConnections.remove(callUUID)
            destroy()
        }
    }
}
```

#### 6. Event Emission

```kotlin
private fun sendEvent(eventName: String, params: WritableMap?) {
    reactApplicationContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        .emit(eventName, params)
}
```

### Android Configuration

#### AndroidManifest.xml Requirements

The Expo config plugin automatically adds:

```xml
<uses-permission android:name="android.permission.BIND_TELECOM_CONNECTION_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.READ_CALL_LOG"/>
<uses-permission android:name="android.permission.WRITE_CALL_LOG"/>
<uses-permission android:name="android.permission.MANAGE_OWN_CALLS"/>

<service
    android:name="com.callkeeper.VoiceConnectionService"
    android:permission="android.permission.BIND_TELECOM_CONNECTION_SERVICE">
    <intent-filter>
        <action android:name="android.telecom.ConnectionService" />
    </intent-filter>
</service>
```

#### Build Configuration

```gradle
android {
    compileSdkVersion 33
    minSdkVersion 21
    targetSdkVersion 33
    
    sourceSets {
        main {
            kotlin.srcDirs += ["src/main/kotlin"]
            if (isNewArchitectureEnabled()) {
                kotlin.srcDirs += ["src/newarch/kotlin"]
            } else {
                kotlin.srcDirs += ["src/oldarch/kotlin"]
            }
        }
    }
}
```

### Android-Specific Features

1. **ConnectionService Integration**
   - Self-managed connections (API 26+)
   - Native call UI (heads-up notification)
   - Call controls from notification

2. **PhoneAccount Management**
   - VoIP account registration
   - Call routing
   - Multiple account support

3. **Audio Management**
   - Audio routing (speaker, Bluetooth, earpiece)
   - Hold/resume functionality
   - Mute/unmute support

---

## 🔄 Cross-Platform Considerations

### Event Names

Both platforms emit the same event names for consistency:

| Event | iOS | Android | Description |
|-------|-----|---------|-------------|
| `answerCall` | ✅ | ✅ | User answered call |
| `endCall` | ✅ | ✅ | User ended call |
| `didReceiveStartCallAction` | ✅ | ✅ | Outgoing call started |
| `didActivateAudioSession` | ✅ | ✅ | Audio session ready |
| `didDisplayIncomingCall` | ✅ | ✅ | Incoming call shown |
| `didPerformSetMutedCallAction` | ✅ | ✅ | Mute toggled |
| `didToggleHoldAction` | ✅ | ✅ | Hold toggled |
| `didPerformDTMFAction` | ✅ | ✅ | DTMF key pressed |
| `didResetProvider` | ✅ | ❌ | Provider reset (iOS only) |

### Method Signatures

All methods have identical signatures across platforms:

```typescript
// TypeScript interface (shared)
interface Spec extends TurboModule {
  setup(options: CallKeeperOptions): Promise<void>;
  displayIncomingCall(
    callUUID: string,
    handle: string,
    localizedCallerName?: string,
    handleType?: string,
    hasVideo?: boolean
  ): Promise<void>;
  // ... all other methods
}
```

### Error Handling

Both platforms use Promise-based error handling:

**iOS:**
```swift
resolve(nil) // Success
reject("ERROR_CODE", "Error message", error) // Failure
```

**Android:**
```kotlin
promise.resolve(null) // Success
promise.reject("ERROR_CODE", "Error message", e) // Failure
```

---

## 🚀 Setup & Configuration

### Expo Setup

1. **Install package:**
   ```bash
   npx expo install expo-call-keep
   ```

2. **Add config plugin:**
   ```json
   {
     "expo": {
       "plugins": ["expo-call-keep"]
     }
   }
   ```

3. **Rebuild:**
   ```bash
   npx expo prebuild --clean
   ```

### Bare React Native Setup

1. **Install:**
   ```bash
   npm install expo-call-keep
   ```

2. **iOS:**
   ```bash
   cd ios && pod install && cd ..
   ```

3. **Android:**
   - Permissions and service registration handled automatically
   - No manual configuration needed

### New Architecture Setup

**Enable New Architecture:**

1. **iOS:** Add to `ios/Podfile`:
   ```ruby
   use_react_native!(
     :new_arch_enabled => true
   )
   ```

2. **Android:** Add to `android/gradle.properties`:
   ```properties
   newArchEnabled=true
   ```

3. **Rebuild:**
   ```bash
   # iOS
   cd ios && pod install && cd ..
   npx react-native run-ios
   
   # Android
   cd android && ./gradlew clean && cd ..
   npx react-native run-android
   ```

---

## 💻 Code Examples

### Basic Setup

```typescript
import CallKeeper from 'expo-call-keep';

// Initialize
await CallKeeper.setup({
  appName: 'MyApp',
  supportsVideo: false,
  includesCallsInRecents: true,
});
```

### Display Incoming Call

```typescript
import { v4 as uuidv4 } from 'uuid';

const callUUID = uuidv4();

await CallKeeper.displayIncomingCall(
  callUUID,
  '+1234567890',
  'John Doe',
  'number',
  false
);
```

### Event Listeners

```typescript
// Answer call
CallKeeper.addEventListener('answerCall', ({ callUUID }) => {
  console.log('Call answered:', callUUID);
  // Connect your VoIP session
});

// End call
CallKeeper.addEventListener('endCall', ({ callUUID }) => {
  console.log('Call ended:', callUUID);
  // Disconnect your VoIP session
});

// Audio session ready
CallKeeper.addEventListener('didActivateAudioSession', () => {
  console.log('Audio session activated');
  // Start audio playback/recording
});
```

---

## 🐛 Platform-Specific Troubleshooting

### iOS Issues

#### Issue: Module Not Found
**Error:** `TurboModuleRegistry.getEnforcing(...): 'CallKeeper' could not be found`

**Solution:**
```bash
cd ios
rm -rf build
pod deintegrate
pod install
cd ..
npx react-native run-ios
```

#### Issue: CallKit Provider Crash
**Error:** `initWithLocalizedName: parameter 'localizedName' cannot be nil`

**Solution:** Ensure `appName` is provided in `setup()` options.

#### Issue: Events Not Firing
**Solution:**
1. Verify `setup()` is called before any other methods
2. Check event listeners are registered
3. Ensure module is properly linked

### Android Issues

#### Issue: Module Not Found
**Error:** `TurboModuleRegistry.getEnforcing(...): 'CallKeeper' could not be found`

**Solution:**
```bash
cd android
./gradlew clean
cd ..
npx react-native run-android
```

#### Issue: ConnectionService Not Registered
**Error:** `SecurityException: Failed to setup CallKeeper`

**Solution:**
1. Verify `BIND_TELECOM_CONNECTION_SERVICE` permission in AndroidManifest.xml
2. Check PhoneAccount registration in `setup()`
3. Ensure using `CAPABILITY_SELF_MANAGED` only (not combined with other capabilities)

#### Issue: Compilation Errors
**Error:** `Redeclaration: class CallKeeperModule`

**Solution:**
- Ensure correct source sets are configured in `build.gradle`
- Old arch: `src/oldarch/kotlin`
- New arch: `src/newarch/kotlin`

---

## 📊 Architecture Comparison

| Feature | iOS | Android |
|---------|-----|---------|
| **Framework** | CallKit | ConnectionService |
| **Language** | Swift/Objective-C | Kotlin |
| **Module Registration** | `RCT_EXPORT_MODULE` | `ReactPackage` / Auto (New Arch) |
| **Event System** | `RCTEventEmitter` | `DeviceEventManagerModule` |
| **Native UI** | System call screen | Heads-up notification |
| **Background** | VoIP push | Foreground service |
| **Audio** | AVAudioSession | AudioManager |
| **Minimum Version** | iOS 13.0 | Android 6.0 (API 23) |

---

## ✅ Testing Checklist

### iOS Testing
- [ ] Module loads correctly
- [ ] `setup()` completes without errors
- [ ] Incoming call displays on lock screen
- [ ] Incoming call displays in app
- [ ] Answer call works
- [ ] End call works
- [ ] Events fire correctly
- [ ] Audio session activates
- [ ] Mute/unmute works
- [ ] Hold/resume works

### Android Testing
- [ ] Module loads correctly
- [ ] `setup()` completes without errors
- [ ] Permissions granted
- [ ] Incoming call displays (heads-up)
- [ ] Answer call works
- [ ] End call works
- [ ] Events fire correctly
- [ ] Audio session activates
- [ ] Mute/unmute works
- [ ] Hold/resume works

### Cross-Platform Testing
- [ ] Same API works on both platforms
- [ ] Events have consistent names
- [ ] Error handling is consistent
- [ ] TypeScript types are correct

---

## 📚 Additional Resources

### iOS
- [CallKit Framework](https://developer.apple.com/documentation/callkit)
- [AVFoundation Audio](https://developer.apple.com/documentation/avfoundation/audio)
- [React Native iOS Modules](https://reactnative.dev/docs/native-modules-ios)

### Android
- [ConnectionService API](https://developer.android.com/reference/android/telecom/ConnectionService)
- [TelecomManager](https://developer.android.com/reference/android/telecom/TelecomManager)
- [React Native Android Modules](https://reactnative.dev/docs/native-modules-android)

### General
- [React Native New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page)
- [TurboModules Guide](https://reactnative.dev/docs/the-new-architecture/pillars-turbomodules)
- [Expo Config Plugins](https://docs.expo.dev/config-plugins/introduction/)

---

## 🔗 Related Documentation

- **Main README:** `README.md`
- **Implementation Guide:** `IMPLEMENTATION.md`
- **Android Architecture:** `ANDROID_ARCHITECTURE.md`
- **Quick Start:** `QUICK_START.md`

---

**Last Updated:** Version 1.0.3  
**Maintained By:** expo-call-keep contributors


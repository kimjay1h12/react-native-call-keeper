package com.callkeeper;

import android.Manifest;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.telecom.PhoneAccount;
import android.telecom.PhoneAccountHandle;
import android.telecom.TelecomManager;
import android.telecom.VideoProfile;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class CallKeeperModule extends CallKeeperSpec {

    private static final String E_SETUP_FAILED = "E_SETUP_FAILED";
    private static final String E_CALL_FAILED = "E_CALL_FAILED";
    private static final String E_PERMISSION_DENIED = "E_PERMISSION_DENIED";

    private final ReactApplicationContext reactContext;
    private TelecomManager telecomManager;
    private PhoneAccountHandle phoneAccountHandle;
    private String appName;
    private final Map<String, CallData> calls = new HashMap<>();

    public CallKeeperModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @NonNull
    @Override
    public String getName() {
        return "CallKeeper";
    }

    @ReactMethod
    public void setup(ReadableMap options, Promise promise) {
        try {
            appName = options.getString("appName");
            telecomManager = (TelecomManager) reactContext.getSystemService(Context.TELECOM_SERVICE);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ComponentName componentName = new ComponentName(
                    reactContext,
                    VoiceConnectionService.class
                );

                phoneAccountHandle = new PhoneAccountHandle(componentName, appName);

                PhoneAccount.Builder builder = new PhoneAccount.Builder(phoneAccountHandle, appName)
                    .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER |
                                   PhoneAccount.CAPABILITY_CONNECTION_MANAGER |
                                   PhoneAccount.CAPABILITY_SELF_MANAGED);

                if (options.hasKey("supportsVideo") && options.getBoolean("supportsVideo")) {
                    builder.setCapabilities(builder.build().getCapabilities() | 
                                          PhoneAccount.CAPABILITY_VIDEO_CALLING);
                }

                PhoneAccount account = builder.build();
                telecomManager.registerPhoneAccount(account);

                VoiceConnectionService.setPhoneAccountHandle(phoneAccountHandle);
                VoiceConnectionService.setReactContext(reactContext);
            }

            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_SETUP_FAILED, "Failed to setup CallKeeper: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void displayIncomingCall(
        String callUUID,
        String handle,
        @Nullable String localizedCallerName,
        @Nullable String handleType,
        @Nullable Boolean hasVideo,
        Promise promise
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Bundle extras = new Bundle();
                Uri uri = Uri.fromParts(
                    handleType != null && handleType.equals("number") ? "tel" : "sip",
                    handle,
                    null
                );

                extras.putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, uri);
                extras.putString(TelecomManager.EXTRA_CALL_SUBJECT, 
                               localizedCallerName != null ? localizedCallerName : handle);

                if (phoneAccountHandle != null) {
                    telecomManager.addNewIncomingCall(phoneAccountHandle, extras);
                    
                    CallData callData = new CallData(callUUID, handle, localizedCallerName, hasVideo != null && hasVideo);
                    calls.put(callUUID, callData);

                    WritableMap params = Arguments.createMap();
                    params.putString("callUUID", callUUID);
                    sendEvent("didDisplayIncomingCall", params);

                    promise.resolve(true);
                } else {
                    promise.reject(E_CALL_FAILED, "PhoneAccount not registered");
                }
            } else {
                promise.reject(E_CALL_FAILED, "Android version not supported");
            }
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to display incoming call: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void startCall(
        String callUUID,
        String handle,
        @Nullable String contactIdentifier,
        @Nullable String handleType,
        @Nullable Boolean hasVideo,
        Promise promise
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Bundle extras = new Bundle();
                Uri uri = Uri.fromParts(
                    handleType != null && handleType.equals("number") ? "tel" : "sip",
                    handle,
                    null
                );

                extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, phoneAccountHandle);
                boolean videoEnabled = hasVideo != null && hasVideo;
                extras.putBoolean(TelecomManager.EXTRA_START_CALL_WITH_VIDEO_STATE, videoEnabled);
                extras.putInt(TelecomManager.EXTRA_START_CALL_WITH_VIDEO_STATE,
                    videoEnabled ? VideoProfile.STATE_BIDIRECTIONAL : VideoProfile.STATE_AUDIO_ONLY);

                if (phoneAccountHandle != null) {
                    telecomManager.placeCall(uri, extras);

                    CallData callData = new CallData(callUUID, handle, contactIdentifier, videoEnabled);
                    calls.put(callUUID, callData);

                    WritableMap params = Arguments.createMap();
                    params.putString("callUUID", callUUID);
                    params.putString("handle", handle);
                    sendEvent("didReceiveStartCallAction", params);

                    promise.resolve(true);
                } else {
                    promise.reject(E_CALL_FAILED, "PhoneAccount not registered");
                }
            } else {
                promise.reject(E_CALL_FAILED, "Android version not supported");
            }
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to start call: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void endCall(String callUUID, Promise promise) {
        try {
            VoiceConnectionService.endCall(callUUID);
            calls.remove(callUUID);
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to end call: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void endAllCalls(Promise promise) {
        try {
            for (String callUUID : calls.keySet()) {
                VoiceConnectionService.endCall(callUUID);
            }
            calls.clear();
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to end all calls: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void answerIncomingCall(String callUUID, Promise promise) {
        try {
            VoiceConnectionService.answerCall(callUUID);
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to answer call: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void rejectCall(String callUUID, Promise promise) {
        endCall(callUUID, promise);
    }

    @ReactMethod
    public void setMutedCall(String callUUID, boolean muted, Promise promise) {
        try {
            VoiceConnectionService.setMuted(callUUID, muted);
            
            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            params.putBoolean("muted", muted);
            sendEvent("didPerformSetMutedCallAction", params);

            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to set mute: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void setOnHold(String callUUID, boolean onHold, Promise promise) {
        try {
            VoiceConnectionService.setOnHold(callUUID, onHold);
            
            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            params.putBoolean("hold", onHold);
            sendEvent("didToggleHoldAction", params);

            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to set hold: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void reportConnectedOutgoingCall(String callUUID, Promise promise) {
        try {
            VoiceConnectionService.setActive(callUUID);
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to report connected call: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void reportEndCallWithUUID(String callUUID, double reason, Promise promise) {
        try {
            VoiceConnectionService.endCall(callUUID);
            calls.remove(callUUID);
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to report end call: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void updateDisplay(String callUUID, String displayName, String handle, Promise promise) {
        try {
            CallData callData = calls.get(callUUID);
            if (callData != null) {
                callData.displayName = displayName;
                callData.handle = handle;
            }
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to update display: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void checkPermissions(Promise promise) {
        boolean hasPermissions = true;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            int phoneStatePermission = ContextCompat.checkSelfPermission(
                reactContext,
                Manifest.permission.READ_PHONE_STATE
            );
            int callPhonePermission = ContextCompat.checkSelfPermission(
                reactContext,
                Manifest.permission.CALL_PHONE
            );

            hasPermissions = phoneStatePermission == PackageManager.PERMISSION_GRANTED &&
                           callPhonePermission == PackageManager.PERMISSION_GRANTED;
        }

        promise.resolve(hasPermissions);
    }

    @ReactMethod
    public void checkIsInManagedCall(Promise promise) {
        promise.resolve(!calls.isEmpty());
    }

    @ReactMethod
    public void setAvailable(boolean available, Promise promise) {
        // Not implemented for Android
        promise.resolve(true);
    }

    @ReactMethod
    public void setCurrentCallActive(String callUUID, Promise promise) {
        try {
            VoiceConnectionService.setActive(callUUID);
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to set call active: " + e.getMessage(), e);
        }
    }

    @ReactMethod
    public void backToForeground(Promise promise) {
        try {
            Context context = reactContext.getApplicationContext();
            String packageName = context.getPackageName();
            Intent intent = context.getPackageManager().getLaunchIntentForPackage(packageName);
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                context.startActivity(intent);
            }
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject(E_CALL_FAILED, "Failed to bring to foreground: " + e.getMessage(), e);
        }
    }

    private void sendEvent(String eventName, @Nullable WritableMap params) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }

    static class CallData {
        String uuid;
        String handle;
        String displayName;
        boolean hasVideo;

        CallData(String uuid, String handle, String displayName, boolean hasVideo) {
            this.uuid = uuid;
            this.handle = handle;
            this.displayName = displayName;
            this.hasVideo = hasVideo;
        }
    }
}


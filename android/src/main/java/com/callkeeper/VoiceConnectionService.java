package com.callkeeper;

import android.net.Uri;
import android.os.Build;
import android.telecom.CallAudioState;
import android.telecom.Connection;
import android.telecom.ConnectionRequest;
import android.telecom.ConnectionService;
import android.telecom.PhoneAccountHandle;
import android.telecom.TelecomManager;
import android.telecom.VideoProfile;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RequiresApi(api = Build.VERSION_CODES.M)
public class VoiceConnectionService extends ConnectionService {

    private static PhoneAccountHandle phoneAccountHandle;
    private static ReactApplicationContext reactContext;
    private static final Map<String, VoiceConnection> connections = new HashMap<>();

    public static void setPhoneAccountHandle(PhoneAccountHandle handle) {
        phoneAccountHandle = handle;
    }

    public static void setReactContext(ReactApplicationContext context) {
        reactContext = context;
    }

    @Override
    public Connection onCreateIncomingConnection(
        PhoneAccountHandle connectionManagerPhoneAccount,
        ConnectionRequest request
    ) {
        String callUUID = UUID.randomUUID().toString();
        Uri address = request.getAddress();
        String handle = address != null ? address.getSchemeSpecificPart() : "Unknown";

        VoiceConnection connection = new VoiceConnection(callUUID, handle);
        connection.setConnectionProperties(Connection.PROPERTY_SELF_MANAGED);
        connection.setAddress(address, TelecomManager.PRESENTATION_ALLOWED);
        connection.setCallerDisplayName(handle, TelecomManager.PRESENTATION_ALLOWED);

        int videoState = request.getVideoState();
        if (videoState == VideoProfile.STATE_BIDIRECTIONAL) {
            connection.setVideoState(videoState);
        }

        connection.setRinging();
        connections.put(callUUID, connection);

        WritableMap params = Arguments.createMap();
        params.putString("callUUID", callUUID);
        params.putString("handle", handle);
        sendEvent("didDisplayIncomingCall", params);

        return connection;
    }

    @Override
    public Connection onCreateOutgoingConnection(
        PhoneAccountHandle connectionManagerPhoneAccount,
        ConnectionRequest request
    ) {
        String callUUID = UUID.randomUUID().toString();
        Uri address = request.getAddress();
        String handle = address != null ? address.getSchemeSpecificPart() : "Unknown";

        VoiceConnection connection = new VoiceConnection(callUUID, handle);
        connection.setConnectionProperties(Connection.PROPERTY_SELF_MANAGED);
        connection.setAddress(address, TelecomManager.PRESENTATION_ALLOWED);
        connection.setCallerDisplayName(handle, TelecomManager.PRESENTATION_ALLOWED);

        int videoState = request.getVideoState();
        if (videoState == VideoProfile.STATE_BIDIRECTIONAL) {
            connection.setVideoState(videoState);
        }

        connection.setDialing();
        connections.put(callUUID, connection);

        WritableMap params = Arguments.createMap();
        params.putString("callUUID", callUUID);
        params.putString("handle", handle);
        sendEvent("didReceiveStartCallAction", params);

        return connection;
    }

    public static void answerCall(String callUUID) {
        VoiceConnection connection = connections.get(callUUID);
        if (connection != null) {
            connection.setActive();
            
            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            sendEvent("answerCall", params);
        }
    }

    public static void endCall(String callUUID) {
        VoiceConnection connection = connections.get(callUUID);
        if (connection != null) {
            connection.setDisconnected(null);
            connection.destroy();
            connections.remove(callUUID);

            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            sendEvent("endCall", params);
        }
    }

    public static void setMuted(String callUUID, boolean muted) {
        VoiceConnection connection = connections.get(callUUID);
        if (connection != null) {
            connection.setMuted(muted);
        }
    }

    public static void setOnHold(String callUUID, boolean onHold) {
        VoiceConnection connection = connections.get(callUUID);
        if (connection != null) {
            if (onHold) {
                connection.setOnHold();
            } else {
                connection.setActive();
            }
        }
    }

    public static void setActive(String callUUID) {
        VoiceConnection connection = connections.get(callUUID);
        if (connection != null) {
            connection.setActive();
        }
    }

    private static void sendEvent(String eventName, @Nullable WritableMap params) {
        if (reactContext != null) {
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    static class VoiceConnection extends Connection {
        private final String callUUID;
        private final String handle;
        private boolean isMuted = false;

        VoiceConnection(String callUUID, String handle) {
            this.callUUID = callUUID;
            this.handle = handle;
            
            setConnectionCapabilities(
                Connection.CAPABILITY_HOLD |
                Connection.CAPABILITY_SUPPORT_HOLD |
                Connection.CAPABILITY_MUTE
            );
        }

        @Override
        public void onAnswer() {
            super.onAnswer();
            setActive();
            
            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            sendEvent("answerCall", params);
        }

        @Override
        public void onReject() {
            super.onReject();
            setDisconnected(null);
            destroy();
            connections.remove(callUUID);

            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            sendEvent("endCall", params);
        }

        @Override
        public void onDisconnect() {
            super.onDisconnect();
            setDisconnected(null);
            destroy();
            connections.remove(callUUID);

            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            sendEvent("endCall", params);
        }

        @Override
        public void onAbort() {
            super.onAbort();
            setDisconnected(null);
            destroy();
            connections.remove(callUUID);
        }

        @Override
        public void onHold() {
            super.onHold();
            setOnHold();

            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            params.putBoolean("hold", true);
            sendEvent("didToggleHoldAction", params);
        }

        @Override
        public void onUnhold() {
            super.onUnhold();
            setActive();

            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            params.putBoolean("hold", false);
            sendEvent("didToggleHoldAction", params);
        }

        @Override
        public void onCallAudioStateChanged(CallAudioState state) {
            super.onCallAudioStateChanged(state);
            isMuted = state.isMuted();

            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            params.putBoolean("muted", isMuted);
            sendEvent("didPerformSetMutedCallAction", params);
        }

        @Override
        public void onPlayDtmfTone(char c) {
            super.onPlayDtmfTone(c);
            
            WritableMap params = Arguments.createMap();
            params.putString("callUUID", callUUID);
            params.putString("digits", String.valueOf(c));
            sendEvent("didPerformDTMFAction", params);
        }

        public void setMuted(boolean muted) {
            isMuted = muted;
        }
    }
}


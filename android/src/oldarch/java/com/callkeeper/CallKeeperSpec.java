package com.callkeeper;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;

abstract class CallKeeperSpec extends ReactContextBaseJavaModule {
  CallKeeperSpec(ReactApplicationContext context) {
    super(context);
  }

  public abstract void setup(ReadableMap options, Promise promise);
  public abstract void displayIncomingCall(String callUUID, String handle, String localizedCallerName, String handleType, boolean hasVideo, Promise promise);
  public abstract void startCall(String callUUID, String handle, String contactIdentifier, String handleType, boolean hasVideo, Promise promise);
  public abstract void endCall(String callUUID, Promise promise);
  public abstract void endAllCalls(Promise promise);
  public abstract void answerIncomingCall(String callUUID, Promise promise);
  public abstract void rejectCall(String callUUID, Promise promise);
  public abstract void setMutedCall(String callUUID, boolean muted, Promise promise);
  public abstract void setOnHold(String callUUID, boolean onHold, Promise promise);
  public abstract void reportConnectedOutgoingCall(String callUUID, Promise promise);
  public abstract void reportEndCallWithUUID(String callUUID, int reason, Promise promise);
  public abstract void updateDisplay(String callUUID, String displayName, String handle, Promise promise);
  public abstract void checkPermissions(Promise promise);
  public abstract void checkIsInManagedCall(Promise promise);
  public abstract void setAvailable(boolean available, Promise promise);
  public abstract void setCurrentCallActive(String callUUID, Promise promise);
  public abstract void backToForeground(Promise promise);
}


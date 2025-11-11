package com.callkeeper

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReadableMap

abstract class CallKeeperSpec(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    abstract fun setup(options: ReadableMap, promise: Promise)
    abstract fun displayIncomingCall(
        callUUID: String,
        handle: String,
        localizedCallerName: String?,
        handleType: String?,
        hasVideo: Boolean?,
        promise: Promise
    )
    abstract fun startCall(
        callUUID: String,
        handle: String,
        contactIdentifier: String?,
        handleType: String?,
        hasVideo: Boolean?,
        promise: Promise
    )
    abstract fun endCall(callUUID: String, promise: Promise)
    abstract fun endAllCalls(promise: Promise)
    abstract fun answerIncomingCall(callUUID: String, promise: Promise)
    abstract fun rejectCall(callUUID: String, promise: Promise)
    abstract fun setMutedCall(callUUID: String, muted: Boolean, promise: Promise)
    abstract fun setOnHold(callUUID: String, onHold: Boolean, promise: Promise)
    abstract fun reportConnectedOutgoingCall(callUUID: String, promise: Promise)
    abstract fun reportEndCallWithUUID(callUUID: String, reason: Double, promise: Promise)
    abstract fun updateDisplay(callUUID: String, displayName: String, handle: String, promise: Promise)
    abstract fun checkPermissions(promise: Promise)
    abstract fun checkIsInManagedCall(promise: Promise)
    abstract fun setAvailable(available: Boolean, promise: Promise)
    abstract fun setCurrentCallActive(callUUID: String, promise: Promise)
    abstract fun backToForeground(promise: Promise)
}


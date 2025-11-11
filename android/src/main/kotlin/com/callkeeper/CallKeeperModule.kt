package com.callkeeper

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telecom.VideoProfile
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.util.*

class CallKeeperModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private val context: Context = reactContext.applicationContext
    private var phoneAccountHandle: PhoneAccountHandle? = null
    private var settings: ReadableMap? = null

    override fun getName(): String {
        return "CallKeeper"
    }

    private fun sendEvent(eventName: String, params: WritableMap?) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    @ReactMethod
    fun setup(options: ReadableMap, promise: Promise) {
        try {
            settings = options
            val appName = options.getString("appName") ?: "App"
            
            // Set ReactContext for event sending
            VoiceConnectionService.setReactContext(reactApplicationContext)
            
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

    @ReactMethod
    fun displayIncomingCall(
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

            val uri = Uri.fromParts(
                handleType ?: "generic",
                handle,
                null
            )

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
            sendEvent("answerCall", params)

            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("INCOMING_CALL_ERROR", "Failed to display incoming call: ${e.message}", e)
        }
    }

    @ReactMethod
    fun startCall(
        callUUID: String,
        handle: String,
        contactIdentifier: String?,
        handleType: String?,
        hasVideo: Boolean?,
        promise: Promise
    ) {
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val phoneAccountHandle = this.phoneAccountHandle
                ?: throw IllegalStateException("CallKeeper not initialized. Call setup() first.")

            val uri = Uri.fromParts(
                handleType ?: "generic",
                handle,
                null
            )

            val extras = Bundle().apply {
                putString("callUUID", callUUID)
                putString("handle", handle)
                putString("contactIdentifier", contactIdentifier)
                putBoolean("hasVideo", hasVideo ?: false)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                telecomManager.placeCall(uri, extras)
            }

            val params = Arguments.createMap().apply {
                putString("callUUID", callUUID)
                putString("handle", handle)
            }
            sendEvent("didReceiveStartCallAction", params)

            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("START_CALL_ERROR", "Failed to start call: ${e.message}", e)
        }
    }

    @ReactMethod
    fun endCall(callUUID: String, promise: Promise) {
        try {
            VoiceConnectionService.endCall(callUUID)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("END_CALL_ERROR", "Failed to end call: ${e.message}", e)
        }
    }

    @ReactMethod
    fun endAllCalls(promise: Promise) {
        try {
            VoiceConnectionService.endAllCalls()
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("END_ALL_CALLS_ERROR", "Failed to end all calls: ${e.message}", e)
        }
    }

    @ReactMethod
    fun answerIncomingCall(callUUID: String, promise: Promise) {
        try {
            VoiceConnectionService.answerCall(callUUID)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("ANSWER_CALL_ERROR", "Failed to answer call: ${e.message}", e)
        }
    }

    @ReactMethod
    fun rejectCall(callUUID: String, promise: Promise) {
        try {
            VoiceConnectionService.rejectCall(callUUID)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("REJECT_CALL_ERROR", "Failed to reject call: ${e.message}", e)
        }
    }

    @ReactMethod
    fun setMutedCall(callUUID: String, muted: Boolean, promise: Promise) {
        try {
            VoiceConnectionService.setMuted(callUUID, muted)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("MUTE_ERROR", "Failed to set mute: ${e.message}", e)
        }
    }

    @ReactMethod
    fun setOnHold(callUUID: String, onHold: Boolean, promise: Promise) {
        try {
            VoiceConnectionService.setOnHold(callUUID, onHold)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("HOLD_ERROR", "Failed to set hold: ${e.message}", e)
        }
    }

    @ReactMethod
    fun reportConnectedOutgoingCall(callUUID: String, promise: Promise) {
        try {
            VoiceConnectionService.reportConnected(callUUID)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("REPORT_CONNECTED_ERROR", "Failed to report connected: ${e.message}", e)
        }
    }

    @ReactMethod
    fun reportEndCallWithUUID(callUUID: String, reason: Double, promise: Promise) {
        try {
            VoiceConnectionService.reportEndCall(callUUID, reason.toInt())
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("REPORT_END_ERROR", "Failed to report end call: ${e.message}", e)
        }
    }

    @ReactMethod
    fun updateDisplay(callUUID: String, displayName: String, handle: String, promise: Promise) {
        try {
            VoiceConnectionService.updateDisplay(callUUID, displayName, handle)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("UPDATE_DISPLAY_ERROR", "Failed to update display: ${e.message}", e)
        }
    }

    @ReactMethod
    fun checkPermissions(promise: Promise) {
        try {
            val hasPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED &&
                context.checkSelfPermission(Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED &&
                context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }
            promise.resolve(hasPermissions)
        } catch (e: Exception) {
            promise.reject("CHECK_PERMISSIONS_ERROR", "Failed to check permissions: ${e.message}", e)
        }
    }

    @ReactMethod
    fun checkIsInManagedCall(promise: Promise) {
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val isInCall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                telecomManager.isInCall
            } else {
                false
            }
            promise.resolve(isInCall)
        } catch (e: Exception) {
            promise.reject("CHECK_CALL_ERROR", "Failed to check call state: ${e.message}", e)
        }
    }

    @ReactMethod
    fun setAvailable(available: Boolean, promise: Promise) {
        try {
            // Android-specific availability setting
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("SET_AVAILABLE_ERROR", "Failed to set available: ${e.message}", e)
        }
    }

    @ReactMethod
    fun setCurrentCallActive(callUUID: String, promise: Promise) {
        try {
            VoiceConnectionService.setActive(callUUID)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("SET_ACTIVE_ERROR", "Failed to set call active: ${e.message}", e)
        }
    }

    @ReactMethod
    fun backToForeground(promise: Promise) {
        try {
            // Bring app to foreground
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("FOREGROUND_ERROR", "Failed to bring to foreground: ${e.message}", e)
        }
    }
}


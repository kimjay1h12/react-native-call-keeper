package com.callkeeper

import android.net.Uri
import android.os.Bundle
import android.telecom.*
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import java.util.concurrent.ConcurrentHashMap

class VoiceConnectionService : ConnectionService() {
    companion object {
        private val activeConnections = ConcurrentHashMap<String, VoiceConnection>()
        private var reactContext: ReactApplicationContext? = null

        fun setReactContext(context: ReactApplicationContext?) {
            reactContext = context
        }

        private fun sendEvent(eventName: String, params: WritableMap?) {
            reactContext?.let { context ->
                try {
                    context
                        .getJSModule(com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                        .emit(eventName, params)
                } catch (e: Exception) {
                    // Event emitter not available
                }
            }
        }

        fun endCall(callUUID: String) {
            activeConnections[callUUID]?.destroy()
        }

        fun endAllCalls() {
            activeConnections.values.forEach { it.destroy() }
            activeConnections.clear()
        }

        fun answerCall(callUUID: String) {
            activeConnections[callUUID]?.let { connection ->
                connection.setActive()
                connection.activate()
            }
        }

        fun rejectCall(callUUID: String) {
            activeConnections[callUUID]?.setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
        }

        fun setMuted(callUUID: String, muted: Boolean) {
            activeConnections[callUUID]?.setMuted(muted)
        }

        fun setOnHold(callUUID: String, onHold: Boolean) {
            if (onHold) {
                activeConnections[callUUID]?.onHold()
            } else {
                activeConnections[callUUID]?.onUnhold()
            }
        }

        fun reportConnected(callUUID: String) {
            activeConnections[callUUID]?.let { connection ->
                connection.setActive()
                connection.activate()
            }
        }

        fun reportEndCall(callUUID: String, reason: Int) {
            val disconnectCause = when (reason) {
                1 -> DisconnectCause(DisconnectCause.ERROR)
                2 -> DisconnectCause(DisconnectCause.REMOTE)
                3 -> DisconnectCause(DisconnectCause.LOCAL)
                4 -> DisconnectCause(DisconnectCause.CANCELED)
                5 -> DisconnectCause(DisconnectCause.REJECTED)
                6 -> DisconnectCause(DisconnectCause.MISSED)
                else -> DisconnectCause(DisconnectCause.UNKNOWN)
            }
            activeConnections[callUUID]?.setDisconnected(disconnectCause)
        }

        fun updateDisplay(callUUID: String, displayName: String, handle: String) {
            activeConnections[callUUID]?.let { connection ->
                val statusHints = StatusHints(displayName, null, null)
                connection.statusHints = statusHints
            }
        }

        fun setActive(callUUID: String) {
            activeConnections[callUUID]?.let { connection ->
                connection.setActive()
                connection.activate()
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

    override fun onCreateOutgoingConnection(
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
        init {
            setConnectionCapabilities(
                CAPABILITY_SUPPORT_HOLD or
                CAPABILITY_MUTE or
                CAPABILITY_SUPPORTS_VT_LOCAL_BIDIRECTIONAL
            )
        }

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

        override fun onAbort() {
            super.onAbort()
            setDisconnected(DisconnectCause(DisconnectCause.CANCELED))
            sendEvent("endCall", Arguments.createMap().apply {
                putString("callUUID", callUUID)
            })
            activeConnections.remove(callUUID)
            destroy()
        }

        override fun onHold() {
            super.onHold()
            sendEvent("didToggleHoldAction", Arguments.createMap().apply {
                putString("callUUID", callUUID)
                putBoolean("hold", true)
            })
        }

        override fun onUnhold() {
            super.onUnhold()
            activate()
            sendEvent("didToggleHoldAction", Arguments.createMap().apply {
                putString("callUUID", callUUID)
                putBoolean("hold", false)
            })
        }

        override fun onMuteStateChanged(isMuted: Boolean) {
            super.onMuteStateChanged(isMuted)
            sendEvent("didPerformSetMutedCallAction", Arguments.createMap().apply {
                putString("callUUID", callUUID)
                putBoolean("muted", isMuted)
            })
        }

        override fun onPlayDtmfTone(c: Char) {
            super.onPlayDtmfTone(c)
            sendEvent("didPerformDTMFAction", Arguments.createMap().apply {
                putString("callUUID", callUUID)
                putString("digits", c.toString())
            })
        }

        fun activate() {
            setActive()
            sendEvent("didActivateAudioSession", null)
        }

        private fun sendEvent(eventName: String, params: WritableMap?) {
            Companion.sendEvent(eventName, params)
        }
    }
}


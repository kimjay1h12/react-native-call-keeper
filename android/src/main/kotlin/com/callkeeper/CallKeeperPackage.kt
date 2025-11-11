package com.callkeeper

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class CallKeeperPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        // For Old Architecture: creates CallKeeperModule from src/oldarch/kotlin
        // For New Architecture: module is auto-registered by codegen, so we return empty list
        // The build system handles which sourceSet is active based on newArchEnabled property
        return try {
            // Try to create the module - will work for old arch, fail for new arch (which is fine)
            listOf(CallKeeperModule(reactContext))
        } catch (e: Exception) {
            // New Architecture - module is auto-registered by TurboModule system
            emptyList()
        }
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}


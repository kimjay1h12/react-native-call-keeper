package com.callkeeper

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class CallKeeperPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        // Check if New Architecture is enabled
        val isNewArchEnabled = try {
            val buildConfigClass = Class.forName("com.callkeeper.BuildConfig")
            val isNewArchField = buildConfigClass.getField("IS_NEW_ARCHITECTURE_ENABLED")
            isNewArchField.getBoolean(null)
        } catch (e: Exception) {
            false
        }
        
        // For New Architecture: module is auto-registered by codegen
        if (isNewArchEnabled) {
            return emptyList()
        }
        
        // For Old Architecture: create module using reflection to avoid compile-time dependency
        return try {
            val moduleClass = Class.forName("com.callkeeper.CallKeeperModule")
            val constructor = moduleClass.getConstructor(ReactApplicationContext::class.java)
            val module = constructor.newInstance(reactContext) as NativeModule
            listOf(module)
        } catch (e: Exception) {
            // If module class not found, return empty list
            emptyList()
        }
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}


package com.callkeeper

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class CallKeeperPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        // Check if New Architecture is enabled using BuildConfig
        val isNewArchEnabled = try {
            val buildConfigClass = Class.forName("com.callkeeper.BuildConfig")
            val isNewArchField = buildConfigClass.getField("IS_NEW_ARCHITECTURE_ENABLED")
            isNewArchField.getBoolean(null)
        } catch (e: Exception) {
            // If BuildConfig not available, assume old architecture
            false
        }
        
        // For New Architecture: module is auto-registered by TurboModule codegen
        // Return empty list - the module will be registered automatically
        if (isNewArchEnabled) {
            return emptyList()
        }
        
        // For Old Architecture: create module instance
        // Use reflection to avoid compile-time dependency issues
        // This allows the package to compile regardless of which source sets are included
        return try {
            val moduleClass = Class.forName("com.callkeeper.CallKeeperModule")
            val constructor = moduleClass.getConstructor(ReactApplicationContext::class.java)
            val moduleInstance = constructor.newInstance(reactContext)
            @Suppress("UNCHECKED_CAST")
            listOf(moduleInstance as NativeModule)
        } catch (e: ClassNotFoundException) {
            // Module class not found - this shouldn't happen in old arch, but handle gracefully
            emptyList()
        } catch (e: Exception) {
            // Any other error creating the module
            emptyList()
        }
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}


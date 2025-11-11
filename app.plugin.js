const {
  withInfoPlist,
  withAndroidManifest,
  createRunOncePlugin,
} = require('@expo/config-plugins');

/**
 * Add CallKit background mode to iOS Info.plist
 */
function withCallKitBackground(config) {
  return withInfoPlist(config, (config) => {
    if (!config.modResults.UIBackgroundModes) {
      config.modResults.UIBackgroundModes = [];
    }
    
    const backgroundModes = config.modResults.UIBackgroundModes;
    
    if (!backgroundModes.includes('voip')) {
      backgroundModes.push('voip');
    }
    
    if (!backgroundModes.includes('audio')) {
      backgroundModes.push('audio');
    }

    return config;
  });
}

/**
 * Add required permissions to AndroidManifest.xml
 */
function withCallKeeperPermissions(config) {
  return withAndroidManifest(config, (config) => {
    const androidManifest = config.modResults.manifest;

    // Ensure application tag exists
    if (!androidManifest.application) {
      androidManifest.application = [{}];
    }

    // Ensure uses-permission array exists
    if (!androidManifest['uses-permission']) {
      androidManifest['uses-permission'] = [];
    }

    const permissions = [
      'android.permission.BIND_TELECOM_CONNECTION_SERVICE',
      'android.permission.FOREGROUND_SERVICE',
      'android.permission.READ_PHONE_STATE',
      'android.permission.CALL_PHONE',
      'android.permission.RECORD_AUDIO',
      'android.permission.WAKE_LOCK',
      'android.permission.READ_CALL_LOG',
      'android.permission.WRITE_CALL_LOG',
      'android.permission.MANAGE_OWN_CALLS',
    ];

    // Add permissions if they don't exist
    permissions.forEach((permission) => {
      const hasPermission = androidManifest['uses-permission'].some(
        (p) => p.$['android:name'] === permission
      );

      if (!hasPermission) {
        androidManifest['uses-permission'].push({
          $: {
            'android:name': permission,
          },
        });
      }
    });

    return config;
  });
}

/**
 * Main plugin function
 */
function withCallKeeper(config, props = {}) {
  // Apply iOS modifications
  config = withCallKitBackground(config);
  
  // Apply Android modifications
  config = withCallKeeperPermissions(config);

  return config;
}

module.exports = createRunOncePlugin(
  withCallKeeper,
  'expo-call-keep',
  '1.0.0'
);


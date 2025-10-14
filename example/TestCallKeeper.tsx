import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  Button,
  StyleSheet,
  ScrollView,
  Alert,
  Platform,
} from 'react-native';
import CallKeeper from 'react-native-call-keeper';
import type { CallKeeperEvent } from 'react-native-call-keeper';

const TestCallKeeper = () => {
  const [isSetup, setIsSetup] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);
  const [activeCallUUID, setActiveCallUUID] = useState<string | null>(null);

  const addLog = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs((prev) => [`[${timestamp}] ${message}`, ...prev].slice(0, 50));
    console.log(`[CallKeeper] ${message}`);
  };

  useEffect(() => {
    setupCallKeeper();
    setupEventListeners();

    return () => {
      CallKeeper.removeAllListeners();
    };
  }, []);

  const setupCallKeeper = async () => {
    try {
      addLog('Starting CallKeeper setup...');

      await CallKeeper.setup({
        appName: 'TestCallApp',
        supportsVideo: true,
        includesCallsInRecents: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      });

      addLog('✅ CallKeeper setup successful!');
      setIsSetup(true);

      // Check permissions
      const hasPermissions = await CallKeeper.checkPermissions();
      addLog(`Permissions status: ${hasPermissions ? 'Granted' : 'Not granted'}`);
    } catch (error: any) {
      addLog(`❌ Setup failed: ${error.message}`);
      Alert.alert('Setup Error', error.message);
    }
  };

  const setupEventListeners = () => {
    addLog('Setting up event listeners...');

    CallKeeper.addEventListener('answerCall', (event: CallKeeperEvent) => {
      addLog(`🔔 EVENT: answerCall - UUID: ${event.callUUID}`);
      if (activeCallUUID) {
        CallKeeper.setCurrentCallActive(event.callUUID);
      }
    });

    CallKeeper.addEventListener('endCall', (event: CallKeeperEvent) => {
      addLog(`🔔 EVENT: endCall - UUID: ${event.callUUID}`);
      setActiveCallUUID(null);
    });

    CallKeeper.addEventListener('didReceiveStartCallAction', (event: CallKeeperEvent) => {
      addLog(`🔔 EVENT: didReceiveStartCallAction - UUID: ${event.callUUID}, Handle: ${event.handle}`);
    });

    CallKeeper.addEventListener('didActivateAudioSession', () => {
      addLog('🔔 EVENT: didActivateAudioSession');
    });

    CallKeeper.addEventListener('didDisplayIncomingCall', (event: CallKeeperEvent) => {
      addLog(`🔔 EVENT: didDisplayIncomingCall - UUID: ${event.callUUID}`);
    });

    CallKeeper.addEventListener('didPerformSetMutedCallAction', (event: CallKeeperEvent) => {
      addLog(`🔔 EVENT: didPerformSetMutedCallAction - Muted: ${event.muted}`);
    });

    CallKeeper.addEventListener('didToggleHoldAction', (event: CallKeeperEvent) => {
      addLog(`🔔 EVENT: didToggleHoldAction - Hold: ${event.hold}`);
    });

    CallKeeper.addEventListener('didResetProvider', () => {
      addLog('🔔 EVENT: didResetProvider');
    });

    addLog('✅ Event listeners registered');
  };

  const testIncomingCall = async () => {
    try {
      const uuid = generateUUID();
      addLog(`Testing incoming call with UUID: ${uuid}`);

      await CallKeeper.displayIncomingCall(
        uuid,
        '+1234567890',
        'John Doe',
        'number',
        false
      );

      setActiveCallUUID(uuid);
      addLog('✅ Incoming call displayed');
    } catch (error: any) {
      addLog(`❌ Incoming call failed: ${error.message}`);
    }
  };

  const testOutgoingCall = async () => {
    try {
      const uuid = generateUUID();
      addLog(`Testing outgoing call with UUID: ${uuid}`);

      await CallKeeper.startCall(
        uuid,
        '+1234567890',
        'Jane Doe',
        'number',
        false
      );

      setActiveCallUUID(uuid);
      addLog('✅ Outgoing call started');

      // Simulate connection after 2 seconds
      setTimeout(async () => {
        await CallKeeper.reportConnectedOutgoingCall(uuid);
        addLog('✅ Outgoing call connected');
      }, 2000);
    } catch (error: any) {
      addLog(`❌ Outgoing call failed: ${error.message}`);
    }
  };

  const testEndCall = async () => {
    if (!activeCallUUID) {
      Alert.alert('No Active Call', 'Start a call first');
      return;
    }

    try {
      addLog(`Ending call: ${activeCallUUID}`);
      await CallKeeper.endCall(activeCallUUID);
      await CallKeeper.reportEndCallWithUUID(activeCallUUID, 3); // Local ended
      setActiveCallUUID(null);
      addLog('✅ Call ended');
    } catch (error: any) {
      addLog(`❌ End call failed: ${error.message}`);
    }
  };

  const testMuteCall = async () => {
    if (!activeCallUUID) {
      Alert.alert('No Active Call', 'Start a call first');
      return;
    }

    try {
      await CallKeeper.setMutedCall(activeCallUUID, true);
      addLog('✅ Call muted');
    } catch (error: any) {
      addLog(`❌ Mute failed: ${error.message}`);
    }
  };

  const testHoldCall = async () => {
    if (!activeCallUUID) {
      Alert.alert('No Active Call', 'Start a call first');
      return;
    }

    try {
      await CallKeeper.setOnHold(activeCallUUID, true);
      addLog('✅ Call on hold');
    } catch (error: any) {
      addLog(`❌ Hold failed: ${error.message}`);
    }
  };

  const testCheckInCall = async () => {
    try {
      const inCall = await CallKeeper.checkIsInManagedCall();
      addLog(`In managed call: ${inCall}`);
    } catch (error: any) {
      addLog(`❌ Check failed: ${error.message}`);
    }
  };

  const generateUUID = () => {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>CallKeeper Test</Text>
        <Text style={styles.status}>
          Status: {isSetup ? '✅ Ready' : '⏳ Setting up...'}
        </Text>
        {activeCallUUID && (
          <Text style={styles.activeCall}>
            Active Call: {activeCallUUID.substring(0, 8)}...
          </Text>
        )}
      </View>

      <View style={styles.buttonContainer}>
        <Button title="📞 Incoming Call" onPress={testIncomingCall} />
        <Button title="📱 Outgoing Call" onPress={testOutgoingCall} />
        <Button title="❌ End Call" onPress={testEndCall} />
        <Button title="🔇 Mute" onPress={testMuteCall} />
        <Button title="⏸️ Hold" onPress={testHoldCall} />
        <Button title="ℹ️ Check In Call" onPress={testCheckInCall} />
        <Button title="🗑️ Clear Logs" onPress={() => setLogs([])} />
      </View>

      <View style={styles.logContainer}>
        <Text style={styles.logTitle}>Event Logs:</Text>
        <ScrollView style={styles.logScroll}>
          {logs.map((log, index) => (
            <Text key={index} style={styles.logText}>
              {log}
            </Text>
          ))}
          {logs.length === 0 && (
            <Text style={styles.emptyLog}>No logs yet...</Text>
          )}
        </ScrollView>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  header: {
    marginBottom: 20,
    padding: 15,
    backgroundColor: 'white',
    borderRadius: 10,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  status: {
    fontSize: 16,
    color: '#666',
  },
  activeCall: {
    fontSize: 14,
    color: '#007AFF',
    marginTop: 5,
  },
  buttonContainer: {
    gap: 10,
    marginBottom: 20,
  },
  logContainer: {
    flex: 1,
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 10,
  },
  logTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  logScroll: {
    flex: 1,
  },
  logText: {
    fontSize: 12,
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
    marginBottom: 5,
    color: '#333',
  },
  emptyLog: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    marginTop: 20,
  },
});

export default TestCallKeeper;


import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import NativeCallKeeper from './NativeCallKeeper';
import type { CallKeeperOptions, CallData } from './NativeCallKeeper';

export type { CallKeeperOptions, CallData };

export type CallKeeperEventType =
  | 'didReceiveStartCallAction'
  | 'answerCall'
  | 'endCall'
  | 'didActivateAudioSession'
  | 'didDisplayIncomingCall'
  | 'didPerformSetMutedCallAction'
  | 'didToggleHoldAction'
  | 'didPerformDTMFAction'
  | 'didLoadWithEvents'
  | 'checkReachability'
  | 'didResetProvider';

export interface CallKeeperEvent {
  callUUID: string;
  handle?: string;
  name?: string;
  muted?: boolean;
  hold?: boolean;
  digits?: string;
}

class CallKeeperModule {
  private eventEmitter: NativeEventEmitter;
  private listeners: Map<string, any[]> = new Map();

  constructor() {
    this.eventEmitter = new NativeEventEmitter(
      NativeModules.CallKeeper || NativeCallKeeper
    );
  }

  /**
   * Initialize the CallKeeper module with configuration options
   */
  async setup(options: CallKeeperOptions): Promise<void> {
    try {
      await NativeCallKeeper.setup(options);
    } catch (error) {
      console.error('CallKeeper setup error:', error);
      throw error;
    }
  }

  /**
   * Display an incoming call notification
   */
  async displayIncomingCall(
    callUUID: string,
    handle: string,
    localizedCallerName?: string,
    handleType: 'generic' | 'number' | 'email' = 'generic',
    hasVideo: boolean = false
  ): Promise<void> {
    return NativeCallKeeper.displayIncomingCall(
      callUUID,
      handle,
      localizedCallerName,
      handleType,
      hasVideo
    );
  }

  /**
   * Start an outgoing call
   */
  async startCall(
    callUUID: string,
    handle: string,
    contactIdentifier?: string,
    handleType: 'generic' | 'number' | 'email' = 'generic',
    hasVideo: boolean = false
  ): Promise<void> {
    return NativeCallKeeper.startCall(
      callUUID,
      handle,
      contactIdentifier,
      handleType,
      hasVideo
    );
  }

  /**
   * End a specific call
   */
  async endCall(callUUID: string): Promise<void> {
    return NativeCallKeeper.endCall(callUUID);
  }

  /**
   * End all active calls
   */
  async endAllCalls(): Promise<void> {
    return NativeCallKeeper.endAllCalls();
  }

  /**
   * Answer an incoming call
   */
  async answerIncomingCall(callUUID: string): Promise<void> {
    return NativeCallKeeper.answerIncomingCall(callUUID);
  }

  /**
   * Reject an incoming call
   */
  async rejectCall(callUUID: string): Promise<void> {
    return NativeCallKeeper.rejectCall(callUUID);
  }

  /**
   * Set mute status for a call
   */
  async setMutedCall(callUUID: string, muted: boolean): Promise<void> {
    return NativeCallKeeper.setMutedCall(callUUID, muted);
  }

  /**
   * Put a call on hold
   */
  async setOnHold(callUUID: string, onHold: boolean): Promise<void> {
    return NativeCallKeeper.setOnHold(callUUID, onHold);
  }

  /**
   * Report that an outgoing call has connected
   */
  async reportConnectedOutgoingCall(callUUID: string): Promise<void> {
    return NativeCallKeeper.reportConnectedOutgoingCall(callUUID);
  }

  /**
   * Report that a call has ended
   * @param callUUID - The UUID of the call
   * @param reason - End call reason (1: failed, 2: remote ended, 3: local ended, 4: answered elsewhere, 5: declined elsewhere, 6: missed)
   */
  async reportEndCallWithUUID(callUUID: string, reason: number): Promise<void> {
    return NativeCallKeeper.reportEndCallWithUUID(callUUID, reason);
  }

  /**
   * Update the display information for a call
   */
  async updateDisplay(
    callUUID: string,
    displayName: string,
    handle: string
  ): Promise<void> {
    return NativeCallKeeper.updateDisplay(callUUID, displayName, handle);
  }

  /**
   * Check if the app has necessary permissions
   */
  async checkPermissions(): Promise<boolean> {
    return NativeCallKeeper.checkPermissions();
  }

  /**
   * Check if there's an active managed call
   */
  async checkIsInManagedCall(): Promise<boolean> {
    return NativeCallKeeper.checkIsInManagedCall();
  }

  /**
   * Set availability for receiving calls (Android only)
   */
  async setAvailable(available: boolean): Promise<void> {
    if (Platform.OS === 'android') {
      return NativeCallKeeper.setAvailable(available);
    }
  }

  /**
   * Set the current call as active
   */
  async setCurrentCallActive(callUUID: string): Promise<void> {
    return NativeCallKeeper.setCurrentCallActive(callUUID);
  }

  /**
   * Bring the app to foreground
   */
  async backToForeground(): Promise<void> {
    return NativeCallKeeper.backToForeground();
  }

  /**
   * Add event listener
   */
  addEventListener(
    eventType: CallKeeperEventType,
    listener: (event: CallKeeperEvent) => void
  ): void {
    const subscription = this.eventEmitter.addListener(eventType, listener);
    
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, []);
    }
    this.listeners.get(eventType)?.push(subscription);
  }

  /**
   * Remove event listener
   */
  removeEventListener(eventType: CallKeeperEventType): void {
    const subscriptions = this.listeners.get(eventType);
    if (subscriptions) {
      subscriptions.forEach((subscription) => subscription.remove());
      this.listeners.delete(eventType);
    }
  }

  /**
   * Remove all event listeners
   */
  removeAllListeners(): void {
    this.listeners.forEach((subscriptions) => {
      subscriptions.forEach((subscription) => subscription.remove());
    });
    this.listeners.clear();
  }
}

export default new CallKeeperModule();


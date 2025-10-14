import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface CallKeeperOptions {
  appName: string;
  imageName?: string;
  ringtoneSound?: string;
  includesCallsInRecents?: boolean;
  supportsVideo?: boolean;
  maximumCallGroups?: number;
  maximumCallsPerCallGroup?: number;
}

export interface CallData {
  callUUID: string;
  handle: string;
  handleType?: 'generic' | 'number' | 'email';
  hasVideo?: boolean;
  localizedCallerName?: string;
  supportsGrouping?: boolean;
  supportsUngrouping?: boolean;
  supportsDTMF?: boolean;
  supportsHolding?: boolean;
}

export interface Spec extends TurboModule {
  setup(options: CallKeeperOptions): Promise<void>;
  displayIncomingCall(
    callUUID: string,
    handle: string,
    localizedCallerName?: string,
    handleType?: string,
    hasVideo?: boolean
  ): Promise<void>;
  startCall(
    callUUID: string,
    handle: string,
    contactIdentifier?: string,
    handleType?: string,
    hasVideo?: boolean
  ): Promise<void>;
  endCall(callUUID: string): Promise<void>;
  endAllCalls(): Promise<void>;
  answerIncomingCall(callUUID: string): Promise<void>;
  rejectCall(callUUID: string): Promise<void>;
  setMutedCall(callUUID: string, muted: boolean): Promise<void>;
  setOnHold(callUUID: string, onHold: boolean): Promise<void>;
  reportConnectedOutgoingCall(callUUID: string): Promise<void>;
  reportEndCallWithUUID(
    callUUID: string,
    reason: number
  ): Promise<void>;
  updateDisplay(
    callUUID: string,
    displayName: string,
    handle: string
  ): Promise<void>;
  checkPermissions(): Promise<boolean>;
  checkIsInManagedCall(): Promise<boolean>;
  setAvailable(available: boolean): Promise<void>;
  setCurrentCallActive(callUUID: string): Promise<void>;
  backToForeground(): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('CallKeeper');


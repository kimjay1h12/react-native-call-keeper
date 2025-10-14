#import "CallKeeper.h"
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <CallKit/CallKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CallKeeper () <CXProviderDelegate>
@property (nonatomic, strong) CXProvider *provider;
@property (nonatomic, strong) CXCallController *callController;
@property (nonatomic, strong) NSMutableDictionary *calls;
@property (nonatomic, strong) NSString *appName;
@end

@implementation CallKeeper

RCT_EXPORT_MODULE(CallKeeper)

- (instancetype)init
{
    if (self = [super init]) {
        _calls = [[NSMutableDictionary alloc] init];
        _callController = [[CXCallController alloc] init];
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[
        @"didReceiveStartCallAction",
        @"answerCall",
        @"endCall",
        @"didActivateAudioSession",
        @"didDisplayIncomingCall",
        @"didPerformSetMutedCallAction",
        @"didToggleHoldAction",
        @"didPerformDTMFAction",
        @"didLoadWithEvents",
        @"checkReachability",
        @"didResetProvider"
    ];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

RCT_EXPORT_METHOD(setup:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            self.appName = options[@"appName"];
            
            CXProviderConfiguration *configuration;
            if (@available(iOS 14.0, *)) {
                configuration = [[CXProviderConfiguration alloc] init];
                configuration.localizedName = self.appName;
            } else {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:self.appName];
                #pragma clang diagnostic pop
            }
            
            configuration.maximumCallGroups = [options[@"maximumCallGroups"] unsignedIntegerValue] ?: 1;
            configuration.maximumCallsPerCallGroup = [options[@"maximumCallsPerCallGroup"] unsignedIntegerValue] ?: 1;
            configuration.supportsVideo = [options[@"supportsVideo"] boolValue];
            
            if (options[@"imageName"]) {
                configuration.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:options[@"imageName"]]);
            }
            
            if (options[@"ringtoneSound"]) {
                configuration.ringtoneSound = options[@"ringtoneSound"];
            }
            
            configuration.includesCallsInRecents = [options[@"includesCallsInRecents"] boolValue];
            
            // Set supported handle types
            NSMutableSet *supportedHandleTypes = [NSMutableSet new];
            [supportedHandleTypes addObject:@(CXHandleTypePhoneNumber)];
            [supportedHandleTypes addObject:@(CXHandleTypeGeneric)];
            [supportedHandleTypes addObject:@(CXHandleTypeEmailAddress)];
            configuration.supportedHandleTypes = supportedHandleTypes;
            
            self.provider = [[CXProvider alloc] initWithConfiguration:configuration];
            [self.provider setDelegate:self queue:nil];
            
            resolve(@(YES));
        } @catch (NSException *exception) {
            reject(@"setup_error", exception.reason, nil);
        }
    });
}

RCT_EXPORT_METHOD(displayIncomingCall:(NSString *)callUUID
                  handle:(NSString *)handle
                  localizedCallerName:(NSString *)localizedCallerName
                  handleType:(NSString *)handleType
                  hasVideo:(NSNumber *)hasVideo
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
        callUpdate.remoteHandle = [[CXHandle alloc] initWithType:[self getHandleType:handleType] value:handle];
        callUpdate.localizedCallerName = localizedCallerName ?: handle;
        callUpdate.hasVideo = hasVideo ? [hasVideo boolValue] : NO;
        callUpdate.supportsHolding = YES;
        callUpdate.supportsGrouping = NO;
        callUpdate.supportsUngrouping = NO;
        callUpdate.supportsDTMF = YES;
        
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        
        [self.provider reportNewIncomingCallWithUUID:uuid
                                               update:callUpdate
                                           completion:^(NSError * _Nullable error) {
            if (error) {
                reject(@"incoming_call_error", error.localizedDescription, error);
            } else {
                self.calls[callUUID] = @{@"handle": handle, @"hasVideo": hasVideo ?: @(NO)};
                [self sendEventWithName:@"didDisplayIncomingCall" body:@{@"callUUID": callUUID}];
                resolve(@(YES));
            }
        }];
    });
}

RCT_EXPORT_METHOD(startCall:(NSString *)callUUID
                  handle:(NSString *)handle
                  contactIdentifier:(NSString *)contactIdentifier
                  handleType:(NSString *)handleType
                  hasVideo:(NSNumber *)hasVideo
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CXHandle *callHandle = [[CXHandle alloc] initWithType:[self getHandleType:handleType] value:handle];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        
        CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
        startCallAction.video = hasVideo ? [hasVideo boolValue] : NO;
        startCallAction.contactIdentifier = contactIdentifier;
        
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
        
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error) {
                reject(@"start_call_error", error.localizedDescription, error);
            } else {
                self.calls[callUUID] = @{@"handle": handle, @"hasVideo": hasVideo ?: @(NO)};
                resolve(@(YES));
            }
        }];
    });
}

RCT_EXPORT_METHOD(endCall:(NSString *)callUUID
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
        
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error) {
                reject(@"end_call_error", error.localizedDescription, error);
            } else {
                [self.calls removeObjectForKey:callUUID];
                resolve(@(YES));
            }
        }];
    });
}

RCT_EXPORT_METHOD(endAllCalls:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *callUUIDs = [self.calls allKeys];
        for (NSString *callUUID in callUUIDs) {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
            CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
            CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
            [self.callController requestTransaction:transaction completion:nil];
        }
        [self.calls removeAllObjects];
        resolve(@(YES));
    });
}

RCT_EXPORT_METHOD(answerIncomingCall:(NSString *)callUUID
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXAnswerCallAction *answerAction = [[CXAnswerCallAction alloc] initWithCallUUID:uuid];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:answerAction];
        
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error) {
                reject(@"answer_call_error", error.localizedDescription, error);
            } else {
                resolve(@(YES));
            }
        }];
    });
}

RCT_EXPORT_METHOD(rejectCall:(NSString *)callUUID
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    [self endCall:callUUID resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(setMutedCall:(NSString *)callUUID
                  muted:(BOOL)muted
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXSetMutedCallAction *muteAction = [[CXSetMutedCallAction alloc] initWithCallUUID:uuid muted:muted];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:muteAction];
        
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error) {
                reject(@"mute_error", error.localizedDescription, error);
            } else {
                resolve(@(YES));
            }
        }];
    });
}

RCT_EXPORT_METHOD(setOnHold:(NSString *)callUUID
                  onHold:(BOOL)onHold
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXSetHeldCallAction *holdAction = [[CXSetHeldCallAction alloc] initWithCallUUID:uuid onHold:onHold];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:holdAction];
        
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error) {
                reject(@"hold_error", error.localizedDescription, error);
            } else {
                resolve(@(YES));
            }
        }];
    });
}

RCT_EXPORT_METHOD(reportConnectedOutgoingCall:(NSString *)callUUID
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        [self.provider reportOutgoingCallWithUUID:uuid connectedAtDate:[NSDate date]];
        resolve(@(YES));
    });
}

RCT_EXPORT_METHOD(reportEndCallWithUUID:(NSString *)callUUID
                  reason:(NSInteger)reason
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXCallEndedReason endReason;
        
        switch (reason) {
            case 1:
                endReason = CXCallEndedReasonFailed;
                break;
            case 2:
                endReason = CXCallEndedReasonRemoteEnded;
                break;
            case 3:
                endReason = CXCallEndedReasonUnanswered;
                break;
            case 4:
                endReason = CXCallEndedReasonAnsweredElsewhere;
                break;
            case 5:
                endReason = CXCallEndedReasonDeclinedElsewhere;
                break;
            default:
                endReason = CXCallEndedReasonFailed;
        }
        
        [self.provider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:endReason];
        [self.calls removeObjectForKey:callUUID];
        resolve(@(YES));
    });
}

RCT_EXPORT_METHOD(updateDisplay:(NSString *)callUUID
                  displayName:(NSString *)displayName
                  handle:(NSString *)handle
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXCallUpdate *update = [[CXCallUpdate alloc] init];
        update.localizedCallerName = displayName;
        update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
        
        [self.provider reportCallWithUUID:uuid updated:update];
        resolve(@(YES));
    });
}

RCT_EXPORT_METHOD(checkPermissions:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    // iOS doesn't require specific permissions for CallKit
    resolve(@(YES));
}

RCT_EXPORT_METHOD(checkIsInManagedCall:(RCTPromiseResolveBlock)resolve
                       reject:(RCTPromiseRejectBlock)reject)
{
    resolve(@([self.calls count] > 0));
}

RCT_EXPORT_METHOD(setAvailable:(BOOL)available
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    // Not applicable for iOS
    resolve(@(YES));
}

RCT_EXPORT_METHOD(setCurrentCallActive:(NSString *)callUUID
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callUUID];
        CXCallUpdate *update = [[CXCallUpdate alloc] init];
        [self.provider reportCallWithUUID:uuid updated:update];
        resolve(@(YES));
    });
}

RCT_EXPORT_METHOD(backToForeground:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    resolve(@(YES));
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider
{
    [self sendEventWithName:@"didResetProvider" body:@{}];
    [self.calls removeAllObjects];
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action
{
    [self.provider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:[NSDate date]];
    
    [self sendEventWithName:@"didReceiveStartCallAction" body:@{
        @"callUUID": [action.callUUID UUIDString],
        @"handle": action.handle.value
    }];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
    [self sendEventWithName:@"answerCall" body:@{
        @"callUUID": [action.callUUID UUIDString]
    }];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
    NSString *callUUID = [action.callUUID UUIDString];
    
    [self sendEventWithName:@"endCall" body:@{
        @"callUUID": callUUID
    }];
    
    [self.calls removeObjectForKey:callUUID];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action
{
    [self sendEventWithName:@"didToggleHoldAction" body:@{
        @"callUUID": [action.callUUID UUIDString],
        @"hold": @(action.isOnHold)
    }];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action
{
    [self sendEventWithName:@"didPerformSetMutedCallAction" body:@{
        @"callUUID": [action.callUUID UUIDString],
        @"muted": @(action.isMuted)
    }];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action
{
    [self sendEventWithName:@"didPerformDTMFAction" body:@{
        @"callUUID": [action.callUUID UUIDString],
        @"digits": action.digits
    }];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession
{
    [self sendEventWithName:@"didActivateAudioSession" body:@{}];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession
{
    // Audio session deactivated
}

#pragma mark - Helper Methods

- (CXHandleType)getHandleType:(NSString *)handleType
{
    if ([handleType isEqualToString:@"number"]) {
        return CXHandleTypePhoneNumber;
    } else if ([handleType isEqualToString:@"email"]) {
        return CXHandleTypeEmailAddress;
    }
    return CXHandleTypeGeneric;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeCallKeeperSpecJSI>(params);
}
#endif

@end


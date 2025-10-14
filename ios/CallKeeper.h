#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNCallKeeperSpec.h"

@interface CallKeeper : RCTEventEmitter <NativeCallKeeperSpec>
#else
@interface CallKeeper : RCTEventEmitter <RCTBridgeModule>
#endif

@end


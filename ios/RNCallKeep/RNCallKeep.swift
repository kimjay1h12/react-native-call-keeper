update this on the ios part //
//  RNCallKeep.swift
//  RNCallKeep
//
//  Converted to Swift for React Native CallKeeper
//

import Foundation
import UIKit
import CallKit
import AVFoundation
import React

#if DEBUG
private let OUTGOING_CALL_WAKEUP_DELAY = 10
#else
private let OUTGOING_CALL_WAKEUP_DELAY = 5
#endif

private let RNCallKeepHandleStartCallNotification = "RNCallKeepHandleStartCallNotification"
private let RNCallKeepDidReceiveStartCallAction = "RNCallKeepDidReceiveStartCallAction"
private let RNCallKeepPerformAnswerCallAction = "RNCallKeepPerformAnswerCallAction"
private let RNCallKeepPerformEndCallAction = "RNCallKeepPerformEndCallAction"
private let RNCallKeepDidActivateAudioSession = "RNCallKeepDidActivateAudioSession"
private let RNCallKeepDidDeactivateAudioSession = "RNCallKeepDidDeactivateAudioSession"
private let RNCallKeepDidDisplayIncomingCall = "RNCallKeepDidDisplayIncomingCall"
private let RNCallKeepDidPerformSetMutedCallAction = "RNCallKeepDidPerformSetMutedCallAction"
private let RNCallKeepPerformPlayDTMFCallAction = "RNCallKeepDidPerformDTMFAction"
private let RNCallKeepDidToggleHoldAction = "RNCallKeepDidToggleHoldAction"
private let RNCallKeepProviderReset = "RNCallKeepProviderReset"
private let RNCallKeepCheckReachability = "RNCallKeepCheckReachability"
private let RNCallKeepDidChangeAudioRoute = "RNCallKeepDidChangeAudioRoute"
private let RNCallKeepDidLoadWithEvents = "RNCallKeepDidLoadWithEvents"

@objc(CallKeeper)
class RNCallKeep: RCTEventEmitter, CXProviderDelegate {
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    private var version: OperatingSystemVersion
    private var isStartCallActionEventListenerAdded = false
    private var hasListeners = false
    private var isReachable = false
    private var delayedEvents: NSMutableArray = []
    
    private static var isSetupNatively = false
    private static var sharedProvider: CXProvider?
    
    var callKeepCallController: CXCallController?
    var callKeepProvider: CXProvider?
    
    override init() {
        #if DEBUG
        print("[RNCallKeep][init]")
        #endif
        
        version = ProcessInfo.processInfo.operatingSystemVersion
        super.init()
        
        isStartCallActionEventListenerAdded = false
        isReachable = false
        delayedEvents = NSMutableArray()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        RNCallKeep.initCallKitProvider()
        callKeepProvider = RNCallKeep.sharedProvider
        callKeepProvider?.setDelegate(self, queue: nil)
    }
    
    deinit {
        #if DEBUG
        print("[RNCallKeep][dealloc]")
        #endif
        
        NotificationCenter.default.removeObserver(self)
        callKeepProvider?.invalidate()
        RNCallKeep.sharedProvider = nil
        isReachable = false
    }
    
    override func supportedEvents() -> [String]! {
        return [
            // Legacy RNCallKeep event names
            RNCallKeepDidReceiveStartCallAction,
            RNCallKeepPerformAnswerCallAction,
            RNCallKeepPerformEndCallAction,
            RNCallKeepDidActivateAudioSession,
            RNCallKeepDidDeactivateAudioSession,
            RNCallKeepDidDisplayIncomingCall,
            RNCallKeepDidPerformSetMutedCallAction,
            RNCallKeepPerformPlayDTMFCallAction,
            RNCallKeepDidToggleHoldAction,
            RNCallKeepProviderReset,
            RNCallKeepCheckReachability,
            RNCallKeepDidLoadWithEvents,
            RNCallKeepDidChangeAudioRoute,
            // Simplified event names for compatibility
            "didReceiveStartCallAction",
            "answerCall",
            "endCall",
            "didActivateAudioSession",
            "didDisplayIncomingCall",
            "didPerformSetMutedCallAction",
            "didToggleHoldAction",
            "didPerformDTMFAction",
            "didLoadWithEvents",
            "checkReachability",
            "didResetProvider"
        ]
    }
    
    override func startObserving() {
        print("[RNCallKeep][startObserving]")
        hasListeners = true
        if delayedEvents.count > 0 {
            sendEvent(withName: RNCallKeepDidLoadWithEvents, body: delayedEvents)
        }
    }
    
    override func stopObserving() {
        hasListeners = false
        
        // Fix for listener count sync
        do {
            try setValue(0, forKey: "_listenerCount")
        } catch {
            print("[RNCallKeep][stopObserving] exception: \(error)")
        }
    }
    
    @objc func onAudioRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? NSNumber else {
            return
        }
        
        let reason = reasonValue.intValue
        let output = RNCallKeep.getAudioOutput()
        
        guard let output = output else { return }
        
        sendEvent(withName: RNCallKeepDidChangeAudioRoute, body: [
            "output": output,
            "reason": reason
        ])
    }
    
    func sendEventWithNameWrapper(_ name: String, body: Any?) {
        print("[RNCallKeep] sendEventWithNameWrapper: \(name), hasListeners: \(hasListeners)")
        
        if hasListeners {
            sendEvent(withName: name, body: body)
        } else {
            let dictionary: [String: Any] = [
                "name": name,
                "data": body ?? NSNull()
            ]
            delayedEvents.add(dictionary)
        }
    }
    
    static func getSettings() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: "RNCallKeepSettings")
    }
    
    static func initCallKitProvider() {
        if sharedProvider == nil {
            let settings = getSettings()
            if let settings = settings, settings["appName"] != nil {
                sharedProvider = CXProvider(configuration: getProviderConfiguration(settings))
            }
        }
    }
    
    static func getAudioOutput() -> String? {
        do {
            let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
            if !outputs.isEmpty {
                return outputs[0].portType.rawValue
            }
        } catch {
            print("getAudioOutput error: \(error)")
        }
        return nil
    }
    
    static func getProviderConfiguration(_ settings: [String: Any]) -> CXProviderConfiguration {
        let appName = settings["appName"] as? String ?? "App"
        
        let configuration: CXProviderConfiguration
        if #available(iOS 14.0, *) {
            configuration = CXProviderConfiguration(localizedName: appName)
        } else {
            configuration = CXProviderConfiguration()
            // On older iOS versions, `localizedName` may be get-only; avoid assigning directly.
        }
        
        // Use `intValue` to match the `Int`-typed properties on CXProviderConfiguration
        if let maxGroupsNumber = settings["maximumCallGroups"] as? NSNumber {
            configuration.maximumCallGroups = maxGroupsNumber.intValue
        } else {
            configuration.maximumCallGroups = 1
        }
        
        if let maxPerGroupNumber = settings["maximumCallsPerCallGroup"] as? NSNumber {
            configuration.maximumCallsPerCallGroup = maxPerGroupNumber.intValue
        } else {
            configuration.maximumCallsPerCallGroup = 1
        }
        
        configuration.supportsVideo = (settings["supportsVideo"] as? NSNumber)?.boolValue ?? false
        configuration.includesCallsInRecents = (settings["includesCallsInRecents"] as? NSNumber)?.boolValue ?? false
        
        if let imageName = settings["imageName"] as? String {
            configuration.iconTemplateImageData = UIImage(named: imageName)?.pngData()
        }
        
        if let ringtoneSound = settings["ringtoneSound"] as? String {
            configuration.ringtoneSound = ringtoneSound
        }
        
        return configuration
    }
    
    static func getHandleType(_ handleType: String?) -> CXHandle.HandleType {
        guard let handleType = handleType else { return .generic }
        
        switch handleType.lowercased() {
        case "number":
            return .phoneNumber
        case "email":
            return .emailAddress
        default:
            return .generic
        }
    }
    
    // MARK: - Setup Methods
    
    @objc func setup(_ options: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try setupInternal(options)
            resolve(nil)
        } catch {
            reject("setup_error", error.localizedDescription, error)
        }
    }
    
    private func setupInternal(_ options: [String: Any]) throws {
        if RNCallKeep.isSetupNatively {
            #if DEBUG
            print("[RNCallKeep][setup] already setup")
            #endif
            return
        }
        
        #if DEBUG
        print("[RNCallKeep][setup] options = \(options)")
        #endif
        
        version = ProcessInfo.processInfo.operatingSystemVersion
        callKeepCallController = CXCallController()
        
        setSettings(options)
        RNCallKeep.initCallKitProvider()
        
        callKeepProvider = RNCallKeep.sharedProvider
        callKeepProvider?.setDelegate(self, queue: nil)
    }
    
    @objc func setSettings(_ options: [String: Any]) {
        #if DEBUG
        print("[RNCallKeep][setSettings] options = \(options)")
        #endif
        
        let settings = NSMutableDictionary(dictionary: options)
        UserDefaults.standard.set(settings, forKey: "RNCallKeepSettings")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Call Management Methods
    
    @objc func displayIncomingCall(
        _ callUUID: String,
        handle: String,
        localizedCallerName: String?,
        handleType: String?,
        hasVideo: NSNumber?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        do {
            let hasVideoBool = hasVideo?.boolValue ?? false
            let safeHandleType = handleType ?? "generic"
            let safeCallerName = localizedCallerName ?? handle
            
            try displayIncomingCallInternal(
                callUUID,
                handle: handle,
                handleType: safeHandleType,
                hasVideo: hasVideoBool,
                localizedCallerName: safeCallerName,
                supportsHolding: true,
                supportsDTMF: true,
                supportsGrouping: true,
                supportsUngrouping: true
            )
            resolve(nil)
        } catch {
            reject("incoming_call_error", error.localizedDescription, error)
        }
    }
    
    private func displayIncomingCallInternal(
        _ uuidString: String,
        handle: String,
        handleType: String,
        hasVideo: Bool,
        localizedCallerName: String?,
        supportsHolding: Bool,
        supportsDTMF: Bool,
        supportsGrouping: Bool,
        supportsUngrouping: Bool
    ) throws {
        RNCallKeep.reportNewIncomingCall(
            uuidString,
            handle: handle,
            handleType: handleType,
            hasVideo: hasVideo,
            localizedCallerName: localizedCallerName,
            supportsHolding: supportsHolding,
            supportsDTMF: supportsDTMF,
            supportsGrouping: supportsGrouping,
            supportsUngrouping: supportsUngrouping,
            fromPushKit: false,
            payload: nil,
            withCompletionHandler: nil
        )
        
        let settings = RNCallKeep.getSettings()
        if let timeout = settings?["displayCallReachabilityTimeout"] as? NSNumber {
            let delay = DispatchTime.now() + DispatchTimeInterval.milliseconds(timeout.intValue)
            DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
                guard let self = self else { return }
                if !self.isReachable {
                    #if DEBUG
                    print("[RNCallKeep]Displayed a call without a reachable app, ending the call: \(uuidString)")
                    #endif
                    RNCallKeep.endCallWithUUID(uuidString, reason: 1)
                }
            }
        }
    }
    
    @objc func startCall(
        _ callUUID: String,
        handle: String,
        contactIdentifier: String?,
        handleType: String?,
        hasVideo: NSNumber?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        do {
            let hasVideoBool = hasVideo?.boolValue ?? false
            let safeHandleType = handleType ?? "generic"
            let safeContactId = contactIdentifier ?? handle
            
            try startCallInternal(
                callUUID,
                handle: handle,
                contactIdentifier: safeContactId,
                handleType: safeHandleType,
                video: hasVideoBool
            )
            resolve(nil)
        } catch {
            reject("start_call_error", error.localizedDescription, error)
        }
    }
    
    private func startCallInternal(
        _ uuidString: String,
        handle: String,
        contactIdentifier: String?,
        handleType: String,
        video: Bool
    ) throws {
        #if DEBUG
        print("[RNCallKeep][startCall] uuidString = \(uuidString)")
        #endif
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "RNCallKeep", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID"])
        }
        
        let handleTypeEnum = RNCallKeep.getHandleType(handleType)
        let callHandle = CXHandle(type: handleTypeEnum, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        startCallAction.isVideo = video
        startCallAction.contactIdentifier = contactIdentifier
        
        let transaction = CXTransaction(action: startCallAction)
        requestTransaction(transaction)
    }
    
    @objc func endCall(_ callUUID: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try endCallInternal(callUUID)
            resolve(nil)
        } catch {
            reject("end_call_error", error.localizedDescription, error)
        }
    }
    
    private func endCallInternal(_ uuidString: String) throws {
        #if DEBUG
        print("[RNCallKeep][endCall] uuidString = \(uuidString)")
        #endif
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "RNCallKeep", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID"])
        }
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        requestTransaction(transaction)
    }
    
    @objc func endAllCalls(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try endAllCallsInternal()
            resolve(nil)
        } catch {
            reject("end_all_calls_error", error.localizedDescription, error)
        }
    }
    
    private func endAllCallsInternal() throws {
        #if DEBUG
        print("[RNCallKeep][endAllCalls]")
        #endif
        
        guard let callController = callKeepCallController else { return }
        
        for call in callController.callObserver.calls {
            let endCallAction = CXEndCallAction(call: call.uuid)
            let transaction = CXTransaction(action: endCallAction)
            requestTransaction(transaction)
        }
    }
    
    @objc func answerIncomingCall(_ callUUID: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try answerIncomingCallInternal(callUUID)
            resolve(nil)
        } catch {
            reject("answer_call_error", error.localizedDescription, error)
        }
    }
    
    private func answerIncomingCallInternal(_ uuidString: String) throws {
        #if DEBUG
        print("[RNCallKeep][answerIncomingCall] uuidString = \(uuidString)")
        #endif
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "RNCallKeep", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID"])
        }
        
        let answerCallAction = CXAnswerCallAction(call: uuid)
        let transaction = CXTransaction(action: answerCallAction)
        requestTransaction(transaction)
    }
    
    @objc func rejectCall(_ callUUID: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        endCall(callUUID, resolve: resolve, reject: reject)
    }
    
    @objc func setMutedCall(_ callUUID: String, muted: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try setMutedCallInternal(callUUID, muted: muted.boolValue)
            resolve(nil)
        } catch {
            reject("mute_call_error", error.localizedDescription, error)
        }
    }
    
    private func setMutedCallInternal(_ uuidString: String, muted: Bool) throws {
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "RNCallKeep", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID"])
        }
        
        let setMutedCallAction = CXSetMutedCallAction(call: uuid, muted: muted)
        let transaction = CXTransaction(action: setMutedCallAction)
        requestTransaction(transaction)
    }
    
    @objc func setOnHold(_ callUUID: String, onHold: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try setOnHoldInternal(callUUID, shouldHold: onHold.boolValue)
            resolve(nil)
        } catch {
            reject("hold_call_error", error.localizedDescription, error)
        }
    }
    
    private func setOnHoldInternal(_ uuidString: String, shouldHold: Bool) throws {
        #if DEBUG
        print("[RNCallKeep][setOnHold] uuidString = \(uuidString), shouldHold = \(shouldHold)")
        #endif
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "RNCallKeep", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID"])
        }
        
        let setHeldCallAction = CXSetHeldCallAction(call: uuid, onHold: shouldHold)
        let transaction = CXTransaction(action: setHeldCallAction)
        requestTransaction(transaction)
    }
    
    @objc func reportConnectedOutgoingCall(_ callUUID: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let uuid = UUID(uuidString: callUUID) else {
            reject("invalid_uuid", "Invalid UUID", nil)
            return
        }
        
        callKeepProvider?.reportOutgoingCall(with: uuid, connectedAt: Date())
        resolve(nil)
    }
    
    @objc func reportEndCallWithUUID(_ callUUID: String, reason: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        RNCallKeep.endCallWithUUID(callUUID, reason: reason.intValue)
        resolve(nil)
    }
    
    @objc func updateDisplay(_ callUUID: String, displayName: String, handle: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // Update display is handled by CallKit automatically
        resolve(nil)
    }
    
    @objc func checkPermissions(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // On iOS, CallKit permissions are always granted
        resolve(true)
    }
    
    @objc func checkIsInManagedCall(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let hasActiveCalls = callKeepCallController?.callObserver.calls.count ?? 0 > 0
        resolve(hasActiveCalls)
    }
    
    @objc func setAvailable(_ available: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // iOS doesn't need availability setting for CallKit
        resolve(nil)
    }
    
    @objc func setCurrentCallActive(_ callUUID: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // This is handled automatically by CallKit
        resolve(nil)
    }
    
    @objc func backToForeground(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.view.window?.makeKeyAndVisible()
            }
        }
        resolve(nil)
    }
    
    // MARK: - Helper Methods
    
    private func requestTransaction(_ transaction: CXTransaction) {
        callKeepCallController?.request(transaction) { error in
            if let error = error {
                print("[RNCallKeep] Error requesting transaction: \(error)")
            }
        }
    }
    
    // MARK: - Static Methods
    
    static func reportNewIncomingCall(
        _ uuidString: String,
        handle: String,
        handleType: String,
        hasVideo: Bool,
        localizedCallerName: String?,
        supportsHolding: Bool,
        supportsDTMF: Bool,
        supportsGrouping: Bool,
        supportsUngrouping: Bool,
        fromPushKit: Bool,
        payload: [String: Any]?,
        withCompletionHandler completion: (() -> Void)?
    ) {
        guard let uuid = UUID(uuidString: uuidString) else { return }
        
        let handleTypeEnum = getHandleType(handleType)
        let callHandle = CXHandle(type: handleTypeEnum, value: handle)
        
        let update = CXCallUpdate()
        update.remoteHandle = callHandle
        update.localizedCallerName = localizedCallerName
        update.hasVideo = hasVideo
        update.supportsHolding = supportsHolding
        update.supportsDTMF = supportsDTMF
        update.supportsGrouping = supportsGrouping
        update.supportsUngrouping = supportsUngrouping
        
        sharedProvider?.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("[RNCallKeep] Error reporting incoming call: \(error)")
            } else {
                completion?()
            }
        }
    }
    
    static func endCallWithUUID(_ uuidString: String, reason: Int) {
        guard let uuid = UUID(uuidString: uuidString) else { return }
        
        let endCallReason: CXCallEndedReason
        switch reason {
        case 1:
            endCallReason = .failed
        case 2:
            endCallReason = .remoteEnded
        case 3:
            endCallReason = .unanswered
        case 4:
            endCallReason = .answeredElsewhere
        case 5:
            endCallReason = .declinedElsewhere
        case 6:
            endCallReason = .unanswered
        default:
            endCallReason = .failed
        }
        
        sharedProvider?.reportCall(with: uuid, endedAt: Date(), reason: endCallReason)
    }
    
    static func isCallActive(_ uuidString: String) -> Bool {
        guard let uuid = UUID(uuidString: uuidString) else { return false }
        // This would need access to call observer - simplified for now
        return false
    }
    
    // MARK: - CXProviderDelegate
    
    func providerDidReset(_ provider: CXProvider) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][providerDidReset]")
        #endif
        
        sendEventWithNameWrapper(RNCallKeepProviderReset, body: nil)
        sendEventWithNameWrapper("didResetProvider", body: nil)
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:performStartCallAction]")
        #endif
        
        let body: [String: Any] = [
            "callUUID": action.callUUID.uuidString.lowercased(),
            "handle": action.handle.value
        ]
        
        sendEventWithNameWrapper(RNCallKeepDidReceiveStartCallAction, body: body)
        sendEventWithNameWrapper("didReceiveStartCallAction", body: body)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:performAnswerCallAction]")
        #endif
        
        let body: [String: Any] = [
            "callUUID": action.callUUID.uuidString.lowercased()
        ]
        
        sendEventWithNameWrapper(RNCallKeepPerformAnswerCallAction, body: body)
        sendEventWithNameWrapper("answerCall", body: body)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:performEndCallAction]")
        #endif
        
        let body: [String: Any] = [
            "callUUID": action.callUUID.uuidString.lowercased()
        ]
        
        sendEventWithNameWrapper(RNCallKeepPerformEndCallAction, body: body)
        sendEventWithNameWrapper("endCall", body: body)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:performSetHeldCallAction]")
        #endif
        
        let body: [String: Any] = [
            "callUUID": action.callUUID.uuidString.lowercased(),
            "hold": action.isOnHold
        ]
        
        sendEventWithNameWrapper(RNCallKeepDidToggleHoldAction, body: body)
        sendEventWithNameWrapper("didToggleHoldAction", body: body)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:performPlayDTMFCallAction]")
        #endif
        
        let body: [String: Any] = [
            "digits": action.digits,
            "callUUID": action.callUUID.uuidString.lowercased()
        ]
        
        sendEventWithNameWrapper(RNCallKeepPerformPlayDTMFCallAction, body: body)
        sendEventWithNameWrapper("didPerformDTMFAction", body: body)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:performSetMutedCallAction]")
        #endif
        
        let body: [String: Any] = [
            "muted": action.isMuted,
            "callUUID": action.callUUID.uuidString.lowercased()
        ]
        
        sendEventWithNameWrapper(RNCallKeepDidPerformSetMutedCallAction, body: body)
        sendEventWithNameWrapper("didPerformSetMutedCallAction", body: body)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:didActivateAudioSession]")
        #endif
        
        configureAudioSession()
        sendEventWithNameWrapper(RNCallKeepDidActivateAudioSession, body: nil)
        sendEventWithNameWrapper("didActivateAudioSession", body: nil)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        #if DEBUG
        print("[RNCallKeep][CXProviderDelegate][provider:didDeactivateAudioSession]")
        #endif
        
        sendEventWithNameWrapper(RNCallKeepDidDeactivateAudioSession, body: nil)
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("[RNCallKeep] Error configuring audio session: \(error)")
        }
    }
}


//
//  KeyboardAvoiding.swift
//  TalentLMSCoreApplication
//
//  Created by Manolis Katsifarakis on 26/02/2019.
//  Copyright © 2019 Epignosis UK Limited. All rights reserved.
//

import UIKit

class KeyboardAvoidingScrollView: UIScrollView, KeyboardAvoidingProtocol {
    fileprivate lazy var keyboardAvoiding = KeyboardAvoiding(scrollView: self)
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        keyboardAvoiding.didMoveToWindow(window)
    }
    
    static func KeyboardAvoidingInputAccessoryView(_ inputAccessoryView: UIView?) -> UIView? {
        return KeyboardTrackingView
            .inputAccessoryViewWithTracking(currentView: inputAccessoryView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        keyboardAvoiding.avoidKeyboard()
    }
}

class KeyboardAvoidingTableView: UITableView, KeyboardAvoidingProtocol {
    fileprivate lazy var keyboardAvoiding = KeyboardAvoiding(scrollView: self)
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        keyboardAvoiding.didMoveToWindow(window)
    }
    
    static func KeyboardAvoidingInputAccessoryView(_ inputAccessoryView: UIView?) -> UIView? {
        return KeyboardTrackingView
            .inputAccessoryViewWithTracking(currentView: inputAccessoryView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        keyboardAvoiding.avoidKeyboard()
    }
}

fileprivate class KeyboardAvoiding {
    enum KeyboardState: Int {
        case willShow
        case didShow
        case willHide
        case didHide
    }
    
    var keyboardState = KeyboardState.didHide
    
    private var keyboardCenterObservation: NSKeyValueObservation?
    private weak var scrollView: UIScrollView?
    
    private var isFirstResponderContainedInScrollView = false
    private var isInitialized: Bool = false
    
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }
    
    private init() {}
    
    private var isReloadingInputViews = false
    
    func didMoveToWindow(_ window: UIWindow?) {
        guard let _ = window else {
            stop()
            return
        }
        
        initialize()
    }
    
    func avoidKeyboard() {
        if isFirstResponderContainedInScrollView && keyboardState.rawValue <= KeyboardState.didShow.rawValue {
            return
        }
        
        guard
            let scrollView = scrollView,
            let keyboardContainer = KeyboardTrackingView.default.keyboardContainer,
            let keyboardOrigin = keyboardContainer.superview?
                .convert(keyboardContainer.frame.origin, to: scrollView.superview)
            else
        {
            return
        }
        
        let bottom = max(0, scrollView.frame.maxY - keyboardOrigin.y)
        
        scrollView.contentInset.bottom = bottom
        scrollView.scrollIndicatorInsets.bottom = bottom
    }
    
    var previousNotificationUserInfo: [AnyHashable : Any]?
}

private extension KeyboardAvoiding {
    func initialize() {
        if isInitialized {
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        start()
        
        isInitialized = true
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardState = .willShow
        guard let _ = scrollView, !isReloadingInputViews else { return }
        
        UIResponder.findCurrentFirstResponder()
        guard let currentFR = UIResponder.currentFirstResponder() as? UIView else {
            return
        }
        
        isFirstResponderContainedInScrollView = isViewContainedInScrollView(view: currentFR)
        if !isFirstResponderContainedInScrollView {
            // First responder is NOT contained in ScrollView.
            // Means we need a tracking view because its probably inside an input accessory view.
            addTrackingViewToFirstResponder(currentFR)
        } else {
            // First responder IS contained in ScrollView.
            // We just perform all animations right away.
            if areEndFramesEqual(notification.userInfo) {
                previousNotificationUserInfo = nil
                return
            }

            previousNotificationUserInfo = notification.userInfo
            updateScrollViewInsetsAndOffset(notification: notification)
        }
    }
    
    func areEndFramesEqual(_ userInfo: [AnyHashable : Any]?) -> Bool {
        if userInfo == nil && previousNotificationUserInfo == nil {
            return true
        }
        
        guard let userInfo = userInfo,
            let previousNotificationUserInfo = previousNotificationUserInfo else
        {
            return false
        }
        
        guard let frameEnd = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect,
            let frameEndPr = previousNotificationUserInfo[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect,
            frameEnd == frameEndPr else {
            return false
        }
        
        return true
    }
    
    @objc func keyboardDidShow(_ notification: Notification) {
        keyboardState = .didShow
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardState = .willHide
        UIResponder.resetCurrentFirstResponder()
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        if isFirstResponderContainedInScrollView, let scrollView = scrollView {
//            let (duration, curveAnimationOption) = animationDurationAndCurveFromNotification(notification)
//            UIView.animate(
//                withDuration: duration,
//                delay: 0,
//                options: [ curveAnimationOption ],
//                animations: {
                    scrollView.contentInset.bottom = 0
                    scrollView.scrollIndicatorInsets.bottom = 0
//            })
        }
        
        if !areEndFramesEqual(notification.userInfo) {
            previousNotificationUserInfo = nil
        }
        
        keyboardState = .didHide
        UIResponder.resetCurrentFirstResponder()
    }
    
    func animationDurationAndCurveFromNotification(_ notification: Notification)
        -> (TimeInterval, UIView.AnimationOptions) {
        let duration = notification.userInfo?[UIWindow.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            ?? 0.3
        var curveAnimationOption = UIView.AnimationOptions.curveEaseInOut
        if let curve = notification.userInfo?[UIWindow.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let curveUInt = UInt(truncating: curve)
            curveAnimationOption = UIView.AnimationOptions(rawValue: curveUInt<<16)
        }

        return (duration, curveAnimationOption)
    }
    
    func isViewContainedInScrollView(view: UIView) -> Bool{
        guard let scrollView = scrollView else { return false }
        var superview = view.superview
        while superview != nil {
            if superview == scrollView {
                return true
            }
            
            superview = superview?.superview
        }
        
        return false
    }
    
    func addTrackingViewToFirstResponder(_ currentFR: UIView?) {
        if let currentFR = currentFR as? UITextField {
            currentFR.inputAccessoryView = KeyboardTrackingView
                .inputAccessoryViewWithTracking(currentView: currentFR.inputAccessoryView)
        } else if let currentFR = currentFR as? UITextView {
            currentFR.inputAccessoryView = KeyboardTrackingView
                .inputAccessoryViewWithTracking(currentView: currentFR.inputAccessoryView)
        } else {
            return
        }
        
        isReloadingInputViews = true
        currentFR?.reloadInputViews()
        isReloadingInputViews = false
    }
    
    func updateScrollViewInsetsAndOffset(notification: Notification) {
        guard let scrollView = scrollView,
            let currentFR = UIResponder.currentFirstResponder() as? UIView,
            let keyboardFrame = notification.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                return
        }
        
        let bottom = max(0, scrollView.frame.maxY - keyboardFrame.origin.y)
        
        var frOriginInScrollView = scrollView.convert(currentFR.frame.origin, from: currentFR.superview)
        frOriginInScrollView.x = scrollView.contentOffset.x
        frOriginInScrollView.y -= keyboardFrame.size.height
        
//        let (duration, curveAnimationOption) = animationDurationAndCurveFromNotification(notification)
//        UIView.animate(
//            withDuration: duration,
//            delay: 0,
//            options: [ curveAnimationOption ],
//            animations: {
                scrollView.contentInset.bottom = bottom
                scrollView.scrollIndicatorInsets.bottom = bottom
                scrollView.setContentOffset(frOriginInScrollView, animated: false)
//        })
    }
    
    func start() {
        KeyboardTrackingView.default.wasAddedToView = { [weak self] in
            self?.startObservingTrackingView()
        }
    }
    
    func startObservingTrackingView() {
        guard
            let _ = scrollView,
            let keyboardContainer = KeyboardTrackingView.default.keyboardContainer,
            keyboardCenterObservation == nil
            else
        {
            return
        }
        
        keyboardCenterObservation = keyboardContainer.observe(\.center as KeyPath<UIView, CGPoint>, options: [ ])
        { [weak self] _, _ in
            self?.avoidKeyboard()
        }
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self)
        if let keyboardCenterObservation = keyboardCenterObservation {
            keyboardCenterObservation.invalidate()
            self.keyboardCenterObservation = nil
        }
        
        KeyboardTrackingView.default.removeFromSuperview()
    }
}

fileprivate protocol KeyboardAvoidingProtocol where Self : UIScrollView {
    var keyboardAvoiding: KeyboardAvoiding { get }
}

fileprivate class KeyboardTrackingView: UIView {
    var wasAddedToView: (() -> ())? = nil
    var isInputAccessoryView = false
    
    static var `default`: KeyboardTrackingView = {
        let defaultView = KeyboardTrackingView()
        return defaultView
    } ()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let _ = superview {
            wasAddedToView?()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let _ = superview {
            wasAddedToView?()
        }
    }
    
    var keyboardContainer: UIView? {
        return !isInputAccessoryView
            ? superview?.superview
            : superview
    }
    
    static func inputAccessoryViewWithTracking(currentView: UIView?) -> UIView? {
        guard let currentView = currentView else {
            KeyboardTrackingView.default.isInputAccessoryView = true
            return KeyboardTrackingView.default
        }
        
        if currentView != KeyboardTrackingView.default {
            KeyboardTrackingView.default.isInputAccessoryView = false
            currentView.addSubview(KeyboardTrackingView.default)
        } else {
            KeyboardTrackingView.default.isInputAccessoryView = true
        }
        
        return currentView
    }
}

fileprivate extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder?
    private static var hasSwizzledMethods = false
    
    static func resetCurrentFirstResponder() {
        _currentFirstResponder = nil
    }
    
    static func currentFirstResponder() -> UIResponder? {
        return _currentFirstResponder
    }
    
    static func findCurrentFirstResponder() {
        UIApplication.shared.sendAction(#selector(findFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @objc private func findFirstResponder() {
        UIResponder._currentFirstResponder = self
    }
}

//
//  KeyboardAvoiding.swift
//
//  Copyright © 2019 Manolis Katsifarakis All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

// MARK: - Keyboard avoiding sub-classes
open class KeyboardAvoidingScrollView: UIScrollView, KeyboardAvoidingProtocol {
    fileprivate lazy var keyboardAvoiding = KeyboardAvoiding(scrollView: self)
    
    @IBInspectable var viewToAvoidKeyboardSpacing: CGFloat = KeyboardAvoiding.VIEW_TO_AVOID_KEYBOARD_SPACING {
        didSet {
            keyboardAvoiding.viewToAvoidKeyboardSpacing = viewToAvoidKeyboardSpacing
        }
    }
    
    @IBInspectable var textViewCursorSpacing: CGFloat = KeyboardAvoiding.TEXTVIEW_CURSOR_SPACING {
        didSet {
            keyboardAvoiding.textViewCursorSpacing = textViewCursorSpacing
        }
    }
    
    @IBInspectable var shouldTrackTextViewCursor: Bool = true {
        didSet {
            keyboardAvoiding.shouldTrackTextViewCursor = shouldTrackTextViewCursor
        }
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        keyboardAvoiding.didMoveToWindow(window)
    }
    
    static func KeyboardAvoidingInputAccessoryView(_ inputAccessoryView: UIView?) -> UIView? {
        return KeyboardTrackingView
            .inputAccessoryViewWithTracking(currentView: inputAccessoryView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        keyboardAvoiding.avoidKeyboard()
    }
}

open class KeyboardAvoidingTableView: UITableView, KeyboardAvoidingProtocol {
    fileprivate lazy var keyboardAvoiding = KeyboardAvoiding(scrollView: self)
    
    @IBInspectable var viewToAvoidKeyboardSpacing: CGFloat = KeyboardAvoiding.VIEW_TO_AVOID_KEYBOARD_SPACING {
        didSet {
            keyboardAvoiding.viewToAvoidKeyboardSpacing = viewToAvoidKeyboardSpacing
        }
    }
    
    @IBInspectable var textViewCursorSpacing: CGFloat = KeyboardAvoiding.TEXTVIEW_CURSOR_SPACING {
        didSet {
            keyboardAvoiding.textViewCursorSpacing = textViewCursorSpacing
        }
    }
    
    @IBInspectable var shouldTrackTextViewCursor: Bool = true {
        didSet {
            keyboardAvoiding.shouldTrackTextViewCursor = shouldTrackTextViewCursor
        }
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        keyboardAvoiding.didMoveToWindow(window)
    }
    
    static func KeyboardAvoidingInputAccessoryView(_ inputAccessoryView: UIView?) -> UIView? {
        return KeyboardTrackingView
            .inputAccessoryViewWithTracking(currentView: inputAccessoryView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        keyboardAvoiding.avoidKeyboard()
    }
}

open class KeyboardAvoidingCollectionView: UICollectionView, KeyboardAvoidingProtocol {
    fileprivate lazy var keyboardAvoiding = KeyboardAvoiding(scrollView: self)
    
    @IBInspectable var viewToAvoidKeyboardSpacing: CGFloat = KeyboardAvoiding.VIEW_TO_AVOID_KEYBOARD_SPACING {
        didSet {
            keyboardAvoiding.viewToAvoidKeyboardSpacing = viewToAvoidKeyboardSpacing
        }
    }
    
    @IBInspectable var textViewCursorSpacing: CGFloat = KeyboardAvoiding.TEXTVIEW_CURSOR_SPACING {
        didSet {
            keyboardAvoiding.textViewCursorSpacing = textViewCursorSpacing
        }
    }
    
    @IBInspectable var shouldTrackTextViewCursor: Bool = true {
        didSet {
            keyboardAvoiding.shouldTrackTextViewCursor = shouldTrackTextViewCursor
        }
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        keyboardAvoiding.didMoveToWindow(window)
    }
    
    static func KeyboardAvoidingInputAccessoryView(_ inputAccessoryView: UIView?) -> UIView? {
        return KeyboardTrackingView
            .inputAccessoryViewWithTracking(currentView: inputAccessoryView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        keyboardAvoiding.avoidKeyboard()
    }
}

// MARK: - KeyboardAvoiding extensions for Text views
extension UITextField: KeyboardAvoidingView {
    @IBOutlet public weak var viewToAvoid: UIView? {
        get {
            return retrieveAvoidingView(key: &_KeyboarAvoiding_ViewToAvoidKey)
        }
        
        set {
            storeAvoidingView(newValue, key: &_KeyboarAvoiding_ViewToAvoidKey)
        }
    }
}

extension UITextView: KeyboardAvoidingView {
    @IBOutlet public weak var viewToAvoid: UIView? {
        get {
            return retrieveAvoidingView(key: &_KeyboarAvoiding_ViewToAvoidKey)
        }
        
        set {
            storeAvoidingView(newValue, key: &_KeyboarAvoiding_ViewToAvoidKey)
        }
    }
}

// MARK: - KeyboardAvoiding main class
private class KeyboardAvoiding {
    enum KeyboardState: Int {
        case willShow
        case didShow
        case willHide
        case didHide
    }
    
    // Space between the keyboard and the specified element to avoid.
    static let VIEW_TO_AVOID_KEYBOARD_SPACING: CGFloat = 0
    static let TEXTVIEW_CURSOR_SPACING: CGFloat = 5.0
    
    var keyboardState = KeyboardState.didHide
    
    var viewToAvoidKeyboardSpacing: CGFloat = VIEW_TO_AVOID_KEYBOARD_SPACING
    var textViewCursorSpacing: CGFloat = TEXTVIEW_CURSOR_SPACING
    var shouldTrackTextViewCursor: Bool = true
    
    private var keyboardCenterObservation: NSKeyValueObservation?
    
    private weak var scrollView: UIScrollView?
    
    private var originalContentInset: UIEdgeInsets = UIEdgeInsets.zero
    
    private var isFirstResponderContainedInScrollView = false
    private var isInitialized: Bool = false
    
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.originalContentInset = scrollView.contentInset
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
}

private extension KeyboardAvoiding {
    // MARK: - Lifecycle
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
        
        keyboardCenterObservation = keyboardContainer.observe(\.center as KeyPath<UIView, CGPoint>, options: [ ]) { [weak self] _, _ in
            self?.avoidKeyboard()
        }
        
        avoidKeyboard()
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self)
        if let keyboardCenterObservation = keyboardCenterObservation {
            keyboardCenterObservation.invalidate()
        }
        
        keyboardCenterObservation = nil
        
        KeyboardTrackingView.default.removeFromSuperview()
    }
    
    // MARK: - Keyboard handling
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardState = .willShow
        guard let scrollView = scrollView, !isReloadingInputViews else { return }
        
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
            if let keys = scrollView.layer.animationKeys(), keys.contains("bounds.size") {
                return
            }
            
            updateScrollViewInsetsAndOffset(notification: notification)
        }
    }
    
    @objc func keyboardDidShow(_ notification: Notification) {
        keyboardState = .didShow
        guard let scrollView = scrollView, isFirstResponderContainedInScrollView else { return }
        
        let viewToAvoid: UIView? = (UIResponder.currentFirstResponder() as? UITextField) != nil
            ? (UIResponder.currentFirstResponder() as? UITextField)?.viewToAvoid
            : (UIResponder.currentFirstResponder() as? UITextView)?.viewToAvoid
        
        if let viewToAvoid = viewToAvoid,
            isViewContainedInScrollView(view: viewToAvoid),
            let superview = viewToAvoid.superview {
            // Extra view to avoid
            let maxPoint = CGPoint(x: 0, y: viewToAvoid.frame.maxY)
            let viewToAvoidInScrollView = scrollView.convert(maxPoint, from: superview)
            scrollBelowY(viewToAvoidInScrollView.y + viewToAvoidKeyboardSpacing)
            return
        } else if shouldTrackTextViewCursor,
            let textView = UIResponder.currentFirstResponder() as? UITextView {
            // UITextView
            scrollBelowTextViewCursor(textView)
            NotificationCenter.default.addObserver(
                self, selector: #selector(scrollBelowTextViewCursorFromNotification(_:)),
                name: UITextView.textDidChangeNotification, object: textView
            )
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardState = .willHide
        UIResponder.resetCurrentFirstResponder()
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        //        if isFirstResponderContainedInScrollView, let scrollView = scrollView {
        //            scrollView.contentInset.bottom = 0
        //            scrollView.scrollIndicatorInsets.bottom = 0
        //        }
        scrollView?.contentInset = originalContentInset
        
        keyboardState = .didHide
        UIResponder.resetCurrentFirstResponder()
        
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
    }
    
    // MARK: - Util
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
    
    func isViewContainedInScrollView(view: UIView) -> Bool {
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
        if !(currentFR is UITextField || currentFR is UITextView) {
            return
        }
        
        if let inputAccessoryViewController = currentFR?.inputAccessoryViewController {
            KeyboardTrackingView.addTrackingToView(inputAccessoryViewController.view)
        } else {
            if let currentFR = currentFR as? UITextField {
                currentFR.inputAccessoryView = KeyboardTrackingView
                    .inputAccessoryViewWithTracking(currentView: currentFR.inputAccessoryView)
            } else if let currentFR = currentFR as? UITextView {
                currentFR.inputAccessoryView = KeyboardTrackingView
                    .inputAccessoryViewWithTracking(currentView: currentFR.inputAccessoryView)
            }
            
            isReloadingInputViews = true
            currentFR?.reloadInputViews()
            isReloadingInputViews = false
        }
    }
    
    // MARK: - ScrollView
    func scrollBelowY(_ y: CGFloat) {
        guard let scrollView = scrollView else { return }
        
        let scrollViewVisibleHeight = scrollView.bounds.size.height - scrollView.contentInset.bottom
        let scrollViewMaxVisibleY = scrollView.contentOffset.y + scrollViewVisibleHeight
        if y > scrollView.contentOffset.y && y < scrollViewMaxVisibleY {
            return
        }
        
        let scrollOffset = y - scrollViewVisibleHeight
        DispatchQueue.main.async {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: scrollOffset), animated: true)
        }
    }
    
    func updateScrollViewInsetsAndOffset(notification: Notification) {
        guard let scrollView = scrollView,
            let superview = scrollView.superview,
            let window = scrollView.window,
            let keyboardFrame = notification.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                return
        }
        
        let scrollViewMaxPoint = CGPoint(x: 0, y: scrollView.frame.maxY)
        let scrollViewInWindow = window.convert(scrollViewMaxPoint, from: superview)
        let bottom = scrollViewInWindow.y - keyboardFrame.origin.y
        if bottom < 0 {
            return
        }
        
        scrollView.contentInset.bottom = bottom
        scrollView.scrollIndicatorInsets.bottom = bottom
    }
    
    @objc func scrollBelowTextViewCursorFromNotification(_ notification: Notification) {
        guard let textView = notification.object as? UITextView else {
            return
        }
        
        scrollBelowTextViewCursor(textView)
    }
    
    func scrollBelowTextViewCursor(_ textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange,
            let scrollView = scrollView else {
                return
        }
        
        let textPosition = selectedRange.isEmpty
            ? selectedRange.start
            : selectedRange.end
        
        let rect = textView.caretRect(for: textPosition)
        if rect.maxY == CGFloat.nan || rect.maxY == CGFloat.infinity {
            return
        }
        let maxPoint = CGPoint(x: 0, y: rect.maxY)
        let caretInScrollView = scrollView.convert(maxPoint, from: textView)
        scrollBelowY(caretInScrollView.y + textViewCursorSpacing)
    }
}

private protocol KeyboardAvoidingProtocol where Self: UIScrollView {
    var keyboardAvoiding: KeyboardAvoiding { get }
    var viewToAvoidKeyboardSpacing: CGFloat { get set }
    var textViewCursorSpacing: CGFloat { get set }
    var shouldTrackTextViewCursor: Bool { get set }
}

// MARK: - Utils
private class KeyboardTrackingView: UIView {
    var wasAddedToView: (() -> Void)?
    var isInputAccessoryView = false
    
    static var `default`: KeyboardTrackingView = {
        let defaultView = KeyboardTrackingView()
        defaultView.isUserInteractionEnabled = false
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
    
    static func addTrackingToView(_ view: UIView) {
        KeyboardTrackingView.default.isInputAccessoryView = false
        view.addSubview(KeyboardTrackingView.default)
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

@objc fileprivate protocol KeyboardAvoidingView {
    weak var viewToAvoid: UIView? { get set }
}

private var _KeyboarAvoiding_ViewToAvoidKey: Int8 = 0
fileprivate extension KeyboardAvoidingView {
    func storeAvoidingView(_ view: UIView?, key: UnsafeRawPointer) {
        if let view = view {
            objc_setAssociatedObject(self, key, WeakObjectContainer(object: view), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(self, key, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func retrieveAvoidingView(key: UnsafeRawPointer) -> UIView? {
        guard let weakObjectContainer = objc_getAssociatedObject(self, key) else {
            return nil
        }
        
        guard let view = (weakObjectContainer as? WeakObjectContainer)?.object as? UIView else {
            storeAvoidingView(nil, key: key)
            return nil
        }
        
        return view
    }
}

private class WeakObjectContainer {
    weak var object: AnyObject?
    
    init(object anObject: AnyObject?) {
        object = anObject
    }
}

import Flutter
import Foundation
import LocalAuthentication
import UIKit
import AVFoundation

public class AppSecurityLockPlugin: NSObject, FlutterPlugin {
    private var lifecycleChannel: FlutterMethodChannel?
    // 是否锁定
    private var isLocked = false
    // 是否开启锁屏锁定
    private var isScreenLockEnabled = false

    // 是否开启后台锁定
    private var isBackgroundLockEnabled = false
    // 标记是否已经开始监听
    private var isListening = false
    // 后台超时时间（秒）
    private var backgroundTimeout: TimeInterval = 60.0

    // debug 模式
    private var isDebugMode: Bool = false

    // 后台超时定时器
    private var backgroundTimeoutTimer: Timer?

    // 触摸事件相关
    private var touchTimer: Timer?
    private var touchTimeout: TimeInterval = 30.0  // 触摸超时时间，默认30秒
    // 是否开启触摸超时
    private var isTouchTimeoutEnabled = false
    // 点击手势识别器
    private var touchGestureRecognizer: UITapGestureRecognizer?
    // 平移手势识别器
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    // 倒计时相关
    private var touchStartTime: Date?
    
    // 录屏防护相关
    private var isScreenRecordingProtectionEnabled = false
    private var screenProtectionView: UIView?
    private var securityOverlay: SecurityOverlayView?
    private var screenRecordingWarningMessage: String = "屏幕正在被录制"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "app_security_lock", binaryMessenger: registrar.messenger())
        let instance = AppSecurityLockPlugin()
        instance.lifecycleChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        // 监听应用生命周期
        instance.startListen()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":

            // 处理初始化参数
            if let args = call.arguments as? [String: Any] {
                if let screenLockEnabled = args["isScreenLockEnabled"] as? Bool {
                    isScreenLockEnabled = screenLockEnabled
                }
                if let backgroundLockEnabled = args["isBackgroundLockEnabled"] as? Bool {
                    isBackgroundLockEnabled = backgroundLockEnabled
                }
                if let timeout = args["backgroundTimeout"] as? Double {
                    backgroundTimeout = timeout
                }
                if let touchTimeoutEnabled = args["isTouchTimeoutEnabled"] as? Bool {
                    isTouchTimeoutEnabled = touchTimeoutEnabled
                }
                if let touchTimeoutSeconds = args["touchTimeout"] as? Double {
                    touchTimeout = touchTimeoutSeconds
                }
                if let debug = args["debug"] as? Bool {
                    isDebugMode = debug
                }
            }
            
            // 立即打印 debug 模式状态（用于调试）
            print("AppSecurityLock: Debug mode is \(isDebugMode ? "ENABLED" : "DISABLED")")
            
            // 只在首次调用时启动监听
            if !isListening {
                startListen()
            }
            
            // 根据配置启动相应的功能
            if isTouchTimeoutEnabled {
                setupTouchEventListeners()
                startTouchTimer()
            }

            if isDebugMode {
                print(
                    "Flutter: 初始化参数 \n  isScreenLockEnabled: \(isScreenLockEnabled),\n  isBackgroundLockEnabled: \(isBackgroundLockEnabled),\n  backgroundTimeout: \(backgroundTimeout),\n  isTouchTimeoutEnabled: \(isTouchTimeoutEnabled),\n  touchTimeout: \(touchTimeout),\n  debug: \(isDebugMode)"
                )
            }

            result(nil)
        // 更新锁定状态
        case "setLockEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                let wasLocked = isLocked
                isLocked = enabled
                if isDebugMode {
                    print("Flutter: 设置锁定状态为 \(isLocked)")
                }
                
                // 如果从解锁状态变为锁定状态，触发手动锁定回调
                if !wasLocked && enabled {
                    if isDebugMode {
                        print("Flutter: 应用已手动锁定，触发锁定回调")
                    }
                    stopAllTimers()
                    removeTouchEventListeners()
                    safeInvokeMethod("onAppLocked", arguments: ["reason": "manual"])
                }
                // 如果从锁定状态变为解锁状态，触发解锁回调
                else if wasLocked && !enabled {
                    if isDebugMode {
                        print("Flutter: 应用已解锁，触发解锁回调")
                    }
                    safeInvokeMethod("onAppUnlocked", arguments: nil)
                    
                    // 解锁后重新启动触摸超时功能（如果启用）
                    if isTouchTimeoutEnabled {
                        setupTouchEventListeners()
                        startTouchTimer()
                    }
                }
                
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        // 更新屏幕锁定开关
        case "setScreenLockEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                isScreenLockEnabled = enabled
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        // 更新后台锁定开关
        case "setBackgroundLockEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                isBackgroundLockEnabled = enabled
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        // 更新后台超时时间
        case "setBackgroundTimeout":
            if let args = call.arguments as? [String: Any],
                let timeout = args["timeout"] as? TimeInterval
            {
                setBackgroundTimeout(timeout)
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing timeout parameter", details: nil
                    ))
            }
        // 更新触摸超时时间
        case "setTouchTimeout":
            if let args = call.arguments as? [String: Any],
                let timeout = args["timeout"] as? TimeInterval
            {
                setTouchTimeout(timeout)
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing timeout parameter", details: nil
                    ))
            }
        case "setTouchTimeoutEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                setTouchTimeoutEnabled(enabled)
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        case "restartTouchTimer":
            restartTouchTimerFromButton()
            result(nil)
        case "setScreenRecordingProtectionEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                let warningMessage = args["warningMessage"] as? String
                setScreenRecordingProtectionEnabled(enabled, warningMessage: warningMessage)
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    //开始生命周期监听
    private func startListen() {
        // 防止重复注册
        if isListening {
            return
        }

        isListening = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        // 注册屏幕锁定监听 - 更可靠的方法
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenLocked),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenUnlocked),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
        
        if isDebugMode {
            print("AppSecurityLock: 屏幕锁定监听器已注册")
        }

        // 触摸事件监听将在 init 方法中根据配置决定是否启动
    }

    // 安全地调用 Flutter 方法
    private func safeInvokeMethod(_ method: String, arguments: Any?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let channel = self.lifecycleChannel else {
                if self?.isDebugMode == true {
                    print("AppSecurityLock: Cannot invoke method \(method), channel is nil")
                }
                return
            }
            
            do {
                channel.invokeMethod(method, arguments: arguments)
            } catch {
                if self.isDebugMode {
                    print("AppSecurityLock: Failed to invoke method \(method): \(error)")
                }
            }
        }
    }

    @objc private func onEnterForeground() {
        if isDebugMode {
            print("App 进入前台")
        }
        // 停止亮度检测，因为应用已进入前台
        stopAllTimers()
        // 启动触摸定时器
        safeInvokeMethod("onEnterForeground", arguments: nil)
        
        // 注意：不再在进入前台时自动触发解锁回调
        // 应用解锁应该由用户通过 UI 操作手动触发（调用 setLocked(false)）
        
        // 检查录屏状态（如果录屏防护已启用）
        if isScreenRecordingProtectionEnabled {
            checkScreenRecording()
        }
        
        // 重新启动触摸超时功能（如果启用的话）
        if isTouchTimeoutEnabled && !isLocked {
            setupTouchEventListeners()
            startTouchTimer()
        }
    }

    @objc private func onEnterBackground() {
        if isDebugMode {
            print("App 进入后台")
        }
        safeInvokeMethod("onEnterBackground", arguments: nil)
        
        // 开始后台超时任务
        startBackgroundTimeoutTimer()
    }

    // 屏幕锁定回调
    @objc func screenLocked() {
        if isDebugMode {
            print("AppSecurityLock: 屏幕锁定检测到 - isScreenLockEnabled: \(isScreenLockEnabled), isLocked: \(isLocked)")
        }
        
        // 只有在启用屏幕锁定功能且应用未锁定时才执行锁定
        if isScreenLockEnabled && !isLocked {
            if isDebugMode {
                print("AppSecurityLock: 执行应用锁定")
            }
            isLocked = true
            stopAllTimers()
            removeTouchEventListeners()
            safeInvokeMethod("onAppLocked", arguments: ["reason": "screenLock"])
        } else {
            if isDebugMode {
                if !isScreenLockEnabled {
                    print("AppSecurityLock: 屏幕锁定功能未启用，跳过锁定")
                } else if isLocked {
                    print("AppSecurityLock: 应用已锁定，跳过重复锁定")
                }
            }
        }
    }

    // 屏幕解锁回调
    @objc func screenUnlocked() {
        if isDebugMode {
            print("AppSecurityLock: 屏幕解锁检测到")
        }
        // 注意：这里不自动解锁应用，需要用户手动解锁
        // 应用解锁由用户通过UI操作控制
    }

    // 设置后台超时时间
    func setBackgroundTimeout(_ timeout: TimeInterval) {
        backgroundTimeout = timeout
        if isDebugMode {
            print("AppSecurityLock: Background timeout set to \(backgroundTimeout) seconds")
        }
        //    判断后台任务是否在运行
        if backgroundTimeoutTimer != nil {
            // 停止后台任务
            stopBackgroundTimeoutTimer()
            if isDebugMode {
                print("AppSecurityLock: Background timeout timer is already running")
            }
        }
    }

    // 开始后台超时任务
    private func startBackgroundTimeoutTimer() {
        // 如果已经有定时器在运行，先停止它
        stopBackgroundTimeoutTimer()

        if isDebugMode {
            print(
                "AppSecurityLock: Starting background timeout timer with \(backgroundTimeout) seconds")
        }
        if isBackgroundLockEnabled {
            backgroundTimeoutTimer = Timer.scheduledTimer(
                withTimeInterval: backgroundTimeout, repeats: false
            ) {
                [weak self] _ in
                self?.handleBackgroundTimeout()
            }
        }
    }  // 后台超时任务
    private func handleBackgroundTimeout() {
        if isDebugMode {
            print("AppSecurityLock: Background timeout occurred")
        }
        // 处理后台超时逻辑
        // 锁定程序
        self.isLocked = true
        if isDebugMode {
            print("AppSecurityLock: App is locked due to background timeout")
        }
        // 触发锁定回调
        self.safeInvokeMethod("onAppLocked", arguments: ["reason": "backgroundTimeout"])
        // 停止后台超时定时器
        self.stopAllTimers()
    }

    // 停止后台超时定时器
    private func stopBackgroundTimeoutTimer() {
        if let timer = backgroundTimeoutTimer {
            if isDebugMode {
                print("AppSecurityLock: Stopping background timeout timer")
            }
            timer.invalidate()
            backgroundTimeoutTimer = nil
        }
    }

    // 停止所有定时器
    private func stopAllTimers() {
        do {
            if backgroundTimeoutTimer != nil {
                stopBackgroundTimeoutTimer()
            }
            if touchTimer != nil {
                stopTouchTimer()
            }
        }
    }

    // 设置触摸事件监听
    private func setupTouchEventListeners() {
        // 延迟设置，确保UI已经加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.isDebugMode == true {
                print("AppSecurityLock: Setting up touch event listeners")
            }
            self?.addTouchEventListeners()
        }
    }

    // 设置触摸事件监听
    private func addTouchEventListeners() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            return
        }

        // 移除旧的监听器
        removeTouchEventListeners()

        // 添加点击手势识别器
        touchGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(handleUserTouch))
        touchGestureRecognizer?.cancelsTouchesInView = false
        touchGestureRecognizer?.delaysTouchesBegan = false
        touchGestureRecognizer?.delaysTouchesEnded = false
        window.addGestureRecognizer(touchGestureRecognizer!)

        // 添加拖拽手势识别器
        panGestureRecognizer = UIPanGestureRecognizer(
            target: self, action: #selector(handleUserTouch))
        panGestureRecognizer?.cancelsTouchesInView = false
        panGestureRecognizer?.delaysTouchesBegan = false
        panGestureRecognizer?.delaysTouchesEnded = false
        window.addGestureRecognizer(panGestureRecognizer!)

        if isDebugMode {
            print("AppSecurityLock: Touch event listeners added successfully")
        }
    }

    @objc private func handleUserTouch() {
        // 重置触摸超时定时器
        if isTouchTimeoutEnabled && !isLocked {
            restartTouchTimer()
        }
    }

    // 移除触摸事件监听
    private func removeTouchEventListeners() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            return
        }

        if let touchRecognizer = touchGestureRecognizer {
            window.removeGestureRecognizer(touchRecognizer)
            touchGestureRecognizer = nil
        }

        if let panRecognizer = panGestureRecognizer {
            window.removeGestureRecognizer(panRecognizer)
            panGestureRecognizer = nil
        }

        if isDebugMode {
            print("AppSecurityLock: Touch event listeners removed")
        }
    }

    // 设置触摸超时时间
    func setTouchTimeout(_ timeout: TimeInterval) {
        touchTimeout = timeout
        if isDebugMode {
            print("AppSecurityLock: Touch timeout set to \(touchTimeout) seconds")
        }
        // 如果触摸定时器正在运行，重启它
        if touchTimer != nil {
            restartTouchTimer()
        }
    }

    // 设置触摸超时是否启用
    func setTouchTimeoutEnabled(_ enabled: Bool) {
        isTouchTimeoutEnabled = enabled
        if isDebugMode {
            print("AppSecurityLock: Touch timeout enabled: \(isTouchTimeoutEnabled)")
        }

        if enabled {
            setupTouchEventListeners()
            startTouchTimer()
        } else {
            stopTouchTimer()
            removeTouchEventListeners()
        }
    }

    // 开始触摸定时器
    private func startTouchTimer() {
        guard isTouchTimeoutEnabled && !isLocked else { return }

        stopTouchTimer()
        if isDebugMode {
            print("AppSecurityLock: Starting touch timer with \(touchTimeout) seconds")
        }

        touchStartTime = Date()
        
        if isDebugMode {
            // Debug模式：每秒执行一次以显示倒计时
            touchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                self?.handleTouchTimerTick(timer)
            }
        } else {
            // 非Debug模式：直接设置超时时间
            touchTimer = Timer.scheduledTimer(withTimeInterval: touchTimeout, repeats: false) {
                [weak self] _ in
                self?.handleTouchTimeout()
            }
        }
    }
    
    private func handleTouchTimerTick(_ timer: Timer) {
        guard let startTime = touchStartTime else {
            timer.invalidate()
            return
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let remainingTime = touchTimeout - elapsedTime
        
        if remainingTime <= 0 {
            // 超时，执行锁定逻辑
            timer.invalidate()
            handleTouchTimeout()
        } else if isDebugMode {
            // 打印倒计时
            let remainingSeconds = Int(ceil(remainingTime))
            print("AppSecurityLock: 触摸倒计时: \(remainingSeconds)秒")
        }
    }

    // 重启触摸定时器
    private func restartTouchTimer() {
        guard isTouchTimeoutEnabled && !isLocked else { return }

        if isDebugMode {
            print("AppSecurityLock: Restarting touch timer")
        }
        // 只重启定时器，不需要重新设置监听器
        startTouchTimer()
    }

    // 从按钮重启触摸定时器（需要重新设置监听器）
    private func restartTouchTimerFromButton() {
        guard isTouchTimeoutEnabled && !isLocked else { return }

        if isDebugMode {
            print("AppSecurityLock: Restarting touch timer from button")
        }
        // 重新设置触摸事件监听器和重启定时器
        setupTouchEventListeners()
        startTouchTimer()
    }

    // 停止触摸定时器
    private func stopTouchTimer() {
        if let timer = touchTimer {
            if isDebugMode {
                print("AppSecurityLock: Stopping touch timer")
            }
            timer.invalidate()
            touchTimer = nil
        }
    }

    // 处理触摸超时
    private func handleTouchTimeout() {
        if isDebugMode {
            print("AppSecurityLock: Touch timeout occurred")
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 锁定应用
            self.isLocked = true
            if self.isDebugMode {
                print("AppSecurityLock: App is locked due to touch timeout")
            }

            // 触发锁定回调
            self.safeInvokeMethod("onAppLocked", arguments: ["reason": "touchTimeout"])

            // 停止所有定时器
            self.stopAllTimers()
            // 移除触摸事件监听
            self.removeTouchEventListeners()
        }
    }

    deinit {
        // 清理资源 - 直接同步清理，避免异步操作
        stopAllTimers()
        removeTouchEventListeners()
        
        // 移除所有观察者
        if isListening {
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.protectedDataWillBecomeUnavailableNotification,
                object: nil
            )
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.protectedDataDidBecomeAvailableNotification,
                object: nil
            )
            isListening = false
        }
        
        // 直接清理录屏防护相关资源，不使用异步操作
        // 移除录屏防护观察者
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // 同步移除安全覆盖视图（不使用异步）
        if let overlay = securityOverlay, overlay.superview != nil {
            overlay.removeFromSuperview()
        }
        
        // 清空所有引用
        lifecycleChannel = nil
        touchGestureRecognizer = nil
        panGestureRecognizer = nil
        securityOverlay = nil
        screenProtectionView = nil
    }

    // MARK: - 录屏防护方法
    
    /// 设置录屏防护
    private func setScreenRecordingProtectionEnabled(_ enabled: Bool, warningMessage: String? = nil) {
        isScreenRecordingProtectionEnabled = enabled
        
        // 更新警告文本
        if let message = warningMessage {
            screenRecordingWarningMessage = message
        }
        
        if enabled {
            if isDebugMode {
                print("AppSecurityLock: Setting up screen recording protection")
            }
            setupScreenRecordingProtection()
        } else {
            if isDebugMode {
                print("AppSecurityLock: Removing screen recording protection")
            }
            removeScreenRecordingProtection()
        }
    }
    
    /// 设置屏幕录制监听
    private func setupScreenRecordingProtection() {
        // 录屏状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenRecordingChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // 注意：不在这里添加 willEnterForegroundNotification 观察者
        // 因为 startListen() 已经添加了，我们可以在 onEnterForeground 中调用 checkScreenRecording()
        // 这样可以避免重复观察和清理时的冲突
        
        // 立即检查当前状态
        checkScreenRecording()
        
        if isDebugMode {
            print("AppSecurityLock: Screen recording protection setup completed")
        }
    }
    
    /// 移除屏幕录制保护
    private func removeScreenRecordingProtection() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // 注意：不在这里移除 willEnterForegroundNotification 观察者
        // 因为它是在 startListen() 中添加的，用于其他功能
        
        // 隐藏覆盖视图（使用异步，但确保安全）
        hideSecurityOverlay()
        
        if isDebugMode {
            print("AppSecurityLock: Screen recording protection removed")
        }
    }
    
    /// 处理屏幕录制状态变化
    @objc private func handleScreenRecordingChange() {
        checkScreenRecording()
    }
    
    /// 检查屏幕录制状态
    @objc private func checkScreenRecording() {
        if isScreenRecordingProtectionEnabled {
            if UIScreen.main.isCaptured {
                showSecurityOverlay()
            } else {
                hideSecurityOverlay()
            }
        }
    }
    
    /// 显示安全覆盖视图
    private func showSecurityOverlay() {
        // 确保在主线程执行
        if Thread.isMainThread {
            performShowSecurityOverlay()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performShowSecurityOverlay()
            }
        }
    }
    
    /// 执行显示安全覆盖视图（必须在主线程调用）
    private func performShowSecurityOverlay() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if securityOverlay == nil {
            securityOverlay = SecurityOverlayView(
                frame: window.bounds,
                warningMessage: screenRecordingWarningMessage
            )
            securityOverlay?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        
        if let overlay = securityOverlay, overlay.superview == nil {
            window.addSubview(overlay)
            window.bringSubviewToFront(overlay)
        }
        
        if isDebugMode {
            print("AppSecurityLock: Security overlay shown")
        }
    }
    
    /// 隐藏安全覆盖视图
    private func hideSecurityOverlay() {
        // 确保在主线程执行
        if Thread.isMainThread {
            performHideSecurityOverlay()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performHideSecurityOverlay()
            }
        }
    }
    
    /// 执行隐藏安全覆盖视图（必须在主线程调用）
    private func performHideSecurityOverlay() {
        if let overlay = securityOverlay, overlay.superview != nil {
            overlay.removeFromSuperview()
        }
        
        if isDebugMode {
            print("AppSecurityLock: Security overlay hidden")
        }
    }
}

// MARK: - 安全覆盖视图（防止录屏内容泄露）

/// 自定义安全覆盖视图（拦截触摸+模糊效果）
class SecurityOverlayView: UIView {
    private let blurView: UIVisualEffectView
    private let warningLabel: UILabel
    
    override init(frame: CGRect) {
        // 设置模糊背景
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(origin: .zero, size: frame.size)
        
        // 设置警告标签
        warningLabel = UILabel()
        warningLabel.text = "屏幕正在被录制"
        warningLabel.textColor = UIColor.red
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0
        warningLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        // 添加子视图
        blurView.contentView.addSubview(warningLabel)
        addSubview(blurView)
        
        // 设置标签约束
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -20)
        ])
    }
    
    init(frame: CGRect, warningMessage: String) {
        // 设置模糊背景
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(origin: .zero, size: frame.size)
        
        // 设置警告标签
        warningLabel = UILabel()
        warningLabel.text = warningMessage
        warningLabel.textColor = UIColor.red
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0
        warningLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        // 添加子视图
        blurView.contentView.addSubview(warningLabel)
        addSubview(blurView)
        
        // 设置标签约束
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 拦截所有触摸事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 返回自身表示拦截所有触摸事件
        return self
    }
}

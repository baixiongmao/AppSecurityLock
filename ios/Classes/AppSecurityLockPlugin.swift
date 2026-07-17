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
    
    // 录屏/截屏防护相关
    private var isScreenRecordingProtectionEnabled = false
    private var screenshotProtectedView: ScreenshotProtectedView?
    private var securityOverlayWindow: UIWindow?
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
        
        // 直接清理录屏/截屏防护相关资源，不使用异步操作
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // 进程退出时勿调用 disableScreenshotProtection()：其 [weak self] 会在 dealloc 中 fatal
        // 此时 Flutter 引擎/窗口已在销毁，无需恢复 layer，只释放引用即可
        screenshotProtectedView?.removeFromSuperview()
        screenshotProtectedView = nil
        
        securityOverlayWindow?.isHidden = true
        securityOverlayWindow = nil
        securityOverlay = nil
        
        lifecycleChannel = nil
        touchGestureRecognizer = nil
        panGestureRecognizer = nil
    }

    // MARK: - 录屏/截屏防护方法
    
    /// 设置录屏与截屏防护
    ///
    /// - 开启时：静默启用 secure 保护（截图露出底层占位文案，平时界面正常）
    /// - 录屏中：显示 warningMessage 全屏遮罩
    /// - 截屏后不再弹遮罩
    private func setScreenRecordingProtectionEnabled(_ enabled: Bool, warningMessage: String? = nil) {
        isScreenRecordingProtectionEnabled = enabled
        
        if let message = warningMessage {
            screenRecordingWarningMessage = message
            screenshotProtectedView?.setPlaceholderText(message)
            securityOverlay?.updateWarningMessage(message)
        }
        
        let run: () -> Void = { [weak self] in
            guard let self = self else { return }
            if enabled {
                self.enableScreenshotProtection()
                self.setupScreenRecordingProtection()
            } else {
                self.removeScreenRecordingProtection()
                self.disableScreenshotProtection()
            }
        }
        
        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.sync(execute: run)
        }
    }
    
    private func getKeyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
            ?? scenes.flatMap { $0.windows }.first
    }
    
    private func getActiveWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
    
    /// 启用截屏保护（Flutter 可用方案）：
    /// - 不把 secure canvas UIView 拆出来 addSubview（那会导致 Flutter 黑屏）
    /// - 保留 UITextField 在层级中，把 flutter.layer 挂到 field 内部 secure sublayer
    /// - 占位层作为更低的兄弟层，截图时浮现
    private func enableScreenshotProtection() {
        guard let window = getKeyWindow(),
              let flutterView = window.rootViewController?.view else {
            if isDebugMode {
                print("AppSecurityLock: Failed to enable screenshot protection - no window/view")
            }
            return
        }

        if let protectedView = screenshotProtectedView {
            protectedView.setPlaceholderText(screenRecordingWarningMessage)
            return
        }

        let protectedView = ScreenshotProtectedView(frame: window.bounds)
        protectedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        protectedView.isUserInteractionEnabled = false
        protectedView.setPlaceholderText(screenRecordingWarningMessage)

        window.insertSubview(protectedView, at: 0)
        protectedView.frame = window.bounds
        window.layoutIfNeeded()

        guard protectedView.activateSecureCanvas() else {
            protectedView.removeFromSuperview()
            if isDebugMode {
                print("AppSecurityLock: Secure anchor unavailable, skip screenshot protection")
            }
            return
        }

        protectedView.protectLayer(of: flutterView)
        screenshotProtectedView = protectedView

        if isDebugMode {
            print("AppSecurityLock: Screenshot protection enabled (secure field anchor)")
        }
    }
    
    /// 关闭截屏保护并恢复 Flutter layer（正常禁用路径）
    /// 注意：deinit 中禁止调用本方法（内部 [weak self] 会在 dealloc 时崩溃）
    private func disableScreenshotProtection() {
        let apply: () -> Void = { [weak self] in
            guard let self = self else { return }
            guard let protectedView = self.screenshotProtectedView else { return }

            if let window = self.getKeyWindow(),
               let flutterView = window.rootViewController?.view {
                protectedView.restoreProtectedLayer(to: window, contentView: flutterView)
            }

            protectedView.removeFromSuperview()
            self.screenshotProtectedView = nil

            if self.isDebugMode {
                print("AppSecurityLock: Screenshot protection disabled")
            }
        }
        
        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }
    
    /// 注册录屏通知；开启时不弹遮罩，截屏后也不弹遮罩
    private func setupScreenRecordingProtection() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenRecordingChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        checkScreenRecording()
        
        if isDebugMode {
            print("AppSecurityLock: Listening for screen recording notifications")
        }
    }
    
    private func removeScreenRecordingProtection() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        hideSecurityOverlay()
        
        if isDebugMode {
            print("AppSecurityLock: Stopped screen recording notification listeners")
        }
    }
    
    @objc private func handleScreenRecordingChange() {
        checkScreenRecording()
    }
    
    @objc private func checkScreenRecording() {
        guard isScreenRecordingProtectionEnabled else {
            hideSecurityOverlay()
            return
        }
        
        if UIScreen.main.isCaptured {
            showSecurityOverlay()
        } else {
            hideSecurityOverlay()
        }
    }
    
    private func showSecurityOverlay() {
        if Thread.isMainThread {
            performShowSecurityOverlay()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performShowSecurityOverlay()
            }
        }
    }
    
    /// 录屏时用独立 UIWindow 显示 warningMessage（不进入 secure 层，文案可见）
    private func performShowSecurityOverlay() {
        guard let scene = getActiveWindowScene() else {
            if isDebugMode {
                print("AppSecurityLock: No window scene for security overlay")
            }
            return
        }
        
        let appWindow = getKeyWindow()
        
        let overlayWindow: UIWindow
        if let existing = securityOverlayWindow {
            overlayWindow = existing
        } else {
            let window = UIWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
            window.windowLevel = .alert + 100
            window.backgroundColor = .clear
            window.isHidden = true
            securityOverlayWindow = window
            overlayWindow = window
        }
        
        if securityOverlay == nil {
            let overlay = SecurityOverlayView(
                frame: overlayWindow.bounds,
                warningMessage: screenRecordingWarningMessage
            )
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            securityOverlay = overlay
            let host = UIViewController()
            host.view.backgroundColor = .clear
            host.view.addSubview(overlay)
            overlayWindow.rootViewController = host
        } else {
            securityOverlay?.updateWarningMessage(screenRecordingWarningMessage)
            securityOverlay?.frame = overlayWindow.bounds
        }
        
        overlayWindow.frame = scene.coordinateSpace.bounds
        overlayWindow.isHidden = false
        overlayWindow.makeKeyAndVisible()
        if let appWindow = appWindow, appWindow !== overlayWindow {
            appWindow.makeKey()
        }
        
        if isDebugMode {
            print("AppSecurityLock: Security overlay shown with message: \(screenRecordingWarningMessage)")
        }
    }
    
    private func hideSecurityOverlay() {
        if Thread.isMainThread {
            performHideSecurityOverlay()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performHideSecurityOverlay()
            }
        }
    }
    
    private func performHideSecurityOverlay() {
        securityOverlayWindow?.isHidden = true
        
        if isDebugMode {
            print("AppSecurityLock: Security overlay hidden")
        }
    }
}

// MARK: - 安全覆盖视图（防止录屏内容泄露）

/// 自定义安全覆盖视图（拦截触摸 + 暗色模糊 + 警告文案）
class SecurityOverlayView: UIView {
    private let dimView: UIView
    private let blurView: UIVisualEffectView
    private let warningLabel: UILabel
    
    override init(frame: CGRect) {
        dimView = UIView()
        let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
        blurView = UIVisualEffectView(effect: blurEffect)
        warningLabel = UILabel()
        warningLabel.text = "屏幕正在被录制"
        super.init(frame: frame)
        commonInit()
    }
    
    init(frame: CGRect, warningMessage: String) {
        dimView = UIView()
        let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
        blurView = UIVisualEffectView(effect: blurEffect)
        warningLabel = UILabel()
        warningLabel.text = warningMessage
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        dimView.frame = bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        warningLabel.textColor = .white
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0
        warningLabel.font = UIFont.boldSystemFont(ofSize: 22)
        
        addSubview(dimView)
        addSubview(blurView)
        blurView.contentView.addSubview(warningLabel)
        
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 24),
            warningLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -24)
        ])
    }
    
    func updateWarningMessage(_ message: String) {
        warningLabel.text = message
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self
    }
}


// MARK: - 截图保护（占位层在下 + UITextField 内部 secure sublayer）

/// 不要把 secure canvas UIView 拆出来再 addSubview——Flutter 会黑屏。
/// 正确：保留 UITextField 完整层级，把 content.layer 挂到其内部 secure sublayer。
/// 占位层在同一父视图更低 z-index，截图时 secure 被跳过、占位层浮现。
class ScreenshotProtectedView: UIView {

    private let secureField = UITextField()
    private var secureAnchor: CALayer?
    private let placeholderView = UIView()
    private weak var protectedContentView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlaceholder()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }

    private func setupPlaceholder() {
        // 与 SecurityOverlayView 同视觉：暗色遮罩 + 模糊 + 居中 warning 文案
        placeholderView.backgroundColor = .clear
        insertSubview(placeholderView, at: 0)
        placeholderView.frame = bounds
        placeholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        dimView.frame = placeholderView.bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholderView.addSubview(dimView)

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
        blurView.frame = placeholderView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholderView.addSubview(blurView)

        let label = UILabel()
        label.text = "屏幕正在被录制"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 22)
        blurView.contentView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -24),
        ])
    }

    @discardableResult
    func activateSecureCanvas() -> Bool {
        if secureAnchor != nil { return true }
        return setupSecureLayer()
    }

    @discardableResult
    private func setupSecureLayer() -> Bool {
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        secureField.backgroundColor = .clear
        secureField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(secureField)
        NSLayoutConstraint.activate([
            secureField.topAnchor.constraint(equalTo: topAnchor),
            secureField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setNeedsLayout()
        layoutIfNeeded()

        let sublayers = secureField.layer.sublayers ?? []
        // 关键：不拆 canvas UIView，只保留内部 secure CALayer 作挂载点
        if #available(iOS 17.0, *) {
            secureAnchor = sublayers.last ?? sublayers.first
        } else {
            secureAnchor = sublayers.first ?? sublayers.last
        }
        return secureAnchor != nil
    }

    var hasSecureCanvas: Bool { secureAnchor != nil }
    var isPlaceholderAboveCanvas: Bool { false }
    var secureCanvasBounds: CGRect { bounds }
    var secureCanvasSubviewCount: Int { 0 }

    var isFlutterLayerInSecureCanvas: Bool {
        guard let content = protectedContentView, let anchor = secureAnchor else { return false }
        return content.layer.superlayer === anchor
    }

    func debugCanvasInfo() -> [String: Any] {
        let sublayers = secureField.layer.sublayers ?? []
        return [
            "hasSecureAnchor": secureAnchor != nil,
            "sublayerCount": sublayers.count,
            "extractedCanvasView": false,
            "viewBounds": "\(bounds)",
            "inWindow": window != nil,
        ]
    }

    func ensurePlaceholderBehindCanvas() {
        insertSubview(placeholderView, at: 0)
        if secureField.superview === self {
            bringSubviewToFront(secureField)
        }
    }

    func protectLayer(of view: UIView) {
        guard let secureAnchor else { return }
        protectedContentView = view
        ensurePlaceholderBehindCanvas()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        secureAnchor.addSublayer(view.layer)
        view.layer.frame = bounds
        CATransaction.commit()
    }

    func restoreProtectedLayer(to window: UIWindow, contentView: UIView) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        window.layer.insertSublayer(contentView.layer, at: 0)
        contentView.layer.frame = window.bounds
        CATransaction.commit()
        protectedContentView = nil
    }

    func setPlaceholderText(_ text: String) {
        // dim + blur + label；label 在 blur.contentView 里
        func findLabel(in view: UIView) -> UILabel? {
            if let label = view as? UILabel { return label }
            for child in view.subviews {
                if let found = findLabel(in: child) { return found }
            }
            return nil
        }
        findLabel(in: placeholderView)?.text = text
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderView.frame = bounds
        if let content = protectedContentView,
           content.layer.superlayer === secureAnchor {
            content.layer.frame = bounds
        }
    }
}

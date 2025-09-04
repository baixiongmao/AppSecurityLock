import Flutter
import Foundation
import LocalAuthentication
import UIKit

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
            }
            // 只在首次调用时启动监听
            if !isListening {
                startListen()
            }
            
            // 根据配置启动相应的功能
            if isTouchTimeoutEnabled {
                setupTouchEventListeners()
                startTouchTimer()
            }
            
            print(
                "Flutter: 初始化参数 \n  isScreenLockEnabled: \(isScreenLockEnabled),\n  isBackgroundLockEnabled: \(isBackgroundLockEnabled),\n  backgroundTimeout: \(backgroundTimeout),\n  isTouchTimeoutEnabled: \(isTouchTimeoutEnabled),\n  touchTimeout: \(touchTimeout)"
            )

            result(nil)
        // 更新锁定状态
        case "setLockEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                isLocked = enabled
                print("AppSecurityLock: Lock state changed to: \(enabled)")
                
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

        // 触摸事件监听将在 init 方法中根据配置决定是否启动
    }

    @objc private func onEnterForeground() {
        print("App 进入前台")
        // 停止亮度检测，因为应用已进入前台
        stopAllTimers()
        // 启动触摸定时器
        lifecycleChannel?.invokeMethod("onEnterForeground", arguments: nil)
        if isLocked {
            // 通知前台解锁
            lifecycleChannel?.invokeMethod("onAppUnlocked", arguments: nil)
        }
        
        // 重新启动触摸超时功能（如果启用的话）
        if isTouchTimeoutEnabled && !isLocked {
            setupTouchEventListeners()
            startTouchTimer()
        }
    }

    @objc private func onEnterBackground() {
        print("App 进入后台")
        lifecycleChannel?.invokeMethod("onEnterBackground", arguments: nil)
        
        // 开始后台超时任务
        startBackgroundTimeoutTimer()
    }

    // 屏幕锁定回调
    @objc func screenLocked() {
        print("AppSecurityLock: 屏幕锁定检测到")
        
        // 只有在启用屏幕锁定功能且应用未锁定时才执行锁定
        if isScreenLockEnabled && !isLocked {
            print("AppSecurityLock: 执行应用锁定")
            isLocked = true
            stopAllTimers()
            removeTouchEventListeners()
            lifecycleChannel?.invokeMethod("onAppLocked", arguments: nil)
        }
    }

    // 屏幕解锁回调
    @objc func screenUnlocked() {
        print("AppSecurityLock: 屏幕解锁检测到")
        // 注意：这里不自动解锁应用，需要用户手动解锁
        // 应用解锁由用户通过UI操作控制
    }

    // 设置后台超时时间
    func setBackgroundTimeout(_ timeout: TimeInterval) {
        backgroundTimeout = timeout
        print("AppSecurityLock: Background timeout set to \(backgroundTimeout) seconds")
        //    判断后台任务是否在运行
        if backgroundTimeoutTimer != nil {
            // 停止后台任务
            stopBackgroundTimeoutTimer()
            print("AppSecurityLock: Background timeout timer is already running")
        }
    }

    // 开始后台超时任务
    private func startBackgroundTimeoutTimer() {
        // 如果已经有定时器在运行，先停止它
        stopBackgroundTimeoutTimer()

        print(
            "AppSecurityLock: Starting background timeout timer with \(backgroundTimeout) seconds")
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
        print("AppSecurityLock: Background timeout occurred")
        // 处理后台超时逻辑
        // 锁定程序
        self.isLocked = true
        print("AppSecurityLock: App is locked due to background timeout")
        // 触发锁定回调
        self.lifecycleChannel?.invokeMethod("onAppLocked", arguments: nil)
        // 停止后台超时定时器
        self.stopAllTimers()
    }

    // 停止后台超时定时器
    private func stopBackgroundTimeoutTimer() {
        if let timer = backgroundTimeoutTimer {
            print("AppSecurityLock: Stopping background timeout timer")
            timer.invalidate()
            backgroundTimeoutTimer = nil
        }
    }

    // 停止所有定时器
    private func stopAllTimers() {
        if backgroundTimeoutTimer != nil {
            stopBackgroundTimeoutTimer()
        }
        if touchTimer != nil {
            stopTouchTimer()
        }
    }

    // 设置触摸事件监听
    private func setupTouchEventListeners() {
        // 延迟设置，确保UI已经加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            print("AppSecurityLock: Setting up touch event listeners")
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

        print("AppSecurityLock: Touch event listeners added successfully")
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

        print("AppSecurityLock: Touch event listeners removed")
    }

    // 设置触摸超时时间
    func setTouchTimeout(_ timeout: TimeInterval) {
        touchTimeout = timeout
        print("AppSecurityLock: Touch timeout set to \(touchTimeout) seconds")
        // 如果触摸定时器正在运行，重启它
        if touchTimer != nil {
            restartTouchTimer()
        }
    }

    // 设置触摸超时是否启用
    func setTouchTimeoutEnabled(_ enabled: Bool) {
        isTouchTimeoutEnabled = enabled
        print("AppSecurityLock: Touch timeout enabled: \(isTouchTimeoutEnabled)")

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
        print("AppSecurityLock: Starting touch timer with \(touchTimeout) seconds")

        touchTimer = Timer.scheduledTimer(withTimeInterval: touchTimeout, repeats: false) {
            [weak self] _ in
            self?.handleTouchTimeout()
        }
    }

    // 重启触摸定时器
    private func restartTouchTimer() {
        guard isTouchTimeoutEnabled && !isLocked else { return }

        print("AppSecurityLock: Restarting touch timer")
        // 只重启定时器，不需要重新设置监听器
        startTouchTimer()
    }

    // 从按钮重启触摸定时器（需要重新设置监听器）
    private func restartTouchTimerFromButton() {
        guard isTouchTimeoutEnabled && !isLocked else { return }

        print("AppSecurityLock: Restarting touch timer from button")
        // 重新设置触摸事件监听器和重启定时器
        setupTouchEventListeners()
        startTouchTimer()
    }

    // 停止触摸定时器
    private func stopTouchTimer() {
        if let timer = touchTimer {
            print("AppSecurityLock: Stopping touch timer")
            timer.invalidate()
            touchTimer = nil
        }
    }

    // 处理触摸超时
    private func handleTouchTimeout() {
        print("AppSecurityLock: Touch timeout occurred")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 锁定应用
            self.isLocked = true
            print("AppSecurityLock: App is locked due to touch timeout")

            // 触发锁定回调
            self.lifecycleChannel?.invokeMethod("onAppLocked", arguments: nil)

            // 停止所有定时器
            self.stopAllTimers()
            // 移除触摸事件监听
            self.removeTouchEventListeners()
        }
    }

    deinit {
        // 清理资源
        stopAllTimers()
        if isListening {
            NotificationCenter.default.removeObserver(self)
            isListening = false
        }
    }
}

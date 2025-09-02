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

    // 亮度检测定时器
    private var brightnessTimer: Timer?
    // 后台超时定时器
    private var backgroundTimeoutTimer: Timer?

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
            // 只在首次调用时启动监听
            if !isListening {
                startListen()
            }

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
            }
            print(
                "Flutter: 初始化参数 -  isScreenLockEnabled: \(isScreenLockEnabled), isBackgroundLockEnabled: \(isBackgroundLockEnabled), backgroundTimeout: \(backgroundTimeout)"
            )

            result(nil)
        case "setLockEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                isLocked = enabled
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
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
        case "stopBrightnessDetection":
            stopBrightnessDetection()
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
    }

    @objc private func onEnterForeground() {
        print("App 进入前台")
        // 停止亮度检测，因为应用已进入前台
        stopAllTimers()
        lifecycleChannel?.invokeMethod("onEnterForeground", arguments: nil)
        if isLocked {
            // 通知前台解锁
            lifecycleChannel?.invokeMethod("onAppUnlocked", arguments: nil)
        }
    }

    @objc private func onEnterBackground() {
        print("App 进入后台")
        lifecycleChannel?.invokeMethod("onEnterBackground", arguments: nil)
        // 开始检测屏幕亮度
        startBrightnessDetection()
        // 开始后台超时任务
        startBackgroundTimeoutTimer()
    }

    // 开始循环，每秒检测手机屏幕亮度
    private func startBrightnessDetection() {
        // 如果已经有定时器在运行，先停止它
        stopBrightnessDetection()
        if isLocked {
            print("AppSecurityLock: App is already locked, skipping brightness detection")
            return
        }
        print("AppSecurityLock: Starting brightness detection")
        if isScreenLockEnabled && !isLocked {
            brightnessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                [weak self] _ in
                self?.checkScreenBrightness()
            }
        }
    }

    // 检查屏幕亮度并处理锁定逻辑
    private func checkScreenBrightness() {
        let currentBrightness = UIScreen.main.brightness
        if isLocked {
            print("AppSecurityLock: App is already locked, skipping brightness check")
            return
        }
        print("AppSecurityLock: Current screen brightness: \(currentBrightness)")

        if currentBrightness == 0.0 && !isLocked {
            print("AppSecurityLock: Screen brightness is 0.0, locking app")
            DispatchQueue.main.async { [weak self] in
                // 锁定
                self?.isLocked = true
                print("AppSecurityLock: App is locked")
                // 锁定回调
                self?.lifecycleChannel?.invokeMethod("onAppLocked", arguments: nil)
                // 停止亮度检测，因为应用已被锁定
                self?.stopAllTimers()
            }
        }
    }

    // 停止亮度检测
    private func stopBrightnessDetection() {
        if let timer = brightnessTimer {
            print("AppSecurityLock: Stopping brightness detection")
            timer.invalidate()
            brightnessTimer = nil
        }
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
        if brightnessTimer != nil {
            stopBrightnessDetection()
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

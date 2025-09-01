import Flutter
import Foundation
import LocalAuthentication
import UIKit

public class AppSecurityLockPlugin: NSObject, FlutterPlugin {
    private var lifecycleChannel: FlutterMethodChannel?
    // 是否锁定
    private var isLocked = false
    // 是否开启面部生物识别
    private var isFaceIDEnabled = false
    // 是否开启密码解锁
    private var isPasscodeEnabled = false
    // 是否开启锁屏锁定
    private var isScreenLockEnabled = false
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
        case "setFaceIDEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                isFaceIDEnabled = enabled
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        case "setPasscodeEnabled":
            if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool
            {
                isPasscodeEnabled = enabled
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT", message: "Missing enabled parameter", details: nil
                    ))
            }
        case "isBiometricAvailable":
            result(isBiometricAvailable())
        case "getBiometricType":
            result(getBiometricType())
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
        case "authenticateWithBiometric":
            authenticateWithBiometric { success, error in
                if success {
                    result(true)
                } else {
                    result(
                        FlutterError(code: "AUTHENTICATION_FAILED", message: error, details: nil))
                }
            }
        case "stopBrightnessDetection":
            stopBrightnessDetection()
            result(nil)
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
        stopBrightnessDetection()
        // 停止后台超时任务
        stopBackgroundTimeoutTimer()
        lifecycleChannel?.invokeMethod("onEnterForeground", arguments: nil)
        if isLocked {
            // 调用生物识别
            startBiometricAuthentication()
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

    //开始生物识别
    private func startBiometricAuthentication() {
        if isFaceIDEnabled && isBiometricAvailable() {
            // 开始面部生物识别
            authenticateWithBiometric { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.isLocked = false
                        // 触发统一的认证回调 - 成功
                        self?.lifecycleChannel?.invokeMethod(
                            "onAuthentication", arguments: ["success": true, "type": "biometric"])
                    } else {
                        if self?.isPasscodeEnabled == true {
                            self?.startPasscodeAuthentication()
                        } else {
                            // 触发统一的认证回调 - 失败
                            self?.lifecycleChannel?.invokeMethod(
                                "onAuthentication",
                                arguments: ["success": false, "error": error ?? "生物识别失败"])
                        }
                    }
                }
            }
        } else if isPasscodeEnabled {
            // 调用密码解锁
            startPasscodeAuthentication()
        }
    }

    // 判断生物识别是否可用
    private func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        return false
    }

    // 获取生物识别类型
    private func getBiometricType() -> String {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        else {
            return "none"
        }

        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                return "faceID"
            case .touchID:
                return "touchID"
            case .opticID:
                return "opticID"
            case .none:
                return "none"
            @unknown default:
                return "unknown"
            }
        } else {
            return "touchID"
        }
    }

    // 执行生物识别认证
    private func authenticateWithBiometric(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        let reason = "请使用生物识别进行身份验证"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
            success, error in
            if success {
                completion(true, nil)
            } else {
                var errorMessage = "生物识别失败"
                if let error = error as? LAError {
                    switch error.code {
                    case .userCancel:
                        errorMessage = "用户取消了认证"
                    case .userFallback:
                        errorMessage = "用户选择了其他认证方式"
                    case .biometryNotAvailable:
                        errorMessage = "生物识别不可用"
                    case .biometryNotEnrolled:
                        errorMessage = "未设置生物识别"
                    case .biometryLockout:
                        errorMessage = "生物识别被锁定"
                    default:
                        errorMessage = "认证失败: \(error.localizedDescription)"
                    }
                }
                completion(false, errorMessage)
            }
        }
    }

    // 开始密码解锁
    private func startPasscodeAuthentication() {
        if isPasscodeEnabled {
            let context = LAContext()
            let reason = "请输入设备密码进行身份验证"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.isLocked = false
                        // 触发统一的认证回调 - 成功
                        self?.lifecycleChannel?.invokeMethod(
                            "onAuthentication", arguments: ["success": true, "type": "passcode"])
                    } else {
                        var errorMessage = "密码认证失败"
                        if let error = error as? LAError {
                            switch error.code {
                            case .userCancel:
                                errorMessage = "用户取消了认证"
                            case .systemCancel:
                                errorMessage = "系统取消了认证"
                            default:
                                errorMessage = "认证失败: \(error.localizedDescription)"
                            }
                        }
                        // 触发统一的认证回调 - 失败
                        self?.lifecycleChannel?.invokeMethod(
                            "onAuthentication",
                            arguments: ["success": false, "error": errorMessage])
                    }
                }
            }
        }
    }

    // 开始循环，每秒检测手机屏幕亮度
    private func startBrightnessDetection() {
        // 如果已经有定时器在运行，先停止它
        stopBrightnessDetection()

        print("AppSecurityLock: Starting brightness detection")
        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            self?.checkScreenBrightness()
        }
    }

    // 检查屏幕亮度并处理锁定逻辑
    private func checkScreenBrightness() {
        let currentBrightness = UIScreen.main.brightness
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
        backgroundTimeoutTimer = Timer.scheduledTimer(
            withTimeInterval: backgroundTimeout, repeats: false
        ) {
            [weak self] _ in
            self?.handleBackgroundTimeout()
        }
    }

    // 后台超时任务
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

package com.example.app_security_lock

import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AppSecurityLockPlugin */
class AppSecurityLockPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    Application.ActivityLifecycleCallbacks {

    companion object {
        private const val TAG = "AppSecurityLockPlugin"
        private const val CHANNEL_NAME = "app_security_lock"
    }

    /// The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null


    // 状态变量
    private var isLocked = false
    private var isScreenLockEnabled = false
    private var isBackgroundLockEnabled = false
    private var isListening = false
    private var backgroundTimeout: Long = 60000L // 60秒，单位毫秒
    private var debug = false
    
    // 触摸超时变量
    private var isTouchTimeoutEnabled = false
    private var touchTimeout: Long = 30000L // 30秒，单位毫秒

    // 定时器
    private var backgroundTimeoutHandler: Handler? = null
    private var backgroundTimeoutRunnable: Runnable? = null
    private var touchTimeoutHandler: Handler? = null
    private var touchTimeoutRunnable: Runnable? = null
    
    // 倒计时相关
    private var touchStartTime: Long = 0L
    private var backgroundStartTime: Long = 0L

    // 生命周期状态
    private var isInBackground = false
    private var backgroundTimestamp = 0L
    
    // 广播接收器
    private var screenBroadcastReceiver: BroadcastReceiver? = null
    private var isScreenReceiverRegistered = false
    
    // 触摸监听相关
    private var touchListener: View.OnTouchListener? = null
    private var isTouchListenerSetup = false
    private var lastTouchTime: Long = 0L
    private var originalCallback: android.view.Window.Callback? = null
    
    // 录屏防护相关
    private var isScreenRecordingProtectionEnabled = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // 注册应用生命周期监听
        if (context is Application) {
            (context as Application).registerActivityLifecycleCallbacks(this)
        }
        
        if (debug) {
            Log.d(TAG, "Plugin attached to engine")
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "init" -> {
                handleInit(call, result)
            }

            "setLockEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setLockEnabled(enabled)
                result.success(null)
            }

            "setScreenLockEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setScreenLockEnabled(enabled)
                result.success(null)
            }

            "setBackgroundLockEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setBackgroundLockEnabled(enabled)
                result.success(null)
            }

            "setBackgroundTimeout" -> {
                val timeout = call.argument<Double>("timeout") ?: 60.0
                setBackgroundTimeout(timeout)
                result.success(null)
            }

            "setTouchTimeout" -> {
                val timeout = call.argument<Double>("timeout") ?: 30.0
                setTouchTimeout(timeout)
                result.success(null)
            }

            "setTouchTimeoutEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setTouchTimeoutEnabled(enabled)
                result.success(null)
            }

            "restartTouchTimer" -> {
                restartTouchTimeoutFromButton()
                result.success(null)
            }

            "onUserInteraction" -> {
                onUserInteraction()
                result.success(null)
            }

            "stopBrightnessDetection" -> {
                stopScreenDetection()
                result.success(null)
            }

            "setScreenRecordingProtectionEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val warningMessage = call.argument<String>("warningMessage")
                setScreenRecordingProtectionEnabled(enabled, warningMessage)
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleInit(call: MethodCall, result: Result) {
        // 只在首次调用时启动监听
        if (!isListening) {
            startListen()
        }

        // 处理初始化参数
        call.argument<Boolean>("isScreenLockEnabled")?.let {
            isScreenLockEnabled = it
        }
        call.argument<Boolean>("isBackgroundLockEnabled")?.let {
            isBackgroundLockEnabled = it
        }
        call.argument<Double>("backgroundTimeout")?.let {
            backgroundTimeout = (it * 1000).toLong()
        }
        call.argument<Boolean>("isTouchTimeoutEnabled")?.let {
            isTouchTimeoutEnabled = it
        }
        call.argument<Double>("touchTimeout")?.let {
            touchTimeout = (it * 1000).toLong()
        }
        call.argument<Boolean>("debug")?.let {
            debug = it
        }

        // 立即打印 debug 模式状态（用于调试）
        Log.d(TAG, "Debug mode is ${if (debug) "ENABLED" else "DISABLED"}")

        if (debug) {
            Log.d(
                TAG,
                "初始化参数 - isScreenLockEnabled: $isScreenLockEnabled, " +
                "isBackgroundLockEnabled: $isBackgroundLockEnabled, " +
                "backgroundTimeout: $backgroundTimeout, " +
                "isTouchTimeoutEnabled: $isTouchTimeoutEnabled, " +
                "touchTimeout: $touchTimeout, " +
                "debug: $debug"
        )
        }
        
        // 启动触摸超时功能（如果启用）
        if (isTouchTimeoutEnabled) {
            setupTouchListener()
            startTouchTimeout()
        }
        
        // 注意：屏幕锁定检测只在用户显式调用setScreenLockEnabled(true)时启动
        // 这里不自动启动屏幕检测，即使isScreenLockEnabled为true
        
        result.success(null)
    }

    private fun startListen() {
        if (isListening) {
            return
        }
        isListening = true
        if (debug) {
            Log.d(TAG, "开始监听应用生命周期")
        }
    }

    // 设置锁定状态
    private fun setLockEnabled(enabled: Boolean) {
        val wasLocked = isLocked
        isLocked = enabled
        if (debug) {
            Log.d(TAG, "Lock state changed to: $enabled")
        }

        // 如果从解锁状态变为锁定状态，触发手动锁定回调
        if (!wasLocked && enabled) {
            if (debug) {
                Log.d(TAG, "应用已手动锁定，触发锁定回调")
            }
            stopAllTimers()
            removeTouchListener()
            invokeMethod("onAppLocked", mapOf("reason" to "manual"))
        }
        // 如果从锁定状态变为解锁状态，触发解锁回调
        else if (wasLocked && !enabled) {
            if (debug) {
                Log.d(TAG, "应用已解锁，触发解锁回调")
            }
            invokeMethod("onAppUnlocked", null)
            
            // 解锁后重新启动触摸超时功能（如果启用）
            if (isTouchTimeoutEnabled) {
                setupTouchListener()
                startTouchTimeout()
            }
        }
    }

    // 设置屏幕锁定检测
    private fun setScreenLockEnabled(enabled: Boolean) {
        isScreenLockEnabled = enabled
        if (debug) {
            Log.d(TAG, "Screen lock enabled: $enabled")
        }

        if (enabled) {
            startScreenDetection()
        } else {
            stopScreenDetection()
        }
    }

    // 设置后台锁定
    private fun setBackgroundLockEnabled(enabled: Boolean) {
        isBackgroundLockEnabled = enabled
        if (debug) {
            Log.d(TAG, "Background lock enabled: $enabled")
        }

        if (enabled && isInBackground) {
            startBackgroundTimeoutTimer()
        } else {
            stopBackgroundTimeoutTimer()
        }
    }

    // 设置后台超时时间
    private fun setBackgroundTimeout(timeout: Double) {
        backgroundTimeout = (timeout * 1000).toLong() // 转换为毫秒
        if (debug) {
            Log.d(TAG, "Background timeout set to $backgroundTimeout ms")
        }

        // 如果后台定时器正在运行，重启它
        if (backgroundTimeoutHandler != null && isBackgroundLockEnabled) {
            startBackgroundTimeoutTimer()
        }
    }

    // 设置触摸超时时间
    private fun setTouchTimeout(timeout: Double) {
        touchTimeout = (timeout * 1000).toLong() // 转换为毫秒
        if (debug) {
            Log.d(TAG, "Touch timeout set to $touchTimeout ms")
        }

        // 如果触摸定时器正在运行，重启它
        if (touchTimeoutHandler != null && isTouchTimeoutEnabled) {
            startTouchTimeout()
        }
    }

    // 设置触摸超时启用状态
    private fun setTouchTimeoutEnabled(enabled: Boolean) {
        isTouchTimeoutEnabled = enabled
        if (debug) {
            Log.d(TAG, "Touch timeout enabled: $isTouchTimeoutEnabled")
        }

        if (enabled && !isLocked) {
            setupTouchListener()
            startTouchTimeout()
        } else {
            removeTouchListener()
            stopTouchTimeout()
        }
    }

    // 开始屏幕状态检测（使用广播接收器）
    private fun startScreenDetection() {
        stopScreenDetection()

        if (!isScreenLockEnabled) {
            if (debug) {
                Log.d(TAG, "屏幕锁定检测未启用")
            }
            return
        }

        if (isLocked) {
            if (debug) {
                Log.d(TAG, "应用已锁定，跳过屏幕检测")
            }
            return
        }

        if (debug) {
            Log.d(TAG, "开始屏幕状态检测")
        }
        initScreenBroadcastReceiver()
        registerScreenReceiver()
    }
    
    private fun initScreenBroadcastReceiver() {
        if (screenBroadcastReceiver == null) {
            screenBroadcastReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    when (intent.action) {
                        Intent.ACTION_SCREEN_OFF -> {
                            if (debug) {
                                Log.d(TAG, "屏幕关闭")
                            }
                            if (!isLocked) {
                                isLocked = true
                                stopAllTimers()
                                removeTouchListener()
                                invokeMethod("onAppLocked", mapOf("reason" to "screenLock"))
                            }
                        }
                        Intent.ACTION_SCREEN_ON -> {
                            if (debug) {
                                Log.d(TAG, "屏幕开启")
                            }
                            // 屏幕开启时不自动解锁，需要用户解锁
                        }
                        Intent.ACTION_USER_PRESENT -> {
                            if (debug) {
                                Log.d(TAG, "用户解锁设备")
                            }
                            // 当用户解锁设备时，可以选择性地解锁应用
                            // 这里暂时不自动解锁应用，由应用层决定
                        }
                    }
                }
            }
        }
    }
    
    private fun registerScreenReceiver() {
        context?.let { ctx ->
            if (!isScreenReceiverRegistered && screenBroadcastReceiver != null) {
                try {
                    val intentFilter = IntentFilter().apply {
                        addAction(Intent.ACTION_SCREEN_OFF)
                        addAction(Intent.ACTION_SCREEN_ON)
                        addAction(Intent.ACTION_USER_PRESENT)
                    }
                    ctx.registerReceiver(screenBroadcastReceiver, intentFilter)
                    isScreenReceiverRegistered = true
                    if (debug) {
                        Log.d(TAG, "屏幕状态广播接收器已注册")
                    }
                } catch (e: Exception) {
                    if (debug) {
                        Log.e(TAG, "注册屏幕状态广播接收器失败", e)
                    }
                }
            }
        }
    }

    private fun stopScreenDetection() {
        context?.let { ctx ->
            if (isScreenReceiverRegistered && screenBroadcastReceiver != null) {
                try {
                    ctx.unregisterReceiver(screenBroadcastReceiver)
                    isScreenReceiverRegistered = false
                    if (debug) {
                        Log.d(TAG, "屏幕状态广播接收器已注销")
                    }
                } catch (e: Exception) {
                    if (debug) {
                        Log.e(TAG, "注销屏幕状态广播接收器失败", e)
                    }
                }
            }
        }
    }

    // 开始后台超时检测
    private fun startBackgroundTimeoutTimer() {
        stopBackgroundTimeoutTimer()

        if (!isBackgroundLockEnabled || isLocked) {
            return
        }

        if(debug){
            Log.d(TAG, "开始后台超时检测，超时时间: ${backgroundTimeout}ms")
        }
        
        backgroundStartTime = System.currentTimeMillis()
        backgroundTimeoutHandler = Handler(Looper.getMainLooper())
        
        // 创建支持倒计时的Runnable
        backgroundTimeoutRunnable = createBackgroundCountdownRunnable()
        
        // 如果debug模式，每秒执行一次以显示倒计时，否则直接延迟到超时时间
        val delayTime = if (debug) 1000L else backgroundTimeout
        backgroundTimeoutHandler?.postDelayed(backgroundTimeoutRunnable!!, delayTime)
    }
    
    private fun createBackgroundCountdownRunnable(): Runnable {
        return object : Runnable {
            override fun run() {
                val currentTime = System.currentTimeMillis()
                val elapsedTime = currentTime - backgroundStartTime
                val remainingTime = backgroundTimeout - elapsedTime
                
                if (remainingTime <= 0) {
                    // 超时，执行锁定逻辑
                    handleBackgroundTimeout()
                } else if (debug) {
                    // debug模式下打印倒计时
                    val remainingSeconds = (remainingTime / 1000).toInt()
                    Log.d(TAG, "后台倒计时: ${remainingSeconds}秒")
                    
                    // 继续倒计时，每秒执行一次
                    backgroundTimeoutHandler?.postDelayed(this, 1000L)
                } else {
                    // 非debug模式，直接延迟到剩余时间后执行
                    backgroundTimeoutHandler?.postDelayed(this, remainingTime)
                }
            }
        }
    }

    private fun handleBackgroundTimeout() {
        if (debug) {
            Log.d(TAG, "后台超时发生")
        }
        isLocked = true
        stopAllTimers()
        removeTouchListener()
        invokeMethod("onAppLocked", mapOf("reason" to "backgroundTimeout"))
    }

    private fun stopBackgroundTimeoutTimer() {
        try {
            backgroundTimeoutRunnable?.let {
                backgroundTimeoutHandler?.removeCallbacks(it)
                backgroundTimeoutRunnable = null
                backgroundTimeoutHandler = null
                if (debug) {
                    Log.d(TAG, "停止后台超时检测")
                }
            }
        } catch (e: Exception) {
            if (debug) {
                Log.e(TAG, "停止后台超时定时器失败", e)
            }
        }
    }

    // 触摸超时相关方法
    private fun startTouchTimeout() {
        stopTouchTimeout()
        
        if (!isTouchTimeoutEnabled || isLocked) {
            return
        }

        if (debug) {
            Log.d(TAG, "开始触摸超时检测，超时时间: ${touchTimeout}ms")
        }

        touchStartTime = System.currentTimeMillis()
        touchTimeoutHandler = Handler(Looper.getMainLooper())
        
        // 创建支持倒计时的Runnable
        touchTimeoutRunnable = createTouchCountdownRunnable()
        
        // 如果debug模式，每秒执行一次以显示倒计时，否则直接延迟到超时时间
        val delayTime = if (debug) 1000L else touchTimeout
        touchTimeoutHandler?.postDelayed(touchTimeoutRunnable!!, delayTime)
    }
    
    private fun createTouchCountdownRunnable(): Runnable {
        return object : Runnable {
            override fun run() {
                val currentTime = System.currentTimeMillis()
                val elapsedTime = currentTime - touchStartTime
                val remainingTime = touchTimeout - elapsedTime
                
                if (remainingTime <= 0) {
                    // 超时，执行锁定逻辑
                    handleTouchTimeout()
                } else if (debug) {
                    // debug模式下打印倒计时
                    val remainingSeconds = (remainingTime / 1000).toInt()
                    Log.d(TAG, "触摸倒计时: ${remainingSeconds}秒")
                    
                    // 继续倒计时，每秒执行一次
                    touchTimeoutHandler?.postDelayed(this, 1000L)
                } else {
                    // 非debug模式，直接延迟到剩余时间后执行
                    touchTimeoutHandler?.postDelayed(this, remainingTime)
                }
            }
        }
    }

    private fun handleTouchTimeout() {
        if (debug) {
            Log.d(TAG, "触摸超时发生")
        }
        isLocked = true
        stopAllTimers()
        removeTouchListener()
        invokeMethod("onAppLocked", mapOf("reason" to "touchTimeout"))
    }
    
    private fun stopTouchTimeout() {
        try {
            touchTimeoutRunnable?.let {
                touchTimeoutHandler?.removeCallbacks(it)
                touchTimeoutRunnable = null
                touchTimeoutHandler = null
                if (debug) {
                    Log.d(TAG, "停止触摸超时检测")
                }
            }
        } catch (e: Exception) {
            if (debug) {
                Log.e(TAG, "停止触摸超时定时器失败", e)
            }
        }
    }
    
    private fun restartTouchTimeout() {
        if (!isTouchTimeoutEnabled || isLocked) {
            return
        }

        if (debug) {
            Log.d(TAG, "重新开始触摸超时检测")
        }
        startTouchTimeout()
    }
    
    // 从按钮重启触摸定时器（需要重新设置监听器）
    private fun restartTouchTimeoutFromButton() {
        if (!isTouchTimeoutEnabled || isLocked) {
            return
        }

        if (debug) {
            Log.d(TAG, "从按钮重启触摸超时检测")
        }
        // 重新设置触摸事件监听器和重启定时器
        setupTouchListener()
        startTouchTimeout()
    }

    // 设置触摸监听器
    private fun setupTouchListener() {
        activity?.let { act ->
            if (!isTouchListenerSetup && isTouchTimeoutEnabled && !isLocked) {
                try {
                    // 使用Window.Callback拦截所有触摸事件（包括Platform View）
                    val window = act.window
                    if (originalCallback == null) {
                        originalCallback = window.callback
                    }
                    
                    window.callback = object : android.view.Window.Callback by originalCallback!! {
                        override fun dispatchTouchEvent(event: MotionEvent?): Boolean {
                            event?.let { ev ->
                                when (ev.action) {
                                    MotionEvent.ACTION_DOWN,
                                    MotionEvent.ACTION_MOVE,
                                    MotionEvent.ACTION_UP -> {
                                        val currentTime = System.currentTimeMillis()
                                        // 防止重复触发，至少间隔50ms
                                        if (currentTime - lastTouchTime > 50) {
                                            lastTouchTime = currentTime
                                            onUserInteraction()
                                            if (debug) {
                                                Log.d(TAG, "Window触摸事件检测: ${ev.action}")
                                            }
                                        }
                                    }
                                }
                            }
                            // 继续传递事件给原始callback
                            return originalCallback?.dispatchTouchEvent(event) ?: false
                        }
                    }
                    
                    isTouchListenerSetup = true
                    if (debug) {
                        Log.d(TAG, "Window触摸拦截器已设置（可捕获Platform View事件）")
                    }
                } catch (e: Exception) {
                    if (debug) {
                        Log.e(TAG, "设置触摸监听器失败", e)
                    }
                }
            }
        }
    }

    // 移除触摸监听器
    private fun removeTouchListener() {
        if (isTouchListenerSetup) {
            try {
                activity?.let { act ->
                    try {
                        // 恢复原始的Window.Callback
                        if (originalCallback != null) {
                            act.window.callback = originalCallback
                        }
                    } catch (e: Exception) {
                        if (debug) {
                            Log.e(TAG, "恢复Window.Callback失败", e)
                        }
                    }
                }
                isTouchListenerSetup = false
                touchListener = null
                if (debug) {
                    Log.d(TAG, "Window触摸拦截器已移除")
                }
            } catch (e: Exception) {
                if (debug) {
                    Log.e(TAG, "移除触摸监听器失败", e)
                }
            }
        }
    }

    // 公共方法：用户交互时调用此方法重置触摸计时器
    fun onUserInteraction() {
        if (isTouchTimeoutEnabled && !isLocked) {
            if (debug) {
                Log.d(TAG, "用户交互，重置触摸超时计时器")
            }
            restartTouchTimeout()
        }
    }

    private fun stopAllTimers() {
        stopBackgroundTimeoutTimer()
        stopTouchTimeout()
        stopScreenDetection()
    }

    private fun invokeMethod(method: String, arguments: Any?) {
        try {
            Handler(Looper.getMainLooper()).post {
                try {
                    channel.invokeMethod(method, arguments)
                } catch (e: Exception) {
                    if (debug) {
                        Log.e(TAG, "调用方法 $method 失败，可能是Flutter引擎已销毁", e)
                    }
                }
            }
        } catch (e: Exception) {
            if (debug) {
                Log.e(TAG, "Post invokeMethod $method 失败", e)
            }
        }
    }

    // Application.ActivityLifecycleCallbacks 实现
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (debug) {
            Log.d(TAG, "onActivityCreated: ${activity.localClassName}")
        }
    }
    
    override fun onActivityStarted(activity: Activity) {
        if (debug) {
            Log.d(TAG, "onActivityStarted: ${activity.localClassName}")
        }
    }

    override fun onActivityResumed(activity: Activity) {
        if (debug) {
            Log.d(TAG, "onActivityResumed: ${activity.localClassName}")
        }
        if (isInBackground) {
            if (debug) {
                Log.d(TAG, "App 进入前台")
            }
            isInBackground = false
            stopAllTimers()
            
            // 如果触摸超时启用且未锁定，启动触摸超时
            if (isTouchTimeoutEnabled && !isLocked) {
                setupTouchListener()
                startTouchTimeout()
            }
            
            invokeMethod("onEnterForeground", null)
            // 注意：不再在进入前台时自动触发解锁回调
            // 应用解锁应该由用户通过 UI 操作手动触发（调用 setLocked(false)）
        }
    }

    override fun onActivityPaused(activity: Activity) {
        if (debug) {
            Log.d(TAG, "onActivityPaused: ${activity.localClassName}")
        }
        if (!isInBackground) {
            if (debug) {
                Log.d(TAG, "App 进入后台")
            }
            isInBackground = true
            backgroundTimestamp = System.currentTimeMillis()
            
            // 移除触摸监听器和停止触摸倒计时
            removeTouchListener()
            stopTouchTimeout()
            
            invokeMethod("onEnterBackground", null)
            
            // 只启动已启用的后台检测
            if (isBackgroundLockEnabled) {
                startBackgroundTimeoutTimer()
            }
            
            // 屏幕锁定检测不需要在后台启动，它应该一直在监听屏幕状态广播
        }
    }

    override fun onActivityStopped(activity: Activity) {
        if (debug) {
            Log.d(TAG, "onActivityStopped: ${activity.localClassName}")
        }
    }
    
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        if (debug) {
            Log.d(TAG, "onActivitySaveInstanceState: ${activity.localClassName}")
        }
    }
    
    override fun onActivityDestroyed(activity: Activity) {
        if (debug) {
            Log.d(TAG, "onActivityDestroyed: ${activity.localClassName}")
        }
        
        // 当Activity被销毁时，清理所有定时器和监听器
        stopAllTimers()
        removeTouchListener()
        
        // 仅在销毁的是当前Activity时才清空activity引用
        if (activity == this.activity) {
            this.activity = null
        }
    }

    // ActivityAware 实现
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (debug) {
            Log.d(TAG, "onAttachedToActivity: ${activity?.localClassName}")
        }
        
        // 如果触摸超时已启用，设置触摸监听
        if (isTouchTimeoutEnabled && !isLocked) {
            setupTouchListener()
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        if (debug) {
            Log.d(TAG, "onDetachedFromActivityForConfigChanges")
        }
        removeTouchListener()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (debug) {
            Log.d(TAG, "onReattachedToActivityForConfigChanges: ${activity?.localClassName}")
        }
        
        // 重新设置触摸监听
        if (isTouchTimeoutEnabled && !isLocked) {
            setupTouchListener()
        }
    }

    override fun onDetachedFromActivity() {
        if (debug) {
            Log.d(TAG, "onDetachedFromActivity")
        }
        removeTouchListener()
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (debug) {
            Log.d(TAG, "onDetachedFromEngine")
        }
        
        try {
            // 设置null之前停止处理方法调用
            channel.setMethodCallHandler(null)
        } catch (e: Exception) {
            if (debug) {
                Log.e(TAG, "setMethodCallHandler failed", e)
            }
        }
        
        // 清理所有资源
        stopAllTimers()
        removeTouchListener()
        
        // 禁用录屏防护
        setScreenRecordingProtectionEnabled(false)
        
        // 注销生命周期回调
        try {
            context?.let { ctx ->
                if (ctx is Application) {
                    ctx.unregisterActivityLifecycleCallbacks(this)
                }
            }
        } catch (e: Exception) {
            if (debug) {
                Log.e(TAG, "unregisterActivityLifecycleCallbacks failed", e)
            }
        }
        
        isListening = false
        activity = null
        context = null
    }

    // MARK: - 录屏防护方法
    
    /// 设置录屏防护
    /// [warningMessage] 可选的警告文本参数（供iOS使用）
    private fun setScreenRecordingProtectionEnabled(enabled: Boolean, warningMessage: String? = null) {
        isScreenRecordingProtectionEnabled = enabled
        
        activity?.let { act ->
            try {
                if (enabled) {
                    // 启用录屏防护：禁止对窗口内容进行录屏
                    // 在Android中，可以通过FLAG_SECURE标志禁止屏幕录制
                    act.window.setFlags(
                        android.view.WindowManager.LayoutParams.FLAG_SECURE,
                        android.view.WindowManager.LayoutParams.FLAG_SECURE
                    )
                    
                    if (debug) {
                        Log.d(TAG, "Screen recording protection enabled")
                        if (warningMessage != null) {
                            Log.d(TAG, "Warning message: $warningMessage")
                        }
                    }
                } else {
                    // 禁用录屏防护：移除FLAG_SECURE标志
                    act.window.clearFlags(
                        android.view.WindowManager.LayoutParams.FLAG_SECURE
                    )
                    
                    if (debug) {
                        Log.d(TAG, "Screen recording protection disabled")
                    }
                }
            } catch (e: Exception) {
                if (debug) {
                    Log.e(TAG, "Failed to set screen recording protection", e)
                }
            }
        }
    }
}

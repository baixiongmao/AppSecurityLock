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

    // 生命周期状态
    private var isInBackground = false
    private var backgroundTimestamp = 0L
    
    // 广播接收器
    private var screenBroadcastReceiver: BroadcastReceiver? = null
    private var isScreenReceiverRegistered = false
    
    // 触摸监听相关
    private var touchListener: View.OnTouchListener? = null
    private var isTouchListenerSetup = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // 注册应用生命周期监听
        if (context is Application) {
            (context as Application).registerActivityLifecycleCallbacks(this)
        }
        
        Log.d(TAG, "AppSecurityLockPlugin attached to engine")
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

        if (debug) {
            Log.d(
                TAG,
                "初始化参数 - isScreenLockEnabled: $isScreenLockEnabled, " +
                "isBackgroundLockEnabled: $isBackgroundLockEnabled, " +
                "backgroundTimeout: $backgroundTimeout, " +
                "isTouchTimeoutEnabled: $isTouchTimeoutEnabled, " +
            "touchTimeout: $touchTimeout"
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
        isLocked = enabled
        if (debug) {
            Log.d(TAG, "Lock state changed to: $enabled")
        }

        // 如果解锁，重新启动触摸超时功能
        if (!enabled && isTouchTimeoutEnabled) {
            setupTouchListener()
            startTouchTimeout()
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
                                invokeMethod("onAppLocked", null)
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
        backgroundTimeoutHandler = Handler(Looper.getMainLooper())
        backgroundTimeoutRunnable = Runnable {
            handleBackgroundTimeout()
        }
        backgroundTimeoutHandler?.postDelayed(backgroundTimeoutRunnable!!, backgroundTimeout)
    }

    private fun handleBackgroundTimeout() {
        if (debug) {
            Log.d(TAG, "后台超时发生")
        }
        isLocked = true
        stopAllTimers()
        removeTouchListener()
        invokeMethod("onAppLocked", null)
    }

    private fun stopBackgroundTimeoutTimer() {
        backgroundTimeoutRunnable?.let {
            backgroundTimeoutHandler?.removeCallbacks(it)
            backgroundTimeoutRunnable = null
            backgroundTimeoutHandler = null
            if (debug) {
                Log.d(TAG, "停止后台超时检测")
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

        touchTimeoutHandler = Handler(Looper.getMainLooper())
        touchTimeoutRunnable = Runnable {
            handleTouchTimeout()
        }
        
        touchTimeoutHandler?.postDelayed(touchTimeoutRunnable!!, touchTimeout)
    }

    private fun handleTouchTimeout() {
        if (debug) {
            Log.d(TAG, "触摸超时发生")
        }
        isLocked = true
        stopAllTimers()
        removeTouchListener()
        invokeMethod("onAppLocked", null)
    }
    
    private fun stopTouchTimeout() {
        touchTimeoutRunnable?.let {
            touchTimeoutHandler?.removeCallbacks(it)
            touchTimeoutRunnable = null
            touchTimeoutHandler = null
            if (debug) {
                Log.d(TAG, "停止触摸超时检测")
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
                    // 创建触摸监听器
                    touchListener = View.OnTouchListener { _, event ->
                        when (event.action) {
                            MotionEvent.ACTION_DOWN,
                            MotionEvent.ACTION_MOVE,
                            MotionEvent.ACTION_UP -> {
                                onUserInteraction()
                            }
                        }
                        false // 不消费事件，让其他组件继续处理
                    }

                    // 获取根视图并设置触摸监听器
                    val rootView = act.findViewById<View>(android.R.id.content)
                    rootView?.let { root ->
                        if (root is ViewGroup) {
                            setTouchListenerRecursively(root)
                        } else {
                            root.setOnTouchListener(touchListener)
                        }
                        isTouchListenerSetup = true
                        if (debug) {
                            Log.d(TAG, "触摸监听器已设置")
                        }
                    }
                } catch (e: Exception) {
                    if (debug) {
                        Log.e(TAG, "设置触摸监听器失败", e)
                    }
                }
            }
        }
    }

    // 递归设置触摸监听器
    private fun setTouchListenerRecursively(viewGroup: ViewGroup) {
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i)
            if (child is ViewGroup) {
                setTouchListenerRecursively(child)
            }
            child.setOnTouchListener(touchListener)
        }
    }

    // 移除触摸监听器
    private fun removeTouchListener() {
        if (isTouchListenerSetup) {
            activity?.let { act ->
                try {
                    val rootView = act.findViewById<View>(android.R.id.content)
                    rootView?.let { root ->
                        if (root is ViewGroup) {
                            removeTouchListenerRecursively(root)
                        } else {
                            root.setOnTouchListener(null)
                        }
                    }
                    isTouchListenerSetup = false
                    touchListener = null
                    if (debug) {
                        Log.d(TAG, "触摸监听器已移除")
                    }
                } catch (e: Exception) {
                    if (debug) {
                        Log.e(TAG, "移除触摸监听器失败", e)
                    }
                }
            }
        }
    }

    // 递归移除触摸监听器
    private fun removeTouchListenerRecursively(viewGroup: ViewGroup) {
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i)
            if (child is ViewGroup) {
                removeTouchListenerRecursively(child)
            }
            child.setOnTouchListener(null)
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
                channel.invokeMethod(method, arguments)
            }
        } catch (e: Exception) {
            if (debug) {
                Log.e(TAG, "调用方法 $method 失败", e)
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
            if (isLocked) {
                invokeMethod("onAppUnlocked", null)
            }
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
            
            // 移除触摸监听器
            removeTouchListener()
            
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
        channel.setMethodCallHandler(null)
        stopAllTimers()
        removeTouchListener()
        
        context?.let { ctx ->
            if (ctx is Application) {
                ctx.unregisterActivityLifecycleCallbacks(this)
            }
        }
        
        context = null
    }
}

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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // 注册应用生命周期监听
        if (context is Application) {
            (context as Application).registerActivityLifecycleCallbacks(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "init" -> {
                handleInit(call, result)
            }

            "setLockEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                isLocked = enabled
                result.success(null)
            }

            "setScreenLockEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                isScreenLockEnabled = enabled
                result.success(null)
            }

            "setBackgroundLockEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                isBackgroundLockEnabled = enabled
                result.success(null)
            }

            "setBackgroundTimeout" -> {
                val timeout = call.argument<Double>("timeout") ?: 60.0
                backgroundTimeout = (timeout * 1000).toLong() // 转换为毫秒
                Log.d(TAG, "Background timeout set to $backgroundTimeout ms")
                result.success(null)
            }

            "setTouchTimeout" -> {
                val timeout = call.argument<Double>("timeout") ?: 30.0
                touchTimeout = (timeout * 1000).toLong() // 转换为毫秒
                Log.d(TAG, "Touch timeout set to $touchTimeout ms")
                result.success(null)
            }

            "setTouchTimeoutEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                isTouchTimeoutEnabled = enabled
                Log.d(TAG, "Touch timeout enabled: $isTouchTimeoutEnabled")
                if (enabled) {
                    startTouchTimeout()
                } else {
                    stopTouchTimeout()
                }
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

        Log.d(
            TAG,
            "初始化参数 - isScreenLockEnabled: $isScreenLockEnabled, isBackgroundLockEnabled: $isBackgroundLockEnabled, backgroundTimeout: $backgroundTimeout, isTouchTimeoutEnabled: $isTouchTimeoutEnabled, touchTimeout: $touchTimeout"
        )
        result.success(null)
    }

    private fun startListen() {
        if (isListening) {
            return
        }
        isListening = true
        Log.d(TAG, "开始监听应用生命周期")
    }

    // 开始屏幕状态检测（使用广播接收器）
    private fun startScreenDetection() {
        stopScreenDetection()

        if (!isScreenLockEnabled || isLocked) {
            return
        }

        Log.d(TAG, "开始屏幕状态检测")
        initScreenBroadcastReceiver()
        registerScreenReceiver()
    }
    
    private fun initScreenBroadcastReceiver() {
        if (screenBroadcastReceiver == null) {
            screenBroadcastReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    when (intent.action) {
                        Intent.ACTION_SCREEN_OFF -> {
                            Log.d(TAG, "屏幕关闭，锁定应用")
                            if (!isLocked) {
                                isLocked = true
                                stopAllTimers()
                                invokeMethod("onAppLocked", null)
                            }
                        }
                        Intent.ACTION_SCREEN_ON -> {
                            Log.d(TAG, "屏幕开启")
                            // 屏幕开启时不自动解锁，需要用户解锁
                        }
                        Intent.ACTION_USER_PRESENT -> {
                            Log.d(TAG, "用户解锁设备")
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
                    ctx.registerReceiver(screenBroadcastReceiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
                    ctx.registerReceiver(screenBroadcastReceiver, IntentFilter(Intent.ACTION_SCREEN_ON))
                    ctx.registerReceiver(screenBroadcastReceiver, IntentFilter(Intent.ACTION_USER_PRESENT))
                    isScreenReceiverRegistered = true
                    Log.d(TAG, "屏幕状态广播接收器已注册")
                } catch (e: Exception) {
                    Log.e(TAG, "注册屏幕状态广播接收器失败", e)
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
                    Log.d(TAG, "屏幕状态广播接收器已注销")
                } catch (e: Exception) {
                    Log.e(TAG, "注销屏幕状态广播接收器失败", e)
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

        Log.d(TAG, "开始后台超时检测，超时时间: ${backgroundTimeout}ms")
        backgroundTimeoutHandler = Handler(Looper.getMainLooper())
        backgroundTimeoutRunnable = Runnable {
            handleBackgroundTimeout()
        }
        backgroundTimeoutHandler?.postDelayed(backgroundTimeoutRunnable!!, backgroundTimeout)
    }

    private fun handleBackgroundTimeout() {
        Log.d(TAG, "后台超时发生")
        isLocked = true
        stopAllTimers()
        invokeMethod("onAppLocked", null)
    }

    private fun stopBackgroundTimeoutTimer() {
        backgroundTimeoutRunnable?.let {
            backgroundTimeoutHandler?.removeCallbacks(it)
            backgroundTimeoutRunnable = null
            backgroundTimeoutHandler = null
            Log.d(TAG, "停止后台超时检测")
        }
    }

    // 触摸超时相关方法
    private fun startTouchTimeout() {
        stopTouchTimeout()
        
        if (!isTouchTimeoutEnabled || isLocked) {
            return
        }
        
        Log.d(TAG, "开始触摸超时检测，超时时间: ${touchTimeout}ms")
        
        touchTimeoutHandler = Handler(Looper.getMainLooper())
        touchTimeoutRunnable = Runnable {
            Log.d(TAG, "触摸超时，锁定应用")
            isLocked = true
            invokeMethod("onAppLocked", null)
        }
        
        touchTimeoutHandler?.postDelayed(touchTimeoutRunnable!!, touchTimeout)
    }
    
    private fun stopTouchTimeout() {
        touchTimeoutHandler?.removeCallbacks(touchTimeoutRunnable ?: return)
        touchTimeoutHandler = null
        touchTimeoutRunnable = null
        Log.d(TAG, "停止触摸超时检测")
    }
    
    private fun restartTouchTimeout() {
        if (!isTouchTimeoutEnabled || isLocked) {
            return
        }
        
        Log.d(TAG, "重新开始触摸超时检测")
        startTouchTimeout()
    }

    private fun stopAllTimers() {
        stopBackgroundTimeoutTimer()
        stopTouchTimeout()
        stopScreenDetection()
    }

    private fun invokeMethod(method: String, arguments: Any?) {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(method, arguments)
        }
    }

    // Application.ActivityLifecycleCallbacks 实现
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}

    override fun onActivityResumed(activity: Activity) {
        if (isInBackground) {
            Log.d(TAG, "App 进入前台")
            isInBackground = false
            stopAllTimers()
            startTouchTimeout()  // 进入前台时启动触摸超时
            invokeMethod("onEnterForeground", null)
            if (isLocked) {
                invokeMethod("onAppUnlocked", null)
            }
        }
    }

    override fun onActivityPaused(activity: Activity) {
        if (!isInBackground) {
            Log.d(TAG, "App 进入后台")
            isInBackground = true
            backgroundTimestamp = System.currentTimeMillis()
            invokeMethod("onEnterBackground", null)
            startScreenDetection()
            startBackgroundTimeoutTimer()
        }
    }

    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}

    // ActivityAware 实现
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAllTimers()
        context?.let { ctx ->
            if (ctx is Application) {
                ctx.unregisterActivityLifecycleCallbacks(this)
            }
        }
    }
}

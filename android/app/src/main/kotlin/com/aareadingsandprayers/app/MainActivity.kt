package com.aareadingsandprayers.app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.aareadingsandprayers.app/keep_alive"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "keepScreenOn" -> {
                    val keepOn = call.argument<Boolean>("keepOn") ?: false
                    if (keepOn) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                "keepCpuAwake" -> {
                    val keepAwake = call.argument<Boolean>("keepAwake") ?: false
                    if (keepAwake) {
                        acquireWakeLock()
                    } else {
                        releaseWakeLock()
                    }
                    result.success(null)
                }
                "startTtsService" -> {
                    startTtsService()
                    result.success(null)
                }
                "stopTtsService" -> {
                    stopTtsService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Don't keep screen on by default - let it sleep naturally
        // TTS will use wake lock to keep CPU running when needed
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return // Already holding wake lock
        }
        
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AAReadings::TTS_PLAYBACK"
        )
        // Acquire for 30 minutes to handle long multiple readings
        wakeLock?.acquire(30*60*1000L /*30 minutes*/)
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    override fun onDestroy() {
        releaseWakeLock()
        stopTtsService()
        super.onDestroy()
    }

    private fun startTtsService() {
        if (!TtsService.isRunning()) {
            val intent = Intent(this, TtsService::class.java)
            startForegroundService(intent)
        }
    }

    private fun stopTtsService() {
        if (TtsService.isRunning()) {
            val intent = Intent(this, TtsService::class.java)
            stopService(intent)
        }
    }
}

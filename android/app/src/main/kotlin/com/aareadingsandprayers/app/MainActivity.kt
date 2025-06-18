package com.aareadingsandprayers.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import androidx.core.view.WindowCompat
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.aareadingsandprayers.app/edge_to_edge"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ compatibility
        // This avoids the deprecated color setting APIs
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableEdgeToEdge" -> {
                    try {
                        // Modern edge-to-edge implementation without deprecated APIs
                        WindowCompat.setDecorFitsSystemWindows(window, false)
                        result.success("Edge-to-edge enabled")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to enable edge-to-edge", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

package com.example.native_ringer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NativeRingerPlugin */
class NativeRingerPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_ringer")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "checkDndPermission" -> {
                result.success(checkDndPermission())
            }
            "requestDndPermission" -> {
                requestDndPermission()
                result.success(null)
            }
            "requestBatteryOptimization" -> {
                requestBatteryOptimization()
                result.success(null)
            }
            "setRingerMode" -> {
                val mode = call.argument<String>("mode")
                if (mode != null) {
                    setRingerMode(mode)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Mode is required", null)
                }
            }
            "isIgnoringBatteryOptimizations" -> {
                result.success(isIgnoringBatteryOptimizations())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
            return powerManager.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true
    }

    private fun checkDndPermission(): Boolean {
        val notificationManager = context.getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            notificationManager.isNotificationPolicyAccessGranted
        } else {
            true
        }
    }

    private fun requestDndPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val intent = android.content.Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    private fun requestBatteryOptimization() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = android.net.Uri.parse("package:${context.packageName}")
            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                context.startActivity(intent)
            } catch (e: Exception) {
                // Fallback to generic settings if specific intent fails
                val settingsIntent = android.content.Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                settingsIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(settingsIntent)
            }
        }
    }

    private fun setRingerMode(mode: String) {
        val audioManager = context.getSystemService(android.content.Context.AUDIO_SERVICE) as android.media.AudioManager
        
        // Check DND permission first
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val notificationManager = context.getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            if (!notificationManager.isNotificationPolicyAccessGranted) {
                println("DND Permission not granted. Cannot change ringer mode.")
                return
            }
        }

        if (mode == "vibrate") {
            // User requested fix: Set Ring Volume to 0
            try {
                audioManager.setStreamVolume(android.media.AudioManager.STREAM_RING, 0, 0)
            } catch (e: Exception) {
                println("Error setting volume to 0: ${e.message}")
            }
            audioManager.ringerMode = android.media.AudioManager.RINGER_MODE_VIBRATE
        } else if (mode == "normal") {
            audioManager.ringerMode = android.media.AudioManager.RINGER_MODE_NORMAL
            // User requested fix: Set Ring Volume to Max (or reasonable level)
            try {
                val maxVolume = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_RING)
                // Set to max volume as requested
                audioManager.setStreamVolume(android.media.AudioManager.STREAM_RING, maxVolume, 0)
            } catch (e: Exception) {
                println("Error setting volume to max: ${e.message}")
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

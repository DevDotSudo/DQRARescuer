package com.dqra.rescuer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Context
import android.media.AudioManager
import android.util.Log

class MainActivity: FlutterActivity() {
    private val MAIN_CHANNEL = "com.dqra.rescuer/main"
    private val EMERGENCY_CHANNEL = "com.dqra.rescuer/emergency"
    private val PERMISSION_REQUEST_CODE = 1001
    private var emergencyEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method Channel for service control
        MethodChannel(flutterEngine.dartExecutor, MAIN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> handleInitialize(result)
                "startBackgroundService" -> handleStartService(call, result)
                "stopBackgroundService" -> handleStopService(result)
                else -> result.notImplemented()
            }
        }
        
        // Event Channel for emergency notifications
        EventChannel(flutterEngine.dartExecutor, EMERGENCY_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    emergencyEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    emergencyEventSink = null
                }
            }
        )
    }

    private fun handleInitialize(result: MethodChannel.Result) {
        // Initialize any required components
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        result.success(null)
    }

    private fun handleStartService(call: MethodCall, result: MethodChannel.Result) {
        val municipality = call.argument<String>("municipality") ?: run {
            result.error("INVALID_ARGUMENT", "Municipality cannot be null", null)
            return
        }
        val rescuerName = call.argument<String>("rescuerName") ?: run {
            result.error("INVALID_ARGUMENT", "Rescuer name cannot be null", null)
            return
        }

        if (checkAndRequestPermissions()) {
            startForegroundService(municipality, rescuerName, result)
        } else {
            result.error("PERMISSION_REQUIRED", "Need permissions to start service", null)
        }
    }

    private fun startForegroundService(municipality: String, rescuerName: String, result: MethodChannel.Result) {
        val intent = Intent(this, ForegroundService::class.java).apply {
            putExtra("municipality", municipality)
            putExtra("rescuerName", rescuerName)
        }
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            result.success("Service started successfully")
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to start service: ${e.message}", null)
        }
    }

    private fun handleStopService(result: MethodChannel.Result) {
        try {
            val intent = Intent(this, ForegroundService::class.java)
            stopService(intent)
            result.success("Service stopped successfully")
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to stop service: ${e.message}", null)
        }
    }

    private fun checkAndRequestPermissions(): Boolean {
        val requiredPermissions = mutableListOf(
            Manifest.permission.FOREGROUND_SERVICE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requiredPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun sendEmergencyEvent(data: Map<String, Any>) {
        emergencyEventSink?.success(data)
    }
}
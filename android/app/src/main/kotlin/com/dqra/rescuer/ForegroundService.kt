package com.dqra.rescuer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Resources
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class ForegroundService : Service() {
    private lateinit var emergencyChannel: MethodChannel
    private var municipality: String? = null
    private var rescuerName: String? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var firestoreListener: com.google.firebase.firestore.ListenerRegistration? = null
    private var mediaPlayer: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var originalVolume: Int = 0
    private var isServiceRunning = false
    private var isAlarmPlaying = false

    companion object {
        private const val STOP_ALARM_ACTION = "STOP_ALARM_ACTION"
        private const val NOTIFICATION_ID = 1
    }

    override fun onCreate() {
        super.onCreate()
        setupEmergencyChannel()
        acquireWakeLock()
        initializeAudio()
    }

    private fun initializeAudio() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        originalVolume = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
    }

    private fun setupEmergencyChannel() {
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        emergencyChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.dqra.rescuer/emergency"
        )
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Rescuer:EmergencyWakeLock"
        ).apply {
            acquire(10 * 60 * 1000L /*10 minutes*/)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            STOP_ALARM_ACTION -> {
                stopEmergencyAlarm()
                return START_STICKY
            }
        }

        if (isServiceRunning) {
            return START_STICKY
        }

        municipality = intent?.getStringExtra("municipality")
        rescuerName = intent?.getStringExtra("rescuerName")
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createForegroundNotification())
        startEmergencyMonitoring()
        
        isServiceRunning = true
        return START_STICKY
    }

    private fun playEmergencyAlarm() {
        try {
            mediaPlayer?.release()
            
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                )
                
                val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 0
                audioManager?.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume, 0)
                
                val packageName = applicationContext.packageName
                val resourceId = resources.getIdentifier(
                    "alert_sound", 
                    "raw", 
                    packageName
                )
                
                if (resourceId == 0) {
                    throw Resources.NotFoundException("Raw resource alert_sound not found")
                }
                
                val soundUri = Uri.parse("android.resource://$packageName/$resourceId")
                setDataSource(applicationContext, soundUri)
                
                prepare()
                start()
                isLooping = true
                isAlarmPlaying = true
                
                // Update notification to show stop button
                updateNotification()
                
                setOnErrorListener { _, what, extra ->
                    emergencyChannel.invokeMethod("onError", mapOf(
                        "error" to "MediaPlayer error: what=$what extra=$extra"
                    ))
                    stopEmergencyAlarm()
                    true
                }
            }
        } catch (e: IOException) {
            emergencyChannel.invokeMethod("onError", mapOf(
                "error" to "Failed to play alarm: ${e.message}"
            ))
            stopEmergencyAlarm()
        } catch (e: Exception) {
            emergencyChannel.invokeMethod("onError", mapOf(
                "error" to "Unexpected error: ${e.message}"
            ))
            stopEmergencyAlarm()
        }
    }

    private fun stopEmergencyAlarm() {
        try {
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
            }
            mediaPlayer = null
            audioManager?.setStreamVolume(AudioManager.STREAM_MUSIC, originalVolume, 0)
            isAlarmPlaying = false
            
            // Update notification to remove stop button
            updateNotification()
        } catch (e: Exception) {
            emergencyChannel.invokeMethod("onError", mapOf(
                "error" to "Failed to stop alarm: ${e.message}"
            ))
        }
    }

    private fun updateNotification() {
        val notification = createForegroundNotification()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createForegroundNotification(): Notification {
        val notificationBuilder = NotificationCompat.Builder(this, "FOREGROUND_CHANNEL")
            .setContentTitle("Emergency Monitoring Active")
            .setContentText("Listening for new emergencies in $municipality")
            .setSmallIcon(R.drawable.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)

        if (isAlarmPlaying) {
            val stopIntent = Intent(this, ForegroundService::class.java).apply {
                action = STOP_ALARM_ACTION
            }
            val stopPendingIntent = PendingIntent.getService(
                this,
                0,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            notificationBuilder.addAction(
                0, // No icon
                "Stop Alarm",
                stopPendingIntent
            )
        }

        return notificationBuilder.build()
    }

    private fun startEmergencyMonitoring() {
        try {
            municipality?.let { muni ->
                val firestore = Firebase.firestore
                
                firestoreListener?.remove()
                
                firestoreListener = firestore
                    .collection("EMERGENCY")
                    .document(muni)
                    .collection("LISTS")
                    .whereEqualTo("status", "pending")
                    .addSnapshotListener { snapshot, error ->
                        error?.let {
                            emergencyChannel.invokeMethod("onError", mapOf(
                                "error" to it.message
                            ))
                            return@addSnapshotListener
                        }

                        snapshot?.documentChanges?.forEach { change ->
                            if (change.type == com.google.firebase.firestore.DocumentChange.Type.ADDED) {
                                playEmergencyAlarm()
                                showEmergencyNotification(
                                    "Emergency Alert",
                                    "New emergency in $municipality"
                                )
                            }
                        }
                    }
            }
        } catch (e: Exception) {
            emergencyChannel.invokeMethod("onError", mapOf(
                "error" to "Firestore initialization failed: ${e.message}"
            ))
        }
    }

    private fun showEmergencyNotification(title: String, message: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, "FOREGROUND_CHANNEL")
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "FOREGROUND_CHANNEL",
                "Emergency Monitoring",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Emergency alerts channel"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        isServiceRunning = false
        stopEmergencyAlarm()
        firestoreListener?.remove()
        wakeLock?.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
package com.kyvronix.phoneguard.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.Manifest
import android.content.pm.PackageManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.kyvronix.phoneguard.location.LocationManager
import com.kyvronix.phoneguard.sms.SmsSender
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class TrackingService : Service() {
    private val CHANNEL_ID = "TrackingServiceChannel"
    private var isTracking = false
    private val handler = Handler(Looper.getMainLooper())
    private var trustedNumber = ""
    private var subscriptionId: Int = -1
    private val TRACKING_INTERVAL: Long = 3 * 60 * 1000 // 3 minutes

    private val trackingRunnable = object : Runnable {
        override fun run() {
            if (isTracking && trustedNumber.isNotEmpty()) {
                sendLocationUpdate()
                handler.postDelayed(this, TRACKING_INTERVAL)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Active Tracking")
            .setContentText("Continuous location tracking is active")
            .setSmallIcon(android.R.drawable.ic_dialog_map)
            .build()
        val hasLocationPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && hasLocationPermission) {
            startForeground(2, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            if (!hasLocationPermission) {
                Log.e("TrackingService", "Missing location permission for foreground service type 'location'")
            }
            startForeground(2, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val newNumber = intent?.getStringExtra("trustedNumber") ?: ""
        val newSubId = intent?.getIntExtra("subscriptionId", -1) ?: -1

        // Always update the target number from the latest intent.
        // This ensures if a different trusted number sends a trigger,
        // subsequent location updates go to that number, not the previous one.
        if (newNumber.isNotEmpty()) {
            trustedNumber = newNumber
            subscriptionId = newSubId
            Log.d("TrackingService", "Target updated to: $trustedNumber (subId=$subscriptionId)")
        }

        if (!isTracking) {
            isTracking = true
            handler.post(trackingRunnable)
            Log.d("TrackingService", "Tracking started for: $trustedNumber")
        }
        return START_NOT_STICKY
    }

    private fun sendLocationUpdate() {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val url = LocationManager(this@TrackingService).getCurrentLocationUrl()
                if (url != null) {
                    SmsSender.sendSmsWithSim(this@TrackingService, trustedNumber, "Live Tracking: $url", subscriptionId)
                }
            } catch (e: Exception) {
                Log.e("TrackingService", "Failed to send location update", e)
            }
        }
    }

    override fun onDestroy() {
        isTracking = false
        handler.removeCallbacks(trackingRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Tracking Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}

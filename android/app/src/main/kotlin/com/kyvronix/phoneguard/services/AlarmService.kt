package com.kyvronix.phoneguard.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.content.pm.ServiceInfo
import android.util.Log
import androidx.core.app.NotificationCompat
import com.kyvronix.phoneguard.alarm.AlarmController

class AlarmService : Service() {
    private val CHANNEL_ID = "AlarmServiceChannel"
    private lateinit var alarmController: AlarmController

    override fun onCreate() {
        super.onCreate()
        alarmController = AlarmController(this)
        createNotificationChannel()
        
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Loud Alarm Active")
            .setContentText("The recovery alarm is currently ringing")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(3, notification)
        } else {
            startForeground(3, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("AlarmService", "onStartCommand: Starting alarm siren")
        try {
            alarmController.startAlarm()
        } catch (e: Exception) {
            Log.e("AlarmService", "Failed to start alarm siren", e)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        alarmController.stopAlarm()
        super.onDestroy()
    }

    override fun onBind(intent: Intent): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Used for recovery siren alarm"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}

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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import java.net.NetworkInterface
import java.util.Collections
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Data

class RecoveryService : Service(), CoroutineScope by MainScope() {
    companion object {
        private const val TAG = "RecoveryService"
        private const val CHANNEL_ID = "RecoveryServiceChannel"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun getSafePrefs(): android.content.SharedPreferences {
        val safeContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            createDeviceProtectedStorageContext()
        } else {
            this
        }
        return safeContext.getSharedPreferences("InternalPhoneGuardPrefs", Context.MODE_PRIVATE)
    }

    private fun scheduleInitialSync() {
        val data = Data.Builder()
            .putString("event", "RECOVERY_STARTUP")
            .build()

        val syncRequest = OneTimeWorkRequestBuilder<SyncWorker>()
            .setInputData(data)
            .build()

        WorkManager.getInstance(applicationContext).enqueue(syncRequest)
        Log.d(TAG, "Scheduled startup sync via WorkManager")
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private fun getIpAddress(): String? {
        try {
            val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
            for (intf in interfaces) {
                val addrs = Collections.list(intf.inetAddresses)
                for (addr in addrs) {
                    if (!addr.isLoopbackAddress) {
                        val sAddr = addr.hostAddress
                        val isIPv4 = sAddr.indexOf(':') < 0
                        if (isIPv4) return sAddr
                    }
                }
            }
        } catch (e: Exception) {}
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Protection Active")
            .setContentText("Monitoring for remote recovery commands")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                } else {
                    0
                }
                if (type != 0) {
                    startForeground(1, notification, type)
                } else {
                    startForeground(1, notification)
                }
            } else {
                startForeground(1, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start RecoveryService in foreground: ${e.message}")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                stopSelf()
                return START_NOT_STICKY
            }
        }

        // Offload sync and firestore listeners
        scheduleInitialSync()
        
        try {
            val cmdIntent = Intent(this, FirestoreCommandService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(cmdIntent)
            } else {
                startService(cmdIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start FirestoreCommandService", e)
        }

        return START_STICKY
    }

    override fun onDestroy() {
        cancel()
        Log.d(TAG, "Service destroyed and scope cancelled")
        super.onDestroy()
    }

    override fun onBind(intent: Intent): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Recovery Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}

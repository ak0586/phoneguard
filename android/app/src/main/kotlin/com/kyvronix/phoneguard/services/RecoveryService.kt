package com.kyvronix.phoneguard.services
import java.util.concurrent.atomic.AtomicLong

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.content.pm.ServiceInfo
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.kyvronix.phoneguard.location.LocationManager
import com.kyvronix.phoneguard.sms.CommandParser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.net.NetworkInterface
import java.util.Collections
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Data

class RecoveryService : Service(), CoroutineScope by MainScope() {
    companion object {
        private const val TAG = "RecoveryService"
        private const val CHANNEL_ID = "RecoveryServiceChannel"
        
        // Static tracker to avoid double-processing even if service is recreated
        private val lastProcessedSmsId = AtomicLong(-1L)
        private val processingLock = Any()
    }

    private var smsObserver: ContentObserver? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // Register observer but don't call startForeground here.
        // It's more reliable in onStartCommand on many devices.
        registerSmsObserver()
    }

    private fun getSafePrefs(): android.content.SharedPreferences {
        val safeContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            createDeviceProtectedStorageContext()
        } else {
            this
        }
        return safeContext.getSharedPreferences("InternalPhoneGuardPrefs", Context.MODE_PRIVATE)
    }

    // ─── SMS ContentObserver (Bypass Broadcast Interception) ──────────────────

    private fun registerSmsObserver() {
        smsObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                checkForNewSms()
            }
        }
        contentResolver.registerContentObserver(
            Uri.parse("content://sms/inbox"), // inbox ONLY — prevents firing on outgoing sent replies
            true,
            smsObserver!!
        )
        Log.d(TAG, "SMS ContentObserver registered on inbox — messaging app bypass active")
    }

    private fun checkForNewSms() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val cursor = contentResolver.query(
                    Uri.parse("content://sms/inbox"),
                    arrayOf("_id", "address", "body", "date"),
                    null,
                    null,
                    "_id DESC LIMIT 1"
                ) ?: return@launch

                cursor.use {
                    if (it.moveToFirst()) {
                        val id   = it.getLong(it.getColumnIndexOrThrow("_id"))
                        val from = it.getString(it.getColumnIndexOrThrow("address")) ?: return@use
                        val body = it.getString(it.getColumnIndexOrThrow("body")) ?: return@use
                        val date = it.getLong(it.getColumnIndexOrThrow("date"))

                        // ATOMIC CLAIM PHASE: Lock, Check, and Set immediately
                        synchronized(processingLock) {
                            if (id <= lastProcessedSmsId.get()) return@use
                            
                            // Use SAFE prefs (Device Protected) for last_sms_id to work when locked
                            val safePrefs = getSafePrefs()
                            val storedLastId = safePrefs.getLong("phoneguard.last_sms_id", -1L)
                            
                            if (id <= storedLastId) {
                                lastProcessedSmsId.set(id)
                                return@use
                            }
                            
                            // Check persistent hash (stored by SmsReceiver) for immediate deduplication
                            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            val expectedHash = "${from.hashCode()}_${body.hashCode()}_${date}"
                            val storedHash = flutterPrefs.getString("phoneguard.last_sms_hash", null)
                            if (expectedHash == storedHash) {
                                Log.d(TAG, "ContentObserver: Hash match detected for id=$id, skipping")
                                lastProcessedSmsId.set(id)
                                return@use
                            }

                            // If we reach here, this thread HAS CLAIMED the ID.
                            lastProcessedSmsId.set(id)
                            safePrefs.edit().putLong("phoneguard.last_sms_id", id).apply()
                        }

                        // Give SmsReceiver (faster path) a small window to potentially finish
                        // If it finishes after our claim but before our parse, its own internal
                        // CommandParser deduplication will catch the duplicate.
                        kotlinx.coroutines.delay(50)

                        Log.d(TAG, "ContentObserver: processing new SMS id=$id from=$from")

                        launch {
                            CommandParser(this@RecoveryService).parseAndExecute(
                                sender = from,
                                message = body,
                                subscriptionId = -1,
                                smsTimestamp = date  // Same timestamp stored in SMS DB → dedup key matches SmsReceiver
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "ContentObserver SMS check failed", e)
            }
        }
    }

    private fun scheduleInitialSync() {
        val safePrefs = getSafePrefs()
        // Load last processed SMS ID from safe prefs to survive restarts
        lastProcessedSmsId.set(safePrefs.getLong("phoneguard.last_sms_id", -1L))

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
        smsObserver?.let { contentResolver.unregisterContentObserver(it) }
        smsObserver = null
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

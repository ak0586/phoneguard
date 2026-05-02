package com.kyvronix.phoneguard.services

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

class RecoveryService : Service(), CoroutineScope by MainScope() {
    companion object {
        private const val TAG = "RecoveryService"
        private const val CHANNEL_ID = "RecoveryServiceChannel"
        
        // Static tracker to avoid double-processing even if service is recreated
        private var lastProcessedSmsId: Long = -1L
    }

    private var smsObserver: ContentObserver? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Protection Active")
            .setContentText("Monitoring for remote recovery commands")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
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

        syncInitialState()
        registerSmsObserver()
        
        // Start Firestore listener for web dashboard commands
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
            Uri.parse("content://sms"),
            true,
            smsObserver!!
        )
        Log.d(TAG, "SMS ContentObserver registered — messaging app bypass active")
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

                        // Avoid double-processing if SmsReceiver already handled it (by ID)
                        if (id == lastProcessedSmsId) return@use

                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                        // Check persistent ID across restarts
                        val storedLastId = prefs.getLong("phoneguard.last_sms_id", -1L)
                        if (id == storedLastId) return@use

                        // Check the hash stored by SmsReceiver — closes the race window
                        val expectedHash = "${from.hashCode()}_${body.hashCode()}_${date}"
                        val storedHash = prefs.getString("phoneguard.last_sms_hash", null)
                        if (expectedHash == storedHash) {
                            Log.d(TAG, "ContentObserver: SMS already handled by SmsReceiver (hash match), skipping id=$id")
                            lastProcessedSmsId = id
                            return@use
                        }

                        lastProcessedSmsId = id
                        prefs.edit().putLong("phoneguard.last_sms_id", id).commit()

                        Log.d(TAG, "ContentObserver: new SMS id=$id from=$from body='$body'")

                        launch {
                            CommandParser(this@RecoveryService).parseAndExecute(
                                sender = from,
                                message = body,
                                subscriptionId = -1
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "ContentObserver SMS check failed", e)
            }
        }
    }

    // ─── Startup Firestore Sync ───────────────────────────────────────────────

    private fun syncInitialState() {
        val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val uid = sharedPrefs.getString("flutter.flutter.user_uid", null)

        // Load last processed SMS ID from prefs to survive restarts
        lastProcessedSmsId = sharedPrefs.getLong("phoneguard.last_sms_id", -1L)

        if (uid == null) {
            Log.w(TAG, "Sync skipped: No UID found")
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                if (com.google.firebase.FirebaseApp.getApps(this@RecoveryService).isEmpty()) {
                    Log.w(TAG, "Firebase not ready, syncing aborted")
                    return@launch
                }

                val location = LocationManager(this@RecoveryService).getCurrentLocation()
                val ip = getIpAddress()
                
                val updates = mutableMapOf<String, Any>(
                    "lastActive" to FieldValue.serverTimestamp(),
                    "isOnline" to true,
                    "deviceModel" to "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}",
                    "osVersion" to "Android ${android.os.Build.VERSION.RELEASE} (SDK ${android.os.Build.VERSION.SDK_INT})"
                )
                
                if (location != null) {
                    updates["lastLatitude"] = location.latitude
                    updates["lastLongitude"] = location.longitude
                    updates["locationUpdatedAt"] = FieldValue.serverTimestamp()
                }
                
                if (ip != null) {
                    updates["lastIp"] = ip
                }

                FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(uid)
                    .update(updates)
                    .addOnSuccessListener {
                        Log.d(TAG, "Initial startup sync successful")
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "Firestore sync failed", e)
                    }
            } catch (e: Exception) {
                Log.e(TAG, "Startup sync failed", e)
            }
        }
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

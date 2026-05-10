package com.kyvronix.phoneguard.services

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.FieldValue
import com.kyvronix.phoneguard.sms.CommandParser
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers

class FirestoreCommandService : Service() {
    private val CHANNEL_ID = "FirestoreCmdChannel"
    private val TAG = "FirestoreCmdService"
    private var listener: com.google.firebase.firestore.ListenerRegistration? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val serviceChannel = android.app.NotificationChannel(
                CHANNEL_ID,
                "Firestore Command Channel",
                android.app.NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")

        val notification = androidx.core.app.NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Cloud Sync Active")
            .setContentText("Listening for remote commands from web dashboard")
            .setSmallIcon(android.R.drawable.ic_popup_sync)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_LOW)
            .build()
        
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                val type = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                } else {
                    0
                }
                if (type != 0) {
                    startForeground(4, notification, type)
                } else {
                    startForeground(4, notification)
                }
            } else {
                startForeground(4, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start FirestoreCommandService in foreground: ${e.message}")
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                stopSelf()
                return START_NOT_STICKY
            }
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val uid = prefs.getString("flutter.user_uid", null)

        if (uid != null) {
            startListening(uid)
        } else {
            Log.w(TAG, "No user UID found, cannot listen to commands")
            stopSelf()
        }

        return START_STICKY
    }

    private fun startListening(uid: String) {
        if (listener != null) return

        val db = FirebaseFirestore.getInstance()
        val docRef = db.collection("users").document(uid)

        listener = docRef.addSnapshotListener { snapshot, e ->
            if (e != null) {
                Log.e(TAG, "Listen failed.", e)
                return@addSnapshotListener
            }

            if (snapshot != null && snapshot.exists()) {
                val pendingCommand = snapshot.get("pendingCommand") as? Map<String, Any>
                if (pendingCommand != null) {
                    val action = pendingCommand["action"] as? String
                    if (action != null) {
                        Log.d(TAG, "Received pending command: $action")
                        
                        kotlinx.coroutines.GlobalScope.launch(kotlinx.coroutines.Dispatchers.IO) {
                            try {
                                // Execute command (suspendable)
                                val result = CommandParser(applicationContext).parseAndExecute("WEB_DASHBOARD", "REMOTE_ACTION $action")

                                if (result == com.kyvronix.phoneguard.sms.CommandStatus.EXPIRED) {
                                    Log.w(TAG, "Command BLOCKED: Protection EXPIRED")
                                    val resultData = hashMapOf<String, Any>(
                                        "action" to action,
                                        "status" to "expired",
                                        "message" to "PhoneGuard Protection Expired. Please watch an ad or buy a subscription in the app to re-enable remote commands",
                                        "at" to FieldValue.serverTimestamp()
                                    )
                                    docRef.update(
                                        "commandResult", resultData,
                                        "pendingCommand", FieldValue.delete()
                                    )
                                } else {
                                    // Sync state to Firestore
                                    com.kyvronix.phoneguard.utils.StateSyncManager.syncState(this@FirestoreCommandService, "WEB_COMMAND_$action")

                                    // Write result and clear pending command
                                    val resultData = hashMapOf<String, Any>(
                                        "action" to action,
                                        "status" to "executed",
                                        "at" to FieldValue.serverTimestamp()
                                    )
                                    docRef.update(
                                        "commandResult", resultData,
                                        "pendingCommand", FieldValue.delete()
                                    )
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Command execution failed", e)
                                docRef.update("pendingCommand", FieldValue.delete())
                            }
                        }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        listener?.remove()
        listener = null
        Log.d(TAG, "Service destroyed")
    }
}

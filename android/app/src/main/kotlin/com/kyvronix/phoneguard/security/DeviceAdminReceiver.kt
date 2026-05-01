package com.kyvronix.phoneguard.security

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.UserHandle
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue

class DeviceAdminReceiver : DeviceAdminReceiver() {
    private val TAG = "DeviceAdminReceiver"

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "Device Admin Enabled")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        Log.w(TAG, "Device Admin Disable Requested")
        return "Disabling protection will allow PhoneGuard to be uninstalled. Are you sure?"
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.w(TAG, "Device Admin Disabled")
        
        // Log deactivation to Firestore if user is logged in
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val userUid = prefs.getString("flutter.user_uid", null)
        
        if (userUid != null) {
            try {
                FirebaseFirestore.getInstance().collection("users").document(userUid)
                    .update("protectionDeactivatedAt", FieldValue.serverTimestamp())
            } catch (e: Exception) {
                Log.e(TAG, "Failed to log deactivation to Firestore: ${e.message}")
            }
        }
    }

    override fun onPasswordFailed(context: Context, intent: Intent, userHandle: UserHandle) {
        super.onPasswordFailed(context, intent, userHandle)
        Log.d(TAG, "System unlock attempt failed")
        
        // Sync state to Firestore on failed unlock
        com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "UNLOCK_FAILED")
        
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val failedAttempts = dpm.getCurrentFailedPasswordAttempts()
        Log.d(TAG, "Failed attempts count: $failedAttempts")

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val settingsJson = prefs.getString("flutter.app_settings", null)
        
        var isEnabled = true
        var threshold = 2
        
        if (settingsJson != null) {
            try {
                val json = org.json.JSONObject(settingsJson)
                isEnabled = json.optBoolean("intrusionSelfieEnabled", true)
                threshold = json.optInt("intrusionThreshold", 2)
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing settings for intrusion: ${e.message}")
            }
        }

        if (isEnabled && failedAttempts >= threshold) {
            logActivityLocally(context, "System Unlock", "Failed attempt detected (#$failedAttempts). Threshold reached.", true)
            val serviceIntent = Intent(context, IntrusionCameraService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } else if (isEnabled) {
            logActivityLocally(context, "System Unlock", "Failed attempt detected (#$failedAttempts). Waiting for threshold ($threshold).", true)
        }
    }

    private fun logActivityLocally(context: Context, command: String, result: String, success: Boolean) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val logsJsonStr = prefs.getString("flutter.activity_logs", "[]") ?: "[]"
            val jsonArray = try { org.json.JSONArray(logsJsonStr) } catch (e: Exception) { org.json.JSONArray() }
            
            val newLogObj = org.json.JSONObject().apply {
                put("id", System.currentTimeMillis().toString())
                put("timestamp", java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply { timeZone = java.util.TimeZone.getTimeZone("UTC") }.format(java.util.Date()))
                put("senderNumber", "SYSTEM")
                put("command", command)
                put("result", result)
                put("success", success)
            }
            jsonArray.put(newLogObj)
            prefs.edit().putString("flutter.activity_logs", jsonArray.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Local log failed", e)
        }
    }
}

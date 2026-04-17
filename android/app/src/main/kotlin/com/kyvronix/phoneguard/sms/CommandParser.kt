package com.kyvronix.phoneguard.sms

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import com.kyvronix.phoneguard.location.LocationManager
import com.kyvronix.phoneguard.security.DeviceAdminReceiver
import com.kyvronix.phoneguard.services.TrackingService
import com.kyvronix.phoneguard.services.AlarmService
import com.kyvronix.phoneguard.services.RecoveryService
import android.os.Build
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.kyvronix.phoneguard.location.LocationResult
import java.util.*

class CommandParser(private val context: Context) {

    companion object {
        private const val TAG = "CommandParser"
    }

    fun parseAndExecute(sender: String, message: String, subscriptionId: Int = -1) {
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val appSettingsJson = sharedPrefs.getString("flutter.app_settings", null)
        if (appSettingsJson == null) {
            Log.w(TAG, "No app_settings found in SharedPreferences")
            return
        }

        Log.d(TAG, "SMS from=$sender body='$message'")

        try {
            startForegroundServiceCompat(Intent(context, RecoveryService::class.java))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start RecoveryService", e)
        }

        try {
            val settings = JSONObject(appSettingsJson)
            val triggerKeyword = settings.optString("triggerKeyword", "miss you phone")
            val isPinEnabled = settings.optBoolean("isPinEnabled", false)
            val pin = settings.optString("pin", "")

            val messageLower = message.trim().lowercase()
            val triggerLower = triggerKeyword.trim().lowercase()

            if (!messageLower.startsWith(triggerLower)) return

            val senderLast10 = extractLast10Digits(sender)
            if (senderLast10.isEmpty()) return

            val trustedNumbersArray = settings.optJSONArray("trustedNumbers") ?: JSONArray()
            var matchedTrustedNumber: String? = null

            for (i in 0 until trustedNumbersArray.length()) {
                val trustedObj = trustedNumbersArray.optJSONObject(i) ?: continue
                val storedNumber = trustedObj.optString("phoneNumber", "")
                val storedLast10 = extractLast10Digits(storedNumber)
                if (storedLast10 == senderLast10) {
                    matchedTrustedNumber = storedNumber
                    break
                }
            }

            if (matchedTrustedNumber == null) return

            // Check Protection Eligibility
            if (!isProtectionActive()) {
                SmsSender.sendSmsWithSim(context, sender, "⚠️ PhoneGuard: Protection Expired. Please watch an ad in the app to re-enable remote commands.", subscriptionId)
                logActivity(sender, "denied", "Protection expired", false)
                return
            }

            // --- New Space-Separated Parsing ---
            val remainder = message.substring(triggerKeyword.length).trim()
            val parts = remainder.split(Regex("\\s+")).filter { it.isNotEmpty() }
            
            var action = "default"
            var receivedPin = ""

            if (isPinEnabled) {
                receivedPin = parts.getOrNull(0) ?: ""
                action = parts.getOrNull(1)?.lowercase() ?: "default"
            } else {
                action = parts.getOrNull(0)?.lowercase() ?: "default"
                receivedPin = ""
            }

            if (isPinEnabled && action != "default" && action != "stop") {
                if (receivedPin != pin) {
                    SmsSender.sendSmsWithSim(context, sender, "❌ Invalid PIN", subscriptionId)
                    return
                }
            }

            val defaultActions = settings.optJSONObject("defaultActions") ?: JSONObject()
            val sendLocation = defaultActions.optBoolean("sendLocation", true)
            val startAlarm = defaultActions.optBoolean("startAlarm", true)
            val enableTracking = defaultActions.optBoolean("enableTracking", false)
            val stopAlarmOnTrigger = defaultActions.optBoolean("stopAlarmOnTrigger", false)
            val lockDevice = defaultActions.optBoolean("lockDevice", false)

            CoroutineScope(Dispatchers.Main).launch {
                kotlinx.coroutines.delay(1000)

                try {
                    when (action) {
                        "location" -> {
                            val result = LocationManager(context).getCurrentLocation()
                            if (result != null) {
                                SmsSender.sendSmsWithSim(context, sender, "📍 Location: ${result.mapsUrl}", subscriptionId)
                                logActivity(sender, action, "Sent location link", true)
                                updateFirestoreLocation(result)
                            } else {
                                SmsSender.sendSmsWithSim(context, sender, "📍 Location unavailable", subscriptionId)
                                logActivity(sender, action, "Location failed", false)
                            }
                        }
                        "alarm" -> {
                            startForegroundServiceCompat(Intent(context, AlarmService::class.java))
                            SmsSender.sendSmsWithSim(context, sender, "🔔 Alarm started", subscriptionId)
                            logActivity(sender, action, "Alarm started", true)
                        }
                        "stop" -> {
                            context.stopService(Intent(context, AlarmService::class.java))
                            context.stopService(Intent(context, TrackingService::class.java))
                            SmsSender.sendSmsWithSim(context, sender, "⏹️ Alarm & Tracking stopped", subscriptionId)
                            logActivity(sender, action, "Stopped successfully", true)
                        }
                        "lock" -> {
                            lockDeviceNow()
                            SmsSender.sendSmsWithSim(context, sender, "🔒 Device locked", subscriptionId)
                            logActivity(sender, action, "Locked", true)
                        }
                        "tracking" -> {
                            val trackingIntent = Intent(context, TrackingService::class.java).apply {
                                putExtra("trustedNumber", sender)
                                putExtra("subscriptionId", subscriptionId)
                            }
                            startForegroundServiceCompat(trackingIntent)
                            SmsSender.sendSmsWithSim(context, sender, "🛰️ Position tracking started", subscriptionId)
                            logActivity(sender, action, "Tracking started", true)
                        }
                        else -> {
                            if (stopAlarmOnTrigger) {
                                context.stopService(Intent(context, AlarmService::class.java))
                                context.stopService(Intent(context, TrackingService::class.java))
                            }
                            if (startAlarm) {
                                startForegroundServiceCompat(Intent(context, AlarmService::class.java))
                            }
                            if (sendLocation) {
                                val result = LocationManager(context).getCurrentLocation()
                                if (result != null) {
                                    SmsSender.sendSmsWithSim(context, sender, "📍 Location: ${result.mapsUrl}", subscriptionId)
                                    updateFirestoreLocation(result)
                                }
                            }
                            if (enableTracking) {
                                val trackingIntent = Intent(context, TrackingService::class.java).apply {
                                    putExtra("trustedNumber", sender)
                                    putExtra("subscriptionId", subscriptionId)
                                }
                                startForegroundServiceCompat(trackingIntent)
                            }
                            if (lockDevice) {
                                lockDeviceNow()
                            }
                            SmsSender.sendSmsWithSim(context, sender, "✅ Recovery command executed", subscriptionId)
                            logActivity(sender, "default", "Executed actions", true)
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing action: $action", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse settings", e)
        }
    }

    private fun startForegroundServiceCompat(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun lockDeviceNow(): Boolean {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val admin = ComponentName(context, DeviceAdminReceiver::class.java)
            if (dpm.isAdminActive(admin)) {
                dpm.lockNow()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun isProtectionActive(): Boolean {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // 1. Premium always active
            if (prefs.getBoolean("flutter.is_premium", false)) return true
            
            // 2. 3-day Free Trial
            val createdAtStr = prefs.getString("flutter.created_at", null)
            if (createdAtStr != null) {
                // ISO format might vary, try parsing first 19 chars
                val datePart = createdAtStr.substring(0, 19)
                val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
                val createdAt = sdf.parse(datePart)
                if (createdAt != null) {
                    val trialMillis = 3 * 24 * 60 * 60 * 1000L
                    if (System.currentTimeMillis() - createdAt.time < trialMillis) return true
                }
            }

            // 3. Ad-extended expiry
            val expiryStr = prefs.getString("flutter.protection_expiry", null)
            if (expiryStr != null) {
                val datePart = expiryStr.substring(0, 19)
                val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
                val expiry = sdf.parse(datePart)
                if (expiry != null && expiry.after(java.util.Date())) return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Protection check failed", e)
        }
        return false
    }

    private fun extractLast10Digits(number: String): String {
        val digits = number.filter { it.isDigit() }
        return if (digits.length >= 10) digits.takeLast(10) else digits
    }

    private fun logActivity(sender: String, command: String, result: String, success: Boolean) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val logsJsonStr = prefs.getString("flutter.activity_logs", "[]") ?: "[]"
            val cleanStr = if (logsJsonStr.startsWith("VGhpcy")) "[]" else logsJsonStr
            val jsonArray = try { JSONArray(cleanStr) } catch (e: Exception) { JSONArray() }
            
            val newLogObj = JSONObject().apply {
                put("id", System.currentTimeMillis().toString())
                put("timestamp", java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply { timeZone = java.util.TimeZone.getTimeZone("UTC") }.format(java.util.Date()))
                put("senderNumber", sender)
                put("command", command)
                put("result", result)
                put("success", success)
            }
            jsonArray.put(newLogObj)
            prefs.edit().putString("flutter.activity_logs", jsonArray.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Log failed", e)
        }
    }

    private fun updateFirestoreLocation(result: LocationResult) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val uid = prefs.getString("flutter.user_uid", null) ?: return
            
            val db = FirebaseFirestore.getInstance()
            val data = mapOf(
                "lastLatitude" to result.latitude,
                "lastLongitude" to result.longitude,
                "locationUpdatedAt" to Date()
            )
            
            db.collection("users").document(uid)
                .set(data, SetOptions.merge())
                .addOnSuccessListener { Log.d(TAG, "Location updated in Firestore") }
                .addOnFailureListener { e -> Log.e(TAG, "Firestore update failed", e) }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update Firestore", e)
        }
    }
}

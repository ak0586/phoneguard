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
import com.google.firebase.firestore.FieldValue
import com.kyvronix.phoneguard.location.LocationResult
import java.util.*

enum class CommandStatus {
    EXECUTED,
    EXPIRED,
    IGNORED
}

class CommandParser(private val context: Context) {

    companion object {
        private const val TAG = "CommandParser"
        
        // Deduplication window to prevent multiple triggers for the same message
        private const val DEDUPE_WINDOW_MS = 10000L // 10 seconds
        private val lastProcessedCommands = mutableMapOf<String, Long>()
        
        private fun isDuplicate(sender: String, action: String?): Boolean {
            val key = "$sender:$action"
            val now = System.currentTimeMillis()
            val lastTime = lastProcessedCommands[key] ?: 0L
            if (now - lastTime < DEDUPE_WINDOW_MS) {
                Log.w("CommandParser", "Dedup: blocking duplicate command key=$key within ${DEDUPE_WINDOW_MS}ms")
                return true
            }
            lastProcessedCommands[key] = now
            if (lastProcessedCommands.size > 100) {
                lastProcessedCommands.entries.removeIf { now - it.value > DEDUPE_WINDOW_MS }
            }
            return false
        }
    }

    suspend fun parseAndExecute(sender: String, message: String, subscriptionId: Int = -1): CommandStatus {
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val appSettingsJson = sharedPrefs.getString("flutter.app_settings", null)
        if (appSettingsJson == null) {
            Log.w(TAG, "PHONEGUARD_DEBUG ❌ No app_settings found in SharedPreferences")
            return CommandStatus.IGNORED
        }

        Log.d(TAG, "PHONEGUARD_DEBUG ─── NEW SMS ─── from='$sender' subId=$subscriptionId body='$message'")
        val senderNorm = normalizeNumber(sender)

        try {
            val settings = JSONObject(appSettingsJson)
            val triggerKeyword = settings.optString("triggerKeyword", "miss you phone")
            val isPinEnabled = settings.optBoolean("isPinEnabled", false)
            val pin = settings.optString("pin", "")

            val isRemoteCommand = sender == "WEB_DASHBOARD"
            var action = "default"
            var matchedTrustedNumber: String? = null
            
            // 1. VALIDATION PHASE (Trigger & Trusted Number)
            if (!isRemoteCommand) {
                // Check Keyword
                val messageLower = message.trim().lowercase()
                val triggerLower = triggerKeyword.trim().lowercase()

                Log.d(TAG, "PHONEGUARD_DEBUG [1] Keyword check: message='$messageLower' trigger='$triggerLower'")
                if (!messageLower.contains(triggerLower)) {
                    Log.d(TAG, "PHONEGUARD_DEBUG [1] ❌ Keyword NOT matched, ignoring")
                    return CommandStatus.IGNORED
                }
                Log.d(TAG, "PHONEGUARD_DEBUG [1] ✅ Keyword matched")

                // Check Trusted Number
                val trustedNumbersArray = settings.optJSONArray("trustedNumbers") ?: JSONArray()
                Log.d(TAG, "PHONEGUARD_DEBUG [2] Trusted number check: senderRaw='$sender' senderNorm='$senderNorm' trustedCount=${trustedNumbersArray.length()}")

                for (i in 0 until trustedNumbersArray.length()) {
                    val trustedObj = trustedNumbersArray.optJSONObject(i) ?: continue
                    val trustedNum = trustedObj.optString("phoneNumber", "")
                    val trustedNorm = normalizeNumber(trustedNum)
                    val matches = numbersMatch(senderNorm, trustedNorm)
                    Log.d(TAG, "PHONEGUARD_DEBUG [2]   [$i] stored='$trustedNum' norm='$trustedNorm' (Checking against senderNorm='$senderNorm') → match=$matches")
                    if (matches) {
                        matchedTrustedNumber = trustedNum
                        break
                    }
                }

                if (matchedTrustedNumber == null) {
                    Log.w(TAG, "PHONEGUARD_DEBUG [2] ❌ senderNorm='$senderNorm' NOT in trusted list — ignoring")
                    return CommandStatus.IGNORED
                }
                Log.d(TAG, "PHONEGUARD_DEBUG [2] ✅ Trusted number matched: '$matchedTrustedNumber'")
            } else {
                // Remote Dashboard Command
                action = message.removePrefix("REMOTE_ACTION ").trim().lowercase()
                Log.d(TAG, "PHONEGUARD_DEBUG [2] ✅ Remote dashboard command: action='$action'")
            }

            // 2. PROTECTION ENFORCEMENT PHASE
            if (!isProtectionActive()) {
                val expiredMsg = "⚠️ PhoneGuard Protection Expired. Please watch an ad or buy a subscription in the app to re-enable remote commands"
                Log.w(TAG, "PHONEGUARD_DEBUG [3] ❌ Protection EXPIRED — notifying sender")
                if (!isRemoteCommand) {
                    SmsSender.sendSmsWithSim(context, sender, expiredMsg, subscriptionId)
                }
                return CommandStatus.EXPIRED
            }
            Log.d(TAG, "PHONEGUARD_DEBUG [3] ✅ Protection active")

            // 3. SERVICE START PHASE
            try {
                startForegroundServiceCompat(Intent(context, RecoveryService::class.java))
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start RecoveryService", e)
            }

            // 4. ACTION PARSING PHASE (Specific to SMS)
            if (!isRemoteCommand) {
                val messageLower = message.trim().lowercase()
                val triggerLower = triggerKeyword.trim().lowercase()
                
                // Extract everything AFTER the first occurrence of the trigger keyword
                val keywordIndex = messageLower.indexOf(triggerLower)
                val remainder = messageLower.substring(keywordIndex + triggerLower.length).trim()
                
                val parts = remainder.split(Regex("\\s+")).filter { it.isNotEmpty() }
                
                // PIN feature removed to simplify user experience
                action = parts.getOrNull(0)?.lowercase() ?: "default"
            }

            // 5. DEFAULT SETTINGS EXTRACTION
            val defaultActions = settings.optJSONObject("defaultActions") ?: JSONObject()
            val sendLocation = defaultActions.optBoolean("sendLocation", true)
            val startAlarm = defaultActions.optBoolean("startAlarm", true)
            val enableTracking = defaultActions.optBoolean("enableTracking", false)
            val stopAlarmOnTrigger = defaultActions.optBoolean("stopAlarmOnTrigger", false)
            val lockDevice = defaultActions.optBoolean("lockDevice", false)

            Log.d(TAG, "Resolved action='$action' sendLocation=$sendLocation startAlarm=$startAlarm enableTracking=$enableTracking lockDevice=$lockDevice stopAlarmOnTrigger=$stopAlarmOnTrigger")

            // 6. DEDUPLICATION CHECK
            // Use normalized sender to ensure different formats (+91 vs local) don't trigger twice
            if (isDuplicate(senderNorm, action)) {
                Log.w(TAG, "Skipping duplicate command: senderNorm=$senderNorm action=$action (within 10s)")
                return CommandStatus.IGNORED
            }

            try {
                when (action) {
                        "location" -> {
                            val result = LocationManager(context).getCurrentLocation()
                            if (result != null) {
                                val label = if (result.isApproximate) "📍Approx. Location (GPS off)" else "📍 Location"
                                if (!isRemoteCommand) {
                                    SmsSender.sendSmsWithSim(context, sender, "$label: ${result.mapsUrl}", subscriptionId)
                                }
                                logActivity(sender, action, "Sent location link (approx=${result.isApproximate})", true)
                                com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "SMS_COMMAND_$action")
                            } else {
                                if (!isRemoteCommand) {
                                    SmsSender.sendSmsWithSim(context, sender, "📍 Location unavailable — GPS & Network both off", subscriptionId)
                                }
                                logActivity(sender, action, "Location failed", false)
                            }
                        }
                        "alarm" -> {
                            startForegroundServiceCompat(Intent(context, AlarmService::class.java))
                            if (!isRemoteCommand) SmsSender.sendSmsWithSim(context, sender, "🔔 Alarm started", subscriptionId)
                            logActivity(sender, action, "Alarm started", true)
                            com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "SMS_COMMAND_$action")
                        }
                        "stop" -> {
                            context.stopService(Intent(context, AlarmService::class.java))
                            context.stopService(Intent(context, TrackingService::class.java))
                            if (!isRemoteCommand) SmsSender.sendSmsWithSim(context, sender, "⏹️ Alarm & Tracking stopped", subscriptionId)
                            logActivity(sender, action, "Stopped successfully", true)
                        }
                        "lock" -> {
                            lockDeviceNow()
                            if (!isRemoteCommand) SmsSender.sendSmsWithSim(context, sender, "🔒 Device locked", subscriptionId)
                            logActivity(sender, action, "Locked", true)
                            com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "SMS_COMMAND_$action")
                        }
                        "tracking" -> {
                            val trackingIntent = Intent(context, TrackingService::class.java).apply {
                                putExtra("trustedNumber", sender)
                                putExtra("subscriptionId", subscriptionId)
                            }
                            startForegroundServiceCompat(trackingIntent)
                            if (!isRemoteCommand) SmsSender.sendSmsWithSim(context, sender, "🛰️ Position tracking started", subscriptionId)
                            logActivity(sender, action, "Tracking started", true)
                            com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "SMS_COMMAND_$action")
                        }
                        else -> {
                            Log.d(TAG, "Executing DEFAULT actions: stopAlarmOnTrigger=$stopAlarmOnTrigger startAlarm=$startAlarm sendLocation=$sendLocation enableTracking=$enableTracking lockDevice=$lockDevice")
                            if (stopAlarmOnTrigger) {
                                Log.d(TAG, "  Stopping existing alarm & tracking")
                                context.stopService(Intent(context, AlarmService::class.java))
                                context.stopService(Intent(context, TrackingService::class.java))
                            }
                            if (startAlarm) {
                                Log.d(TAG, "  Starting alarm")
                                startForegroundServiceCompat(Intent(context, AlarmService::class.java))
                            }

                            // Only fetch GPS if actually needed — avoids 10-18s delay when disabled
                            var locationSent = false
                            if (sendLocation) {
                                val result = LocationManager(context).getCurrentLocation()
                                Log.d(TAG, "  Location result: ${if (result != null) "${result.mapsUrl} approx=${result.isApproximate}" else "null"}")
                                if (result != null) {
                                    val label = if (result.isApproximate) "📍Approx. Location (GPS off)" else "📍 Location"
                                    SmsSender.sendSmsWithSim(context, sender, "$label: ${result.mapsUrl}", subscriptionId)
                                    Log.d(TAG, "  Location SMS sent (approximate=${result.isApproximate})")
                                    locationSent = true
                                } else {
                                    SmsSender.sendSmsWithSim(context, sender, "📍 Location unavailable — GPS & Network both off", subscriptionId)
                                    Log.w(TAG, "  Location was null — all tiers exhausted")
                                    locationSent = true // still sent a message, don't double-send confirmation
                                }
                            }

                            com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "SMS_COMMAND_DEFAULT")

                            if (enableTracking) {
                                Log.d(TAG, "  Starting tracking service")
                                val trackingIntent = Intent(context, TrackingService::class.java).apply {
                                    putExtra("trustedNumber", sender)
                                    putExtra("subscriptionId", subscriptionId)
                                }
                                startForegroundServiceCompat(trackingIntent)
                            }
                            if (lockDevice) {
                                Log.d(TAG, "  Locking device")
                                lockDeviceNow()
                            }

                            // Only send "✅ Recovery command executed" if no location message was sent
                            // (avoid flooding with 2 messages when sendLocation=true)
                            if (!locationSent) {
                                SmsSender.sendSmsWithSim(context, sender, "✅ Recovery command executed", subscriptionId)
                            }
                            logActivity(sender, "default", "Executed actions (locationSent=$locationSent)", true)
                            Log.d(TAG, "Default actions complete")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing action: $action", e)
                    logActivity(sender, action ?: "unknown", "Error: ${e.message}", false)
                }
            return CommandStatus.EXECUTED
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse settings", e)
            return CommandStatus.IGNORED
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
            
            // 1. Premium Check
            val isPremium = prefs.getBoolean("flutter.is_premium", false)
            Log.d(TAG, "isProtectionActive: [1] isPremium=$isPremium")
            if (isPremium) return true
            
            // 2. 3-day Free Trial
            val createdAtStr = prefs.getString("flutter.created_at", null)
            if (createdAtStr != null) {
                Log.d(TAG, "isProtectionActive: [2] Found createdAt='$createdAtStr'")
                val parseTargets = listOf(createdAtStr, createdAtStr.take(19))
                val formatters = listOf(
                    java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSSS", java.util.Locale.US),
                    java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US),
                    java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
                )
                var createdAt: java.util.Date? = null
                outer@ for (target in parseTargets) {
                    for (fmt in formatters) {
                        try {
                            fmt.isLenient = false
                            createdAt = fmt.parse(target)
                            if (createdAt != null) break@outer
                        } catch (_: Exception) {}
                    }
                }

                if (createdAt != null) {
                    val trialMillis = 3 * 24 * 60 * 60 * 1000L
                    val elapsed = System.currentTimeMillis() - createdAt.time
                    val inTrial = elapsed < trialMillis
                    Log.d(TAG, "isProtectionActive: [2] Trial status: elapsed=${elapsed/1000}s, trialLimit=${trialMillis/1000}s, inTrial=$inTrial")
                    if (inTrial) return true
                } else {
                    Log.e(TAG, "isProtectionActive: [2] Could not parse createdAt from '$createdAtStr'")
                }
            } else {
                Log.d(TAG, "isProtectionActive: [2] No createdAt found")
            }

            // 3. Ad-extended expiry
            val expiryStr = prefs.getString("flutter.protection_expiry", null)
            if (expiryStr != null) {
                Log.d(TAG, "isProtectionActive: [3] Found expiryStr='$expiryStr'")
                val datePart = expiryStr.take(19)
                val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
                val expiry = try { sdf.parse(datePart) } catch (_: Exception) { null }
                
                if (expiry != null) {
                    val active = expiry.after(java.util.Date())
                    Log.d(TAG, "isProtectionActive: [3] Ad-expiry check: expiry=$expiry, now=${java.util.Date()}, active=$active")
                    if (active) return true
                } else {
                    Log.e(TAG, "isProtectionActive: [3] Could not parse expiryStr from '$expiryStr'")
                }
            } else {
                Log.d(TAG, "isProtectionActive: [3] No expiryStr found")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Protection check failed with error", e)
        }
        Log.w(TAG, "isProtectionActive: returning FALSE — all protection tiers exhausted or missing")
        return false
    }

    /**
     * Strips a phone number down to pure digits, removes leading zeros
     * (trunk prefix used in many countries like India: 09XXXXXXXXX → 9XXXXXXXXX),
     * and returns the result.
     */
    private fun normalizeNumber(raw: String): String {
        val digits = raw.filter { it.isDigit() }
        return digits.trimStart('0')
    }

    /**
     * Matches two normalized (digits-only, leading-zeros stripped) phone numbers
     * using four strategies to handle every real-world format combination:
     *
     *  Strategy 1 — Exact: "9165939300" == "9165939300"
     *  Strategy 2 — Suffix overlap: "919165939300".endsWith("9165939300")
     *                               handles +91 country-code vs local-only storage
     *  Strategy 3 — Adaptive last-N: compare last min(lenA, lenB) digits
     *                               handles 7-digit local numbers vs full numbers
     *  Strategy 4 — One is suffix of the other (reverse direction)
     */
    private fun numbersMatch(a: String, b: String): Boolean {
        if (a.isEmpty() || b.isEmpty()) return false

        // S1: Exact match
        if (a == b) return true

        // S2 & S4: Suffix match in either direction
        if (a.endsWith(b) || b.endsWith(a)) return true

        // S3: Adaptive last-N (minimum of both lengths, floor at 7 to avoid false positives)
        val n = minOf(a.length, b.length).coerceAtLeast(7)
        if (a.length >= n && b.length >= n) {
            if (a.takeLast(n) == b.takeLast(n)) return true
        }

        return false
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

}

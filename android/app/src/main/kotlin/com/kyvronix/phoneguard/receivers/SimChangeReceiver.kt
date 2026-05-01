package com.kyvronix.phoneguard.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import com.kyvronix.phoneguard.sms.SmsSender

class SimChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.intent.action.SIM_STATE_CHANGED") {
            val state = intent.getStringExtra("ss")
            if (state == "LOADED") {
                val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                val currentNumber = try { telephonyManager.line1Number } catch (e: SecurityException) { null }
                
                checkSimChange(context, currentNumber)
            }
        }
    }

    private fun checkSimChange(context: Context, currentNumber: String?) {
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val appSettingsJson = sharedPrefs.getString("flutter.app_settings", null) ?: return
        
        var isEnabled = true
        try {
            val json = org.json.JSONObject(appSettingsJson)
            isEnabled = json.optBoolean("simChangeAlertEnabled", true)
        } catch (e: Exception) {}

        if (!isEnabled) return
        
        val previousSim = sharedPrefs.getString("flutter.lastSimNumber", "")
        
        if (currentNumber != null && currentNumber != previousSim) {
            sharedPrefs.edit().putString("flutter.lastSimNumber", currentNumber).apply()
            
            val regex = Regex("\"phoneNumber\"\\s*:\\s*\"([^\"]*)\"")
            val matches = regex.findAll(appSettingsJson)
            val trustedNumbers = matches.map { it.groupValues[1] }.toList()

            for (number in trustedNumbers) {
                SmsSender.sendSms(context, number, "ALERT: SIM card changed. New number is $currentNumber")
            }
            com.kyvronix.phoneguard.utils.StateSyncManager.syncState(context, "SIM_CHANGE")
        }
    }
}

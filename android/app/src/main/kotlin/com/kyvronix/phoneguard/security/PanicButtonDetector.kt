package com.kyvronix.phoneguard.security

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.IBinder
import android.util.Log
import com.kyvronix.phoneguard.location.LocationManager
import com.kyvronix.phoneguard.sms.SmsSender
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class PanicButtonDetector : Service() {
    private var pressCount = 0
    private var lastPressTime = 0L
    private val TIME_LIMIT: Long = 3000 // 3 seconds for 5 presses

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_SCREEN_OFF || intent.action == Intent.ACTION_SCREEN_ON) {
                val currentTime = System.currentTimeMillis()
                if (currentTime - lastPressTime > TIME_LIMIT) {
                    pressCount = 1
                } else {
                    pressCount++
                }
                lastPressTime = currentTime

                if (pressCount >= 5) {
                    pressCount = 0
                    triggerPanicAction(context)
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(receiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        unregisterReceiver(receiver)
        super.onDestroy()
    }

    override fun onBind(intent: Intent): IBinder? = null

    private fun triggerPanicAction(context: Context) {
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val appSettingsJson = sharedPrefs.getString("flutter.app_settings", null) ?: return

        val regex = Regex("\"phoneNumber\"\\s*:\\s*\"([^\"]*)\"")
        val matches = regex.findAll(appSettingsJson)
        val trustedNumbers = matches.map { it.groupValues[1] }.toList()

        CoroutineScope(Dispatchers.Main).launch {
            val url = LocationManager(context).getCurrentLocationUrl() ?: "Location unavailable"
            for (number in trustedNumbers) {
                SmsSender.sendSms(context, number, "PANIC ALERT! I might be in trouble. Location: $url")
            }
        }
    }
}

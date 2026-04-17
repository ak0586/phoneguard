package com.kyvronix.phoneguard.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.kyvronix.phoneguard.services.RecoveryService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED) {
            val serviceIntent = Intent(context, RecoveryService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}

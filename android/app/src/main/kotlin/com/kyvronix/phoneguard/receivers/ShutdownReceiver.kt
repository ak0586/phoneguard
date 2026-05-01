package com.kyvronix.phoneguard.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.kyvronix.phoneguard.utils.StateSyncManager

class ShutdownReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_SHUTDOWN || 
            intent.action == "android.intent.action.QUICKBOOT_POWEROFF" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWEROFF") {
            
            val pendingResult = goAsync()
            Log.d("ShutdownReceiver", "System shutting down, performing final Firestore sync...")
            
            StateSyncManager.syncState(context, "SHUTDOWN") {
                pendingResult.finish()
                Log.d("ShutdownReceiver", "Final sync finished, process can exit.")
            }
        }
    }
}

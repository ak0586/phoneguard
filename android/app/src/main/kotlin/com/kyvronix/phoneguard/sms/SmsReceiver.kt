package com.kyvronix.phoneguard.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SmsReceiver", "onReceive called, action=${intent.action}")
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val pendingResult = goAsync()
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            val subscriptionId = intent.getIntExtra("subscription", -1)

            kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
                try {
                    if (messages.isNotEmpty()) {
                        val sender = messages[0].displayOriginatingAddress
                        val fullBody = messages.mapNotNull { it.displayMessageBody }.joinToString("")
                        
                        Log.d("SmsReceiver", "Processing SMS from=$sender body='$fullBody'")

                        if (sender != null) {
                            val result = CommandParser(context).parseAndExecute(
                                sender = sender,
                                message = fullBody,
                                subscriptionId = subscriptionId
                            )
                            Log.d("SmsReceiver", "Command execution result: $result")
                        }
                    }
                } finally {
                    pendingResult.finish()
                }
            }
        }
    }
}

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
                    for (smsMessage in messages) {
                        val sender = smsMessage.displayOriginatingAddress
                        val messageBody = smsMessage.messageBody
                        Log.d("SmsReceiver", "Processing SMS from=$sender body='$messageBody'")

                        if (sender != null) {
                            // Pre-mark this message as "seen" using a hash of sender+body+timestamp
                            // so the RecoveryService ContentObserver skips it immediately.
                            val prefs = context.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                            val smsHash = "${sender.hashCode()}_${messageBody.hashCode()}_${smsMessage.timestampMillis}"
                            prefs.edit().putString("phoneguard.last_sms_hash", smsHash).commit()

                            val result = CommandParser(context).parseAndExecute(
                                sender = sender,
                                message = messageBody,
                                subscriptionId = subscriptionId,
                                smsTimestamp = smsMessage.timestampMillis
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

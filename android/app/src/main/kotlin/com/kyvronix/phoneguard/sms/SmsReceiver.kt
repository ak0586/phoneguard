package com.kyvronix.phoneguard.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SmsReceiver", "onReceive called, action=${intent.action}")
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            Log.d("SmsReceiver", "Got ${messages.size} SMS message(s)")

            val subscriptionId = intent.getIntExtra("subscription", -1)

            for (smsMessage in messages) {
                val sender = smsMessage.displayOriginatingAddress
                val messageBody = smsMessage.messageBody
                Log.d("SmsReceiver", "Processing SMS from=$sender body='$messageBody'")

                if (sender != null) {
                    CommandParser(context).parseAndExecute(
                        sender = sender,
                        message = messageBody,
                        subscriptionId = subscriptionId
                    )
                }
            }
        }
    }
}

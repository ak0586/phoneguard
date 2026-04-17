package com.kyvronix.phoneguard.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)

            // Extract the subscription ID (SIM slot) from the intent.
            // This tells us which SIM card received the message.
            val subscriptionId = intent.getIntExtra("subscription", -1)

            for (smsMessage in messages) {
                val sender = smsMessage.displayOriginatingAddress
                val messageBody = smsMessage.messageBody

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

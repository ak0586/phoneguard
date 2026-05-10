package com.kyvronix.phoneguard.sms

import android.content.Context
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log

class SmsSender {
    companion object {
        // Final gate: prevents sending identical message to the same number within 30s
        // even if all upstream deduplication fails.
        private val lastSentMessages = java.util.Collections.synchronizedMap(mutableMapOf<String, Long>())
        private const val SEND_DEDUPE_MS = 30_000L

        /**
         * Send an SMS using a specific SIM identified by [subscriptionId].
         * If [subscriptionId] is -1 or invalid, attempts to find an active SIM automatically.
         */
        fun sendSmsWithSim(context: Context, phoneNumber: String, message: String, subscriptionId: Int) {
            val now = System.currentTimeMillis()
            val dedupeKey = "$phoneNumber|$message"
            
            synchronized(lastSentMessages) {
                val lastTime = lastSentMessages[dedupeKey] ?: 0L
                if (now - lastTime < SEND_DEDUPE_MS) {
                    Log.w("SmsSender", "Blocking duplicate outgoing SMS to $phoneNumber within ${SEND_DEDUPE_MS}ms")
                    return
                }
                lastSentMessages[dedupeKey] = now
                
                if (lastSentMessages.size > 50) {
                    lastSentMessages.entries.removeIf { now - it.value > SEND_DEDUPE_MS }
                }
            }

            val appContext = context.applicationContext
            // Run in a background thread to allow blocking waits for result status
            Thread {
                val subManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                    appContext.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
                } else {
                    null
                }

                val activeSubIds = mutableListOf<Int>()
                
                // 1. Gather all active subscriptions for dual SIM support
                if (subscriptionId != -1) {
                    activeSubIds.add(subscriptionId)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1 && subManager != null) {
                    try {
                        val activeSubs = subManager.activeSubscriptionInfoList
                        if (activeSubs != null) {
                            for (info in activeSubs) {
                                if (!activeSubIds.contains(info.subscriptionId)) {
                                    activeSubIds.add(info.subscriptionId)
                                }
                            }
                        }
                    } catch (e: SecurityException) {
                        Log.e("SmsSender", "SecurityException gathering subscriptions", e)
                    }
                }

                // Add system default as a final option if it's not already in the list
                if (!activeSubIds.contains(-1)) {
                    activeSubIds.add(-1)
                }

                Log.d("SmsSender", "Starting SMS delivery queue. Target: $phoneNumber, SIM IDs to try: $activeSubIds")

                var success = false

                // 2. Iterate through available SIMs until success
                for (subId in activeSubIds) {
                    Log.d("SmsSender", "Attempting delivery via SIM subId=$subId")
                    
                    val latch = java.util.concurrent.CountDownLatch(1)
                    var currentAttemptSuccess = false
                    val uniqueAction = "com.kyvronix.phoneguard.SMS_SENT_${subId}_${System.currentTimeMillis()}"

                    val receiver = object : android.content.BroadcastReceiver() {
                        override fun onReceive(c: Context?, i: android.content.Intent?) {
                            val result = resultCode
                            currentAttemptSuccess = (result == android.app.Activity.RESULT_OK)
                            Log.d("SmsSender", "SIM subId=$subId report: resultCode=$result (Success=$currentAttemptSuccess)")
                            latch.countDown()
                        }
                    }

                    try {
                        // Register receiver with Android 14+ security flags
                        // MUST be RECEIVER_EXPORTED because the OS (SmsManager) sends the broadcast back to us
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            appContext.registerReceiver(receiver, android.content.IntentFilter(uniqueAction), Context.RECEIVER_EXPORTED)
                        } else {
                            appContext.registerReceiver(receiver, android.content.IntentFilter(uniqueAction))
                        }

                        val smsManager: SmsManager? = if (subId != -1 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                appContext.getSystemService(SmsManager::class.java)?.createForSubscriptionId(subId)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getSmsManagerForSubscriptionId(subId)
                            }
                        } else {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                appContext.getSystemService(SmsManager::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getDefault()
                            }
                        }

                        if (smsManager == null) {
                            Log.e("SmsSender", "SmsManager null for subId $subId")
                            appContext.unregisterReceiver(receiver)
                            continue
                        }

                        val sentIntent = android.app.PendingIntent.getBroadcast(
                            appContext, 
                            subId, // unique requestCode
                            android.content.Intent(uniqueAction), 
                            android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
                        )

                        val parts = smsManager.divideMessage(message)
                        if (parts.size > 1) {
                            Log.d("SmsSender", "Sending multi-part message (${parts.size} parts)")
                            val sentIntents = java.util.ArrayList<android.app.PendingIntent?>()
                            for (p in 0 until parts.size) {
                                // We only really NEED one status callback for the last part or any part to know it went out
                                sentIntents.add(if (p == parts.size - 1) sentIntent else null)
                            }
                            smsManager.sendMultipartTextMessage(phoneNumber, null, parts, sentIntents, null)
                        } else {
                            smsManager.sendTextMessage(phoneNumber, null, message, sentIntent, null)
                        }

                        // Wait for delivery status (max 15 seconds)
                        val completed = latch.await(15, java.util.concurrent.TimeUnit.SECONDS)
                        
                        if (completed && currentAttemptSuccess) {
                            Log.i("SmsSender", "✓ SMS delivered successfully via SIM subId=$subId")
                            success = true
                        } else {
                            val reason = if (!completed) "Timeout" else "Service error/No balance"
                            Log.w("SmsSender", "✗ SIM subId=$subId failed ($reason). Retrying with next available SIM...")
                        }

                    } catch (e: Exception) {
                        Log.e("SmsSender", "Exception during send attempt for subId $subId", e)
                    } finally {
                        try {
                            appContext.unregisterReceiver(receiver)
                        } catch (e: Exception) {
                            // Already unregistered
                        }
                    }

                    if (success) break
                }

                if (!success) {
                    Log.e("SmsSender", "CRITICAL FAILURE: All SIM cards failed to deliver the message.")
                }
            }.start()
        }

        // Overload for simpler calls
        fun sendSms(context: Context, phoneNumber: String, message: String) {
            sendSmsWithSim(context, phoneNumber, message, -1)
        }
    }
}

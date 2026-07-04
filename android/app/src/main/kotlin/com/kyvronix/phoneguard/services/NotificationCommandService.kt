package com.kyvronix.phoneguard.services

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.ContactsContract
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.kyvronix.phoneguard.sms.CommandParser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class NotificationCommandService : NotificationListenerService() {
    private val scope = CoroutineScope(Dispatchers.IO)

    companion object {
        private const val TAG = "NotificationService"
        
        private val TARGET_PACKAGES = setOf(
            "com.google.android.apps.messaging", // Google Messages (RCS & SMS)
            "com.samsung.android.messaging",     // Samsung Messages (SMS)
            "com.whatsapp",                      // WhatsApp
            "com.whatsapp.w4b",                  // WhatsApp Business
            "org.telegram.messenger",             // Telegram
            "org.thunderdog.challegram",         // Telegram X
            "com.facebook.orca",                  // Messenger
            "org.thoughtcrime.securesms"          // Signal
        )

        // Prevent double-processing of the same notification update
        private val lastProcessedNotifications = java.util.Collections.synchronizedMap(mutableMapOf<String, Long>())
        private const val NOTIFICATION_DEDUPE_MS = 30_000L  // 30s matches CommandParser + SmsSender window
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification Listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        
        val packageName = sbn.packageName
        if (!TARGET_PACKAGES.contains(packageName)) return

        val extras = sbn.notification.extras ?: return
        var title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: return
        var text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        // Handle MessagingStyle (RCS, WhatsApp, etc.)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            val messages = extras.get(Notification.EXTRA_MESSAGES) as? Array<*>
            if (messages != null && messages.isNotEmpty()) {
                val lastMessage = messages.last() as? Bundle
                if (lastMessage != null) {
                    val messageText = lastMessage.getCharSequence("text")?.toString()
                    val senderName = lastMessage.getCharSequence("sender")?.toString()
                    if (messageText != null) {
                        text = messageText
                        if (senderName != null) title = senderName
                    }
                }
            }
        }
        
        if (text.isEmpty()) return
        
        // Internal deduplication: Package + Title + Text
        val dedupeKey = "$packageName|$title|$text"
        val now = System.currentTimeMillis()
        synchronized(lastProcessedNotifications) {
            val lastTime = lastProcessedNotifications[dedupeKey] ?: 0L
            if (now - lastTime < NOTIFICATION_DEDUPE_MS) {
                return // Skip duplicate notification update
            }
            lastProcessedNotifications[dedupeKey] = now
            
            // Cleanup
            if (lastProcessedNotifications.size > 50) {
                lastProcessedNotifications.entries.removeIf { now - it.value > NOTIFICATION_DEDUPE_MS }
            }
        }

        Log.d(TAG, "PHONEGUARD_DEBUG 🔔 New notification from $packageName: $title - $text")

        scope.launch {
            handleIncomingNotification(sbn, title, text)
        }
    }

    private suspend fun handleIncomingNotification(sbn: StatusBarNotification, title: String, text: String) {
        // 1. Check if the title is already a phone number
        val possibleNumbers = mutableSetOf<String>()
        if (isPhoneNumber(title)) {
            val norm = normalize(title)
            possibleNumbers.add(norm)
            Log.d(TAG, "Title is phone number: $title -> $norm")
        } else {
            // 2. It's likely a contact name, resolve it to phone numbers
            val resolvedNumbers = resolveContactNameToNumbers(title)
            Log.d(TAG, "Resolved '$title' to numbers: $resolvedNumbers")
            possibleNumbers.addAll(resolvedNumbers.map { normalize(it) })
        }

        if (possibleNumbers.isEmpty()) {
            Log.w(TAG, "No phone numbers found for title: $title")
            return
        }

        Log.d(TAG, "Final normalized possible numbers: $possibleNumbers")

        val parser = CommandParser(this)
        var matched = false

        for (number in possibleNumbers) {
            Log.d(TAG, "Testing command against number: $number")
            
            // Look up the actual SMS timestamp from the database.
            // The ContentObserver in RecoveryService uses the 'date' column as the dedup key.
            // If this notification is for a traditional SMS, we must use the SAME timestamp,
            // otherwise both detection paths produce different keys and both execute.
            // For RCS/WhatsApp (not in SMS DB), findSmsTimestamp returns null → falls back to postTime.
            val smsTimestamp = findSmsTimestamp(text) ?: sbn.postTime
            Log.d(TAG, "Using smsTimestamp=$smsTimestamp (postTime=${sbn.postTime}) for dedup")
            
            val result = parser.parseAndExecute(
                sender = number,
                message = text,
                subscriptionId = -1,
                smsTimestamp = smsTimestamp,
                replyAction = { replyText ->
                    val action = findReplyAction(sbn.notification)
                    if (action != null) {
                        val remoteInputs = action.remoteInputs
                        if (remoteInputs != null && remoteInputs.isNotEmpty()) {
                            val intent = Intent()
                            val bundle = Bundle()
                            bundle.putCharSequence(remoteInputs[0].resultKey, replyText)
                            android.app.RemoteInput.addResultsToIntent(remoteInputs, intent, bundle)
                            try {
                                action.actionIntent.send(this@NotificationCommandService, 0, intent)
                                Log.d(TAG, "Successfully sent auto-reply: $replyText")
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to send auto-reply", e)
                            }
                        }
                    } else {
                        Log.w(TAG, "No reply action found in notification")
                    }
                }
            )
            
            Log.d(TAG, "CommandParser result for $number: ${result.name}")
            
            if (result.name == "EXECUTED") {
                Log.i(TAG, "PHONEGUARD_DEBUG ✅ Match found via Notification ($title -> $number)")
                matched = true
                break
            }
        }

        if (matched) {
            // Dismiss the notification instantly to hide the command
            cancelNotification(sbn.key)
            Log.d(TAG, "Notification dismissed after successful command execution")
        }
    }

    /**
     * Looks up the actual 'date' timestamp stored in the SMS database for a message
     * with the given body. This allows NotificationCommandService to share the same
     * dedup key as RecoveryService's ContentObserver (which also reads the 'date' column).
     * Returns null if the message is not in the SMS DB (i.e., it is RCS or OTT like WhatsApp).
     */
    private fun findSmsTimestamp(messageBody: String): Long? {
        return try {
            val trimmedBody = messageBody.trim()
            // Only look for SMS received in the last 60 seconds to avoid matching
            // old messages with the same body text (e.g., old "Miss you phone" from inbox).
            val cutoffMs = System.currentTimeMillis() - 60_000L
            val cursor = contentResolver.query(
                android.net.Uri.parse("content://sms/inbox"),
                arrayOf("date"),
                "body = ? AND date > ?",
                arrayOf(trimmedBody, cutoffMs.toString()),
                "date DESC LIMIT 1"
            ) ?: return null
            cursor.use {
                if (it.moveToFirst()) it.getLong(0) else null
            }
        } catch (e: Exception) {
            Log.w(TAG, "findSmsTimestamp failed: ${e.message}")
            null
        }
    }

    private fun isPhoneNumber(text: String): Boolean {
        // Simple check: if it contains mostly digits and symbols like +, -, (, )
        val clean = text.replace(Regex("[\\s\\-\\(\\)\\+]"), "")
        return clean.isNotEmpty() && clean.all { it.isDigit() }
    }

    private fun normalize(number: String): String {
        // Remove all non-digits except the leading +
        val hasPlus = number.startsWith("+")
        val digitsOnly = number.replace(Regex("\\D"), "")
        return if (hasPlus) "+$digitsOnly" else digitsOnly
    }

    private fun resolveContactNameToNumbers(name: String): List<String> {
        val numbers = mutableListOf<String>()
        val trimmedName = name.trim()
        
        val hasContactsPermission = checkSelfPermission(android.Manifest.permission.READ_CONTACTS) == android.content.pm.PackageManager.PERMISSION_GRANTED
        Log.d(TAG, "Attempting to resolve contact name: '$trimmedName'. READ_CONTACTS permission: $hasContactsPermission")

        // 1. Try Exact Match first (Fastest)
        val exactNumbers = queryNumbersByName(trimmedName)
        if (exactNumbers.isNotEmpty()) {
            Log.d(TAG, "Exact match found for '$trimmedName': $exactNumbers")
            return exactNumbers
        }

        // 2. Try with normalized spaces (common for messaging apps to add extra spaces)
        val singleSpaceName = trimmedName.replace(Regex("\\s+"), " ")
        if (singleSpaceName != trimmedName) {
            Log.d(TAG, "Trying with single-spaced name: '$singleSpaceName'")
            val sSpaceNumbers = queryNumbersByName(singleSpaceName)
            if (sSpaceNumbers.isNotEmpty()) {
                Log.d(TAG, "Single-space match found: $sSpaceNumbers")
                return sSpaceNumbers
            }
        }

        // 3. Use the Filter URI for fuzzy/robust searching
        Log.d(TAG, "Trying Filter URI search for '$trimmedName'")
        val filterUri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_FILTER_URI, Uri.encode(trimmedName))
        val filterProj = arrayOf(ContactsContract.Contacts._ID, ContactsContract.Contacts.DISPLAY_NAME)
        
        try {
            val cursor: Cursor? = contentResolver.query(filterUri, filterProj, null, null, null)
            cursor?.use {
                while (it.moveToNext()) {
                    val contactId = it.getString(0)
                    val foundName = it.getString(1)
                    Log.d(TAG, "Filter found contact: ID=$contactId, Name='$foundName'")
                    if (contactId != null) {
                        numbers.addAll(getPhoneNumbersForContact(contactId))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Filter search failed", e)
        }

        // 4. Final Fallback: Partial LIKE match
        if (numbers.isEmpty()) {
            Log.d(TAG, "Filter found nothing, trying partial LIKE match")
            val phoneUri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
            val phoneProj = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER, ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val selection = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?"
            val selectionArgs = arrayOf("%$trimmedName%")

            try {
                val phoneCursor = contentResolver.query(phoneUri, phoneProj, selection, selectionArgs, null)
                phoneCursor?.use {
                    while (it.moveToNext()) {
                        val num = it.getString(0)
                        val foundName = it.getString(1)
                        Log.d(TAG, "LIKE found match: '$foundName' -> $num")
                        if (num != null) numbers.add(num)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "LIKE search failed", e)
            }
        }

        val uniqueNumbers = numbers.distinct()
        Log.d(TAG, "Resolved '$trimmedName' to final unique numbers: $uniqueNumbers")
        return uniqueNumbers
    }

    private fun queryNumbersByName(name: String): List<String> {
        val numbers = mutableListOf<String>()
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER)
        val selection = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf(name)
        try {
            contentResolver.query(uri, projection, selection, selectionArgs, null)?.use {
                while (it.moveToNext()) {
                    val num = it.getString(0)
                    if (num != null) numbers.add(num)
                }
            }
        } catch (e: Exception) {}
        return numbers
    }

    private fun getPhoneNumbersForContact(contactId: String): List<String> {
        val numbers = mutableListOf<String>()
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER)
        val selection = "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?"
        val selectionArgs = arrayOf(contactId)

        try {
            contentResolver.query(uri, projection, selection, selectionArgs, null)?.use {
                while (it.moveToNext()) {
                    val number = it.getString(0)
                    if (number != null) numbers.add(number)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get numbers for contactId: $contactId", e)
        }
        return numbers
    }

    private fun findReplyAction(notification: Notification): Notification.Action? {
        val actions = notification.actions ?: return null
        for (action in actions) {
            val remoteInputs = action.remoteInputs
            if (remoteInputs != null && remoteInputs.isNotEmpty()) {
                return action
            }
        }
        return null
    }
}

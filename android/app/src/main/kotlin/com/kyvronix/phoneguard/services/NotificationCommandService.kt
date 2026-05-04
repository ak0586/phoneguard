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
        
        // List of common messaging apps to monitor for RCS/Chat
        private val TARGET_PACKAGES = setOf(
            "com.google.android.apps.messaging", // Google Messages (RCS)
            "com.whatsapp",                      // WhatsApp
            "com.whatsapp.w4b",                  // WhatsApp Business
            "org.telegram.messenger",             // Telegram
            "org.thunderdog.challegram",         // Telegram X
            "com.facebook.orca",                  // Messenger
            "org.thoughtcrime.securesms"          // Signal
        )
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
            val result = parser.parseAndExecute(
                sender = number,
                message = text,
                subscriptionId = -1
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
}

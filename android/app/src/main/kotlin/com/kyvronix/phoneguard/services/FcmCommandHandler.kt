package com.kyvronix.phoneguard.services

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.kyvronix.phoneguard.sms.CommandParser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * FCM-based command handler.
 * Battery-efficient replacement for the persistent Firestore WebSocket listener.
 *
 * The Flutter firebase_messaging plugin registers its own FirebaseMessagingService
 * which handles token management. This class receives data messages routed
 * from that plugin when a DASHBOARD_COMMAND FCM push arrives.
 *
 * Flow:
 *   Web Dashboard -> /api/send-command (Next.js) -> FCM -> Flutter plugin ->
 *   this background handler -> CommandParser -> execute action
 */
class FcmCommandHandler : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FcmCommandHandler"
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val type = message.data["type"]
        val action = message.data["action"]

        Log.d(TAG, "FCM received: type=$type, action=$action")

        if (type != "DASHBOARD_COMMAND" || action.isNullOrBlank()) {
            Log.d(TAG, "Ignoring non-command FCM message")
            return
        }

        Log.i(TAG, "Executing dashboard command via FCM: $action")

        val ctx = this.baseContext
        val job = SupervisorJob()
        CoroutineScope(Dispatchers.IO + job).launch {
            try {
                val result = CommandParser(ctx)
                    .parseAndExecute("WEB_DASHBOARD", "REMOTE_ACTION $action")
                Log.i(TAG, "FCM command '$action' result: ${result.name}")
                com.kyvronix.phoneguard.utils.StateSyncManager.syncState(ctx, "WEB_COMMAND_$action")
            } catch (e: Exception) {
                Log.e(TAG, "FCM command failed", e)
            } finally {
                job.complete()
            }
        }
    }
}

package com.kyvronix.phoneguard.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.kyvronix.phoneguard.location.LocationManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.Collections

class ShutdownReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_SHUTDOWN || 
            intent.action == "android.intent.action.QUICKBOOT_POWEROFF" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWEROFF") {
            
            val pendingResult = goAsync()
            Log.d("ShutdownReceiver", "System shutting down, performing final Firestore sync...")
            
            val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val uid = sharedPrefs.getString("flutter.flutter.user_uid", null)

            if (uid == null) {
                Log.w("ShutdownReceiver", "No user UID found in preferences, skipping sync")
                pendingResult.finish()
                return
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    // 1. Get Location
                    val location = LocationManager(context).getCurrentLocation()
                    
                    // 2. Get IP Address
                    val ip = getIpAddress()
                    
                    val updates = mutableMapOf<String, Any>(
                        "lastActive" to FieldValue.serverTimestamp(),
                        "isOnline" to false
                    )
                    
                    if (location != null) {
                        updates["lastLatitude"] = location.latitude
                        updates["lastLongitude"] = location.longitude
                        updates["locationUpdatedAt"] = FieldValue.serverTimestamp()
                    }
                    
                    if (ip != null) {
                        updates["lastIp"] = ip
                    }

                    // 3. Update Firestore
                    withContext(Dispatchers.IO) {
                        FirebaseFirestore.getInstance()
                            .collection("users")
                            .document(uid)
                            .update(updates)
                            .addOnCompleteListener {
                                Log.d("ShutdownReceiver", "Final sync successful")
                                pendingResult.finish()
                            }
                            .addOnFailureListener { e ->
                                Log.e("ShutdownReceiver", "Firestore update failed", e)
                                pendingResult.finish()
                            }
                    }
                } catch (e: Exception) {
                    Log.e("ShutdownReceiver", "Error during final sync", e)
                    pendingResult.finish()
                }
            }
        }
    }

    private fun getIpAddress(): String? {
        try {
            val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
            for (intf in interfaces) {
                val addrs = Collections.list(intf.inetAddresses)
                for (addr in addrs) {
                    if (!addr.isLoopbackAddress) {
                        val sAddr = addr.hostAddress
                        val isIPv4 = sAddr.indexOf(':') < 0
                        if (isIPv4) return sAddr
                    }
                }
            }
        } catch (e: Exception) {}
        return null
    }
}

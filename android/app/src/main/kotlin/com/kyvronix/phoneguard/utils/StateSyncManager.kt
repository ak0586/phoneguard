package com.kyvronix.phoneguard.utils

import android.content.Context
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.kyvronix.phoneguard.location.LocationManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.net.NetworkInterface
import java.util.Collections

object StateSyncManager {
    private const val TAG = "StateSyncManager"

    fun syncState(context: Context, event: String, onComplete: (() -> Unit)? = null) {
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val uid = sharedPrefs.getString("flutter.flutter.user_uid", null)

        if (uid == null) {
            Log.w(TAG, "No UID found, skipping sync for event: $event")
            onComplete?.invoke()
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val locationManager = LocationManager(context)
                val location = locationManager.getCurrentLocation()
                val ip = getIpAddress()

                val updates = mutableMapOf<String, Any>(
                    "lastActive" to FieldValue.serverTimestamp(),
                    "lastEvent" to event,
                    "deviceModel" to "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}",
                    "osVersion" to "Android ${android.os.Build.VERSION.RELEASE} (SDK ${android.os.Build.VERSION.SDK_INT})",
                    "isOnline" to true
                )

                val prefsEditor = sharedPrefs.edit()

                if (location != null) {
                    updates["lastLatitude"] = location.latitude
                    updates["lastLongitude"] = location.longitude
                    updates["locationUpdatedAt"] = FieldValue.serverTimestamp()
                    
                    prefsEditor.putString("flutter.lastLatitude", location.latitude.toString())
                    prefsEditor.putString("flutter.lastLongitude", location.longitude.toString())
                }

                if (ip != null) {
                    updates["lastIp"] = ip
                    prefsEditor.putString("flutter.lastIp", ip)
                }

                prefsEditor.apply()

                FirebaseFirestore.getInstance().collection("users").document(uid)
                    .update(updates)
                    .addOnCompleteListener {
                        Log.d(TAG, "Successfully synced state to Firestore for event: $event")
                        onComplete?.invoke()
                    }
            } catch (e: Exception) {
                Log.e(TAG, "Error during state sync: ${e.message}")
                onComplete?.invoke()
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

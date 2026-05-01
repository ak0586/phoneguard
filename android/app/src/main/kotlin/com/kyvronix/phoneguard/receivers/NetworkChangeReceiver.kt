package com.kyvronix.phoneguard.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Log
import com.kyvronix.phoneguard.utils.StateSyncManager

class NetworkChangeReceiver : BroadcastReceiver() {
    private val TAG = "NetworkChangeReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ConnectivityManager.CONNECTIVITY_ACTION) {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork
            val capabilities = cm.getNetworkCapabilities(network)
            
            val isConnected = capabilities != null && (
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
            )

            if (isConnected) {
                val pendingResult = goAsync()
                Log.d(TAG, "Network connected, checking for IP change...")
                StateSyncManager.syncState(context, "IP_CHANGE") {
                    pendingResult.finish()
                }
            }
        }
    }
}

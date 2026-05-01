package com.kyvronix.phoneguard.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.util.Log
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

data class LocationResult(
    val latitude: Double,
    val longitude: Double,
    val mapsUrl: String,
    val isApproximate: Boolean = false  // true when using last-known or network location
)

class LocationManager(private val context: Context) {

    companion object {
        private const val TAG = "LocationManager"
        private const val GPS_TIMEOUT_MS = 10_000L   // 10s for GPS
        private const val NET_TIMEOUT_MS = 8_000L    // 8s for network
    }

    /**
     * Multi-tier location strategy:
     * Tier 1 — High accuracy GPS (exact position, requires GPS on)
     * Tier 2 — Balanced power / network-based (works without GPS, uses cell towers + Wi-Fi)
     * Tier 3 — Last known location from ANY provider (always available, may be stale)
     *
     * This ensures a location is always returned even if the thief has GPS disabled.
     */
    @SuppressLint("MissingPermission")
    suspend fun getCurrentLocation(): LocationResult? {
        val fusedClient = LocationServices.getFusedLocationProviderClient(context)

        // ─── Tier 1: GPS (High Accuracy) ──────────────────────────────────────
        Log.d(TAG, "Tier 1: Trying GPS high-accuracy location...")
        val gpsResult = withTimeoutOrNull(GPS_TIMEOUT_MS) {
            suspendCancellableCoroutine<Location?> { cont ->
                fusedClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null)
                    .addOnSuccessListener { loc ->
                        Log.d(TAG, "Tier 1 result: ${if (loc != null) "${loc.latitude},${loc.longitude}" else "null"}")
                        cont.resume(loc)
                    }
                    .addOnFailureListener { e ->
                        Log.w(TAG, "Tier 1 failed: ${e.message}")
                        cont.resume(null)
                    }
            }
        }
        if (gpsResult != null) {
            Log.d(TAG, "✅ Using Tier 1 (GPS) location")
            return gpsResult.toLocationResult(isApproximate = false)
        }

        // ─── Tier 2: Network/Cell-tower (Balanced Power) ──────────────────────
        Log.d(TAG, "Tier 2: Trying network-based location...")
        val networkResult = withTimeoutOrNull(NET_TIMEOUT_MS) {
            suspendCancellableCoroutine<Location?> { cont ->
                fusedClient.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, null)
                    .addOnSuccessListener { loc ->
                        Log.d(TAG, "Tier 2 result: ${if (loc != null) "${loc.latitude},${loc.longitude}" else "null"}")
                        cont.resume(loc)
                    }
                    .addOnFailureListener { e ->
                        Log.w(TAG, "Tier 2 failed: ${e.message}")
                        cont.resume(null)
                    }
            }
        }
        if (networkResult != null) {
            Log.d(TAG, "✅ Using Tier 2 (network) location")
            return networkResult.toLocationResult(isApproximate = true)
        }

        // ─── Tier 3: Last Known Location from any provider ────────────────────
        Log.d(TAG, "Tier 3: Trying last known location...")
        val lastKnownResult = suspendCancellableCoroutine<Location?> { cont ->
            fusedClient.lastLocation
                .addOnSuccessListener { loc ->
                    Log.d(TAG, "Tier 3 result: ${if (loc != null) "${loc.latitude},${loc.longitude} age=${System.currentTimeMillis() - loc.time}ms" else "null"}")
                    cont.resume(loc)
                }
                .addOnFailureListener { e ->
                    Log.w(TAG, "Tier 3 failed: ${e.message}")
                    cont.resume(null)
                }
        }
        if (lastKnownResult != null) {
            Log.d(TAG, "✅ Using Tier 3 (last known) location — may be stale")
            return lastKnownResult.toLocationResult(isApproximate = true)
        }

        Log.e(TAG, "❌ All location tiers exhausted — no location available")
        return null
    }

    suspend fun getCurrentLocationUrl(): String? {
        return getCurrentLocation()?.mapsUrl
    }

    private fun Location.toLocationResult(isApproximate: Boolean) = LocationResult(
        latitude = latitude,
        longitude = longitude,
        mapsUrl = "https://maps.google.com/?q=$latitude,$longitude",
        isApproximate = isApproximate
    )
}

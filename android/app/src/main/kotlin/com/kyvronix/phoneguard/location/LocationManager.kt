package com.kyvronix.phoneguard.location

import android.annotation.SuppressLint
import android.content.Context
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

data class LocationResult(
    val latitude: Double,
    val longitude: Double,
    val mapsUrl: String
)

class LocationManager(private val context: Context) {
    @SuppressLint("MissingPermission")
    suspend fun getCurrentLocation(): LocationResult? = suspendCoroutine { continuation ->
        try {
            val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
            fusedLocationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null)
                .addOnSuccessListener { location ->
                    if (location != null) {
                        continuation.resume(LocationResult(
                            latitude = location.latitude,
                            longitude = location.longitude,
                            mapsUrl = "https://maps.google.com/?q=${location.latitude},${location.longitude}"
                        ))
                    } else {
                        continuation.resume(null)
                    }
                }
                .addOnFailureListener {
                    continuation.resume(null)
                }
        } catch (e: Exception) {
            continuation.resume(null)
        }
    }

    suspend fun getCurrentLocationUrl(): String? {
        return getCurrentLocation()?.mapsUrl
    }
}

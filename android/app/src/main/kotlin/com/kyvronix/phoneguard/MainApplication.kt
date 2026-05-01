package com.kyvronix.phoneguard

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        try {
            if (FirebaseApp.getApps(this).isEmpty()) {
                FirebaseApp.initializeApp(this)
                Log.d("MainApplication", "Firebase initialized successfully")
                
                // Enable Firestore offline persistence
                val settings = com.google.firebase.firestore.FirebaseFirestoreSettings.Builder()
                    .setPersistenceEnabled(true)
                    .build()
                com.google.firebase.firestore.FirebaseFirestore.getInstance().firestoreSettings = settings
            }
        } catch (e: Exception) {
            Log.e("MainApplication", "Firebase initialization failed", e)
        }
    }
}

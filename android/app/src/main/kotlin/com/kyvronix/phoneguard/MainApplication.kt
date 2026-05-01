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
            }
        } catch (e: Exception) {
            Log.e("MainApplication", "Firebase initialization failed", e)
        }
    }
}

package com.kyvronix.phoneguard.security

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.util.Base64
import androidx.camera.core.ImageProxy
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource

class IntrusionCameraService : LifecycleService() {
    private val TAG = "IntrusionCameraService"
    private val CHANNEL_ID = "IntrusionCameraChannel"
    private lateinit var cameraExecutor: ExecutorService
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onCreate() {
        super.onCreate()
        cameraExecutor = Executors.newSingleThreadExecutor()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        createNotificationChannel()
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Security Camera")
            .setContentText("Capturing security event...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var type = ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
            startForeground(2, notification, type)
        } else {
            startForeground(2, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        takePhoto()
        return START_NOT_STICKY
    }

    private fun takePhoto() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener({
            try {
                val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

                val imageCapture = ImageCapture.Builder()
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                    .build()

                val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, cameraSelector, imageCapture)

                imageCapture.takePicture(
                    ContextCompat.getMainExecutor(this),
                    object : ImageCapture.OnImageCapturedCallback() {
                        override fun onCaptureSuccess(image: ImageProxy) {
                            Log.d(TAG, "Photo captured in memory")
                            processAndUploadImage(image)
                        }

                        override fun onError(exc: ImageCaptureException) {
                            Log.e(TAG, "Photo capture failed: ${exc.message}", exc)
                            stopSelf()
                        }
                    }
                )
            } catch (exc: Exception) {
                Log.e(TAG, "Use case binding failed", exc)
                stopSelf()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun processAndUploadImage(image: ImageProxy) {
        try {
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.capacity())
            buffer.get(bytes)
            var bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, null)
            
            val rotationDegrees = image.imageInfo.rotationDegrees
            if (rotationDegrees != 0) {
                val matrix = Matrix()
                matrix.postRotate(rotationDegrees.toFloat())
                bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            }
            
            // Resize to save Firestore document size (1MB limit)
            val maxWidth = 640
            if (bitmap.width > maxWidth) {
                val ratio = maxWidth.toFloat() / bitmap.width
                val newHeight = (bitmap.height * ratio).toInt()
                bitmap = Bitmap.createScaledBitmap(bitmap, maxWidth, newHeight, true)
            }

            val baos = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 40, baos)
            val imageBytes = baos.toByteArray()
            val base64Image = Base64.encodeToString(imageBytes, Base64.NO_WRAP)
            val dataUrl = "data:image/jpeg;base64,$base64Image"

            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val uid = prefs.getString("flutter.flutter.user_uid", null)

            if (uid != null) {
                // Get location first, then save
                fetchLocationAndSave(uid, dataUrl)
            } else {
                Log.w(TAG, "No UID found, cannot upload Base64 photo")
                stopSelf()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to process image", e)
            stopSelf()
        } finally {
            image.close()
        }
    }

    private fun fetchLocationAndSave(uid: String, photoUrl: String) {
        try {
            fusedLocationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, CancellationTokenSource().token)
                .addOnSuccessListener { location ->
                    if (location != null) {
                        saveToFirestore(uid, photoUrl, location.latitude, location.longitude)
                    } else {
                        saveToFirestore(uid, photoUrl, null, null)
                    }
                }
                .addOnFailureListener {
                    saveToFirestore(uid, photoUrl, null, null)
                }
        } catch (e: SecurityException) {
            saveToFirestore(uid, photoUrl, null, null)
        }
    }

    private fun saveToFirestore(uid: String, photoUrl: String, lat: Double?, lng: Double?) {
        val db = FirebaseFirestore.getInstance()
        val photoEntry = hashMapOf(
            "url" to photoUrl,
            "timestamp" to FieldValue.serverTimestamp(),
            "latitude" to lat,
            "longitude" to lng
        )

        db.collection("users").document(uid).update(
            "intrusionPhotos", FieldValue.arrayUnion(photoEntry)
        ).addOnCompleteListener {
            Log.d(TAG, "Firestore updated with new photo and location")
            stopSelf()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Intrusion Camera",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
        Log.d(TAG, "Service destroyed")
    }
}

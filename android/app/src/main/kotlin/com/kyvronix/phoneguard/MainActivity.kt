package com.kyvronix.phoneguard

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import com.kyvronix.phoneguard.alarm.AlarmController
import com.kyvronix.phoneguard.security.DeviceAdminReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "lost_phone_finder/channel"
    private var pendingDeactivationResult: MethodChannel.Result? = null
    private val DEACTIVATE_ADMIN_REQUEST_CODE = 1002

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "deactivateDeviceAdmin" -> {
                        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                        if (keyguardManager.isKeyguardSecure) {
                            val intent = keyguardManager.createConfirmDeviceCredentialIntent("Authentication Required", "Please verify your screen lock to disable protection.")
                            if (intent != null) {
                                pendingDeactivationResult = result
                                startActivityForResult(intent, DEACTIVATE_ADMIN_REQUEST_CODE)
                            } else {
                                deactivateAdmin()
                                result.success(true)
                            }
                        } else {
                            deactivateAdmin()
                            result.success(true)
                        }
                    }
                    "startAlarm" -> {
                        val intent = Intent(this, com.kyvronix.phoneguard.services.AlarmService::class.java)
                        startServiceCompat(intent)
                        result.success(true)
                    }
                    "stopAlarm" -> {
                        val intent = Intent(this, com.kyvronix.phoneguard.services.AlarmService::class.java)
                        stopService(intent)
                        result.success(true)
                    }
                    "lockDevice" -> {
                        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
                        if (dpm.isAdminActive(componentName)) {
                            dpm.lockNow()
                            result.success(true)
                        } else {
                            result.error("NOT_ADMIN", "Device admin not active", null)
                        }
                    }
                    "requestDeviceAdmin" -> {
                        val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                            putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Required for remote locking")
                        }
                        startActivityForResult(intent, 1)
                        result.success(true)
                    }
                    "isDeviceAdminActive" -> {
                        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
                        result.success(devicePolicyManager.isAdminActive(componentName))
                    }
                    "startTrackingService" -> {
                        val number = call.argument<String>("targetNumber")
                        val intent = Intent(this, com.kyvronix.phoneguard.services.TrackingService::class.java).apply {
                            putExtra("trustedNumber", number)
                        }
                        startServiceCompat(intent)
                        result.success(true)
                    }
                    "stopTrackingService" -> {
                        val intent = Intent(this, com.kyvronix.phoneguard.services.TrackingService::class.java)
                        stopService(intent)
                        result.success(true)
                    }
                    "sendSms" -> {
                        val to = call.argument<String>("to")
                        val message = call.argument<String>("message")
                        if (to != null && message != null) {
                            // SMS removed
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Missing 'to' or 'message'", null)
                        }
                    }
                    "startFirestoreCommandService" -> {
                        val intent = Intent(this, com.kyvronix.phoneguard.services.FirestoreCommandService::class.java)
                        startServiceCompat(intent)
                        result.success(true)
                    }
                    "stopFirestoreCommandService" -> {
                        val intent = Intent(this, com.kyvronix.phoneguard.services.FirestoreCommandService::class.java)
                        stopService(intent)
                        result.success(true)
                    }
                    "startRecoveryService" -> {
                        // Start the ContentObserver-based SMS monitor so ALL numbers work,
                        // even if other apps block the SMS_RECEIVED broadcast.
                        val intent = Intent(this, com.kyvronix.phoneguard.services.RecoveryService::class.java)
                        startServiceCompat(intent)
                        result.success(true)
                    }
                    "captureIntruderPhoto" -> {
                        val intent = Intent(this, com.kyvronix.phoneguard.security.IntrusionCameraService::class.java)
                        startServiceCompat(intent)
                        result.success(true)
                    }
                    "isAlarmActive" -> result.success(isServiceRunning(com.kyvronix.phoneguard.services.AlarmService::class.java))
                    "isTrackingRunning" -> result.success(isServiceRunning(com.kyvronix.phoneguard.services.TrackingService::class.java))
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
                        result.success(true)
                    }
                    "openAppInfo" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.fromParts("package", packageName, null)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "openBatteryOptimizationSettings" -> {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "isNotificationListenerEnabled" -> {
                        val pkgName = packageName
                        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                        val enabled = flat != null && flat.contains(pkgName)
                        result.success(enabled)
                    }
                    "openNotificationListenerSettings" -> {
                        val intent = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP_MR1) {
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        } else {
                            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        val intent = Intent("android.settings.NOTIFICATION_SETTINGS")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback if the device doesn't support the generic notification settings intent
                            val fallbackIntent = Intent(Settings.ACTION_SETTINGS)
                            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(fallbackIntent)
                            result.success(true)
                        }
                    }
                    "isGoogleMessagesDefault" -> {
                        val defaultSmsApp = android.provider.Telephony.Sms.getDefaultSmsPackage(this)
                        result.success(defaultSmsApp == "com.google.android.apps.messaging")
                    }
                    "requestGoogleMessagesDefault" -> {
                        try {
                            packageManager.getPackageInfo("com.google.android.apps.messaging", 0)
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                                val roleManager = getSystemService(android.app.role.RoleManager::class.java)
                                if (roleManager!!.isRoleAvailable(android.app.role.RoleManager.ROLE_SMS)) {
                                    if (!roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_SMS)) {
                                        val intent = roleManager.createRequestRoleIntent(android.app.role.RoleManager.ROLE_SMS)
                                        startActivityForResult(intent, 1003)
                                    }
                                }
                            } else {
                                val intent = Intent(android.provider.Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                                intent.putExtra(android.provider.Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, "com.google.android.apps.messaging")
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: PackageManager.NameNotFoundException) {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse("market://details?id=com.google.android.apps.messaging")))
                            } catch (anfe: android.content.ActivityNotFoundException) {
                                startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.messaging")))
                            }
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "MethodChannel error: ${e.message}")
                result.error("NATIVE_ERROR", e.message, null)
            }
        }
    }

    private fun startServiceCompat(intent: Intent) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DEACTIVATE_ADMIN_REQUEST_CODE) {
            if (resultCode == android.app.Activity.RESULT_OK) {
                deactivateAdmin()
                pendingDeactivationResult?.success(true)
            } else {
                pendingDeactivationResult?.success(false)
            }
            pendingDeactivationResult = null
        }
    }

    private fun deactivateAdmin() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
        if (dpm.isAdminActive(componentName)) {
            dpm.removeActiveAdmin(componentName)
        }
    }

    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }
}

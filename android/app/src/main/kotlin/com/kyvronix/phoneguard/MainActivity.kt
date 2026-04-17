package com.kyvronix.phoneguard

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import com.kyvronix.phoneguard.alarm.AlarmController
import com.kyvronix.phoneguard.security.DeviceAdminReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "lost_phone_finder/channel"

    override fun onResume() {
        super.onResume()
        // Protection status re-check if needed, but no longer excluding from recents
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "deactivateDeviceAdmin" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
                    if (dpm.isAdminActive(componentName)) {
                        dpm.removeActiveAdmin(componentName)
                    }
                    result.success(true)
                }
                "startAlarm" -> {
                    val intent = Intent(this, com.kyvronix.phoneguard.services.AlarmService::class.java)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
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
                    val isActive = devicePolicyManager.isAdminActive(componentName)
                    result.success(isActive)
                }
                "startTrackingService" -> {
                    val number = call.argument<String>("targetNumber")
                    val intent = Intent(this, com.kyvronix.phoneguard.services.TrackingService::class.java).apply {
                        putExtra("trustedNumber", number)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
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
                        com.kyvronix.phoneguard.sms.SmsSender.sendSms(this, to, message)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing 'to' or 'message'", null)
                    }
                }
                "isAlarmActive" -> {
                    result.success(isServiceRunning(com.kyvronix.phoneguard.services.AlarmService::class.java))
                }
                "isTrackingRunning" -> {
                    result.success(isServiceRunning(com.kyvronix.phoneguard.services.TrackingService::class.java))
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }
}

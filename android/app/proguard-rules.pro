# ════════════════════════════════════════════════════════════════
#  PhoneGuard — ProGuard / R8 Rules
#  Applied only to release builds (isMinifyEnabled = true)
# ════════════════════════════════════════════════════════════════

# ── General R8 behaviour ────────────────────────────────────────
# Strip all debug logging in release (no Log.d/v output visible)
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
}

# Keep line numbers in stack traces so Firebase Crashlytics can
# show meaningful crash reports (does NOT re-add class names)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ── Flutter engine ───────────────────────────────────────────────
# Flutter's embedding layer uses reflection; must NOT be obfuscated
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ── Firebase ─────────────────────────────────────────────────────
# Firebase uses reflection heavily; keep all Firebase classes intact
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Firebase Messaging service (registered in Manifest by package name)
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# ── Android Components registered in AndroidManifest.xml ────────
# Classes referenced by name in the Manifest MUST be kept exactly.
# R8 renames classes by default — that breaks Manifest lookups.
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.admin.DeviceAdminReceiver

# ── PhoneGuard native services (critical — Manifest references) ──
-keep class com.kyvronix.phoneguard.** { *; }

# ── Kotlin & Coroutines ──────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# Keep Kotlin serialization metadata
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# ── WorkManager ──────────────────────────────────────────────────
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# ── CameraX ──────────────────────────────────────────────────────
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ── JSON / Reflection ────────────────────────────────────────────
# org.json is used directly (JSONObject, JSONArray) — safe to keep
-keep class org.json.** { *; }

# ── Guava ────────────────────────────────────────────────────────
-dontwarn com.google.common.**
-keep class com.google.common.** { *; }

# ── Remove unused warnings ───────────────────────────────────────
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
-dontwarn java.lang.invoke.**

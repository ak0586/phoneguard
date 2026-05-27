# 🔒 PhoneGuard — Security Architecture & Hardening Specifications

This document outlines the security controls, validation strategies, input verification mechanisms, and authorization layers built into PhoneGuard to prevent unauthorized access.

---

## 1. Device Administration Authorization Loop

PhoneGuard uses the Android **Device Administration API** to lock the device remotely. To prevent a thief from easily disabling this permission, PhoneGuard implements a secure deactivation loop.

```
┌────────────────────────┐
│  Deactivate Command    │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐      Yes      ┌────────────────────────┐
│   Is Lockscreen Secure?├──────────────➔│  Confirm Credentials   │
└──────────┬─────────────┘               │  (PIN/Pattern Prompt)  │
           │ No                          └──────────┬─────────────┘
           │                                        │ Authorized
           ▼                                        ▼
┌────────────────────────┐               ┌────────────────────────┐
│ Remove Device Admin    │               │ Remove Device Admin    │
└────────────────────────┘               └────────────────────────────────┘
```

1.  **Lockscreen Check**: When a user attempts to disable Device Admin in [MainActivity.kt](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/kotlin/com/kyvronix/phoneguard/MainActivity.kt#L27-L42), the app queries `KeyguardManager.isKeyguardSecure()`.
2.  **Credential Challenge**: If lockscreen security (PIN, pattern, password) is enabled, the system intercepts the request and launches `createConfirmDeviceCredentialIntent("Authentication Required")`.
3.  **Result Verification**: The admin privilege is only removed if the user successfully authenticates. If the prompt is dismissed or fails, the removal is blocked.

---

## 2. Remote Command Verification: Fuzzy Matching & Normalization

To prevent unauthorized users from triggering recovery actions via SMS, PhoneGuard validates the sender's identity against the user's whitelisted trusted numbers.

### A. Number Normalization
Before comparison, numbers are normalized in `CommandParser.kt` to strip out formatting variations:
```kotlin
private fun normalizeNumber(raw: String): String {
    val digits = raw.filter { it.isDigit() }
    return if (digits.length >= 10) {
        digits.takeLast(10) // Keep the last 10 digits to handle country code variations
    } else {
        digits.trimStart('0')
    }
}
```

### B. Verification Strategies
PhoneGuard implements four lookup strategies in `numbersMatch()` to ensure sender authenticity:

1.  **Exact Matching**: Compares the last 10 digits directly.
2.  **Suffix Overlap**: Compares whether one number ends with the other (e.g. `+919876543210` matches `9876543210`).
3.  **Adaptive Last-N**: Compares trailing digits down to a minimum threshold of 7 digits, preventing formatting mismatches.
4.  **Bidirectional Suffix Checking**: Ensures matches are verified regardless of which number has the country code format prefix.

---

## 3. Command Deduplication & Replay Prevention

To prevent command replay attacks and infinite location request loops (which exhaust battery and SMS limits), PhoneGuard applies two levels of deduplication:

### A. Wall-Clock Window Deduplication
In `CommandParser.kt`, incoming messages are logged in memory using a synchronized cache mapping:
*   **Deduplication Key**: `normalized_sender_address:message_body_hash`
*   **Validity Window**: 60 seconds (`DEDUPE_WINDOW_MS = 60_000L`)
*   **Outcome**: Duplicate commands sent from the same sender within this window are discarded.

### B. Outgoing SMS Deduplication
In `SmsSender.kt`, outgoing SMS messages are gated using a deduplication cache:
*   **Key**: `target_number|message_body`
*   **Validity Window**: 30 seconds (`SEND_DEDUPE_MS = 30_000L`)
*   **Outcome**: Prevents duplicate location updates from being sent to the same number, even if multiple detection events (standard broadcast receiver and SMS DB observer) fire concurrently.

---

## 4. API & Cloud Database Rules

All network operations are authenticated and validated.

*   **Session Management**: Handled via Firebase Authentication. User profiles and metadata are synced using tokens generated from OAuth or Email Sign-in flows.
*   **No Public APIs**: PhoneGuard does not expose custom backend endpoints. The web dashboard communicates with the client device by writing configuration details to Firestore and triggering FCM data payloads.
*   **Firestore Rules**: Write privileges on `users/{uid}` require `request.auth.uid == uid`, ensuring users can only read and write data from their own devices.

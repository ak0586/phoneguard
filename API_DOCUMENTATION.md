# 📡 PhoneGuard — API & Integration Specification

This document details the communication contracts, payload structures, message validation rules, and lifecycle flows of remote commands sent between the PhoneGuard Web Dashboard and the mobile application.

---

## 1. Remote Command Architecture

Communication between the web dashboard and the mobile device is structured around **Firebase Cloud Messaging (FCM)** as the primary transport layer and **Cloud Firestore** as the database layer.

```
┌─────────────────┐       Writes "pendingCommand"        ┌─────────────────┐
│  Web Dashboard  ├─────────────────────────────────────➔│ Cloud Firestore │
└────────┬────────┘                                      └────────┬────────┘
         │                                                        ▲
         │ Dispatches FCM Push Command                            │ Writes Results
         ▼                                                        │
┌─────────────────┐           Delivers Data Payload      ┌────────┴────────┐
│   FCM Gateway   ├─────────────────────────────────────➔│ Mobile App (OS) │
└─────────────────┘                                      └─────────────────┘
```

*   **FCM Data Messaging**: FCM data messages bypass user notification rendering and boot up background service handlers natively on the OS.
*   **Firestore Synchronization Fallback**: The client device runs a `FirestoreCommandService` that registers a document listener. If an internet reconnection is made, pending command fields are immediately synchronized.

---

## 2. Firebase Cloud Messaging (FCM) API

FCM data-only messages are dispatched from the Next.js API backend to the mobile app client.

*   **Protocol**: HTTP v1 API
*   **Endpoint**: `https://fcm.googleapis.com/v1/projects/{project-id}/messages:send`
*   **Headers**:
    *   `Authorization: Bearer <ACCESS_TOKEN>`
    *   `Content-Type: application/json`

### Request Payload Structure

```json
{
  "message": {
    "token": "d_1_fCmToken_From_Firestore_Document...",
    "data": {
      "type": "DASHBOARD_COMMAND",
      "action": "action_identifier"
    },
    "android": {
      "priority": "high",
      "ttl": "60s"
    }
  }
}
```

### Supported Action Identifiers

| Action Value | Operation Target | Execution Payload / Side Effects |
| :--- | :--- | :--- |
| `alarm` | Loud Siren | Activates the foreground `AlarmService` and overrides audio stream parameters to maximum volume. |
| `stop` | Stop Alarm/Tracking | Stops the foreground `AlarmService` and terminates the `TrackingService`. |
| `lock` | Lock Screen | Invokes the Device Admin `DevicePolicyManager.lockNow()` method to instantly lock the display. |
| `location` | Retrieve GPS | Triggers the 3-tier GPS manager and pushes coordinate coordinates back to Firestore. |
| `tracking` | Continuous Tracking | Launches the `TrackingService` to transmit locations at a 3-minute interval. |

---

## 3. Firestore State Synchronization Schema

All client state, logs, and configurations are mapped under the `users/{user_uid}` document.

### A. Core Schema Structure

```json
{
  "uid": "Uq2Z...",
  "name": "Alex Carter",
  "email": "alex.carter@domain.com",
  "mobile": "+919876543210",
  "fcmToken": "fcm_token_string...",
  "isPremium": true,
  "protectionExpiry": "2026-06-27T12:00:00.000Z",
  "currentDeviceId": "device_uuid...",
  "deviceModel": "OnePlus CPH2693",
  "osVersion": "Android 14 (SDK 34)",
  "lastLatitude": 28.6139,
  "lastLongitude": 77.2090,
  "locationUpdatedAt": "2026-05-27T13:20:00.000Z",
  "lastActive": "2026-05-27T13:22:00.000Z",
  "isOnline": true,
  "intrusionPhotos": []
}
```

### B. Command Payload Schema (`pendingCommand`)

The web dashboard updates this map to request action execution.

*   **Path**: `users/{uid}`
*   **Field Key**: `pendingCommand`
*   **Schema Map**:

```json
{
  "pendingCommand": {
    "action": "alarm",
    "issuedAt": {
      "_seconds": 1779979200,
      "_nanoseconds": 500000000
    }
  }
}
```

### C. Command Result Schema (`commandResult`)

The mobile client updates this map upon executing the requested action, clearing the `pendingCommand` field.

*   **Path**: `users/{uid}`
*   **Field Key**: `commandResult`
*   **Schema Map**:

```json
{
  "commandResult": {
    "action": "alarm",
    "status": "executed",
    "at": {
      "_seconds": 1779979205,
      "_nanoseconds": 100000000
    }
  }
}
```

#### Status Response Code Dictionary

*   `executed`: Command successfully run on the device.
*   `expired`: Command execution blocked because the device's protection license has expired.
*   `invalid_args`: Execution rejected due to missing action details or parameter structures.
*   `failed`: Operation failed on Android due to missing hardware permissions.

---

## 4. Sub-Collections

### `activity_logs`
Logs of recovery actions executed on the device are written to this sub-collection for permanent user reference.

*   **Path**: `users/{uid}/activity_logs/{log_id}`
*   **Field Schema**:

```json
{
  "id": "log_uuid_string",
  "timestamp": "2026-05-27T13:20:05.123Z",
  "senderNumber": "WEB_DASHBOARD",
  "command": "alarm",
  "result": "Alarm started successfully",
  "success": true
}
```

---

## 5. Security & Authentication Checks

All operations passing through the Web-to-App API must satisfy these requirements:

1.  **Firebase Auth Rules**: The web application writes to `users/{uid}` using an authenticated SDK. Writes to the document require that `request.auth.uid == uid`.
2.  **Protection Expirations**: The native `CommandParser` parses the local cached `SharedPreferences` variables (`flutter.is_premium` and `flutter.protection_expiry`) to ensure the device license is active before running commands.
3.  **FCM Data Validation**: The `FcmCommandHandler` checks the `type` property in the incoming push data. It ignores any message that does not contain `"type": "DASHBOARD_COMMAND"`.

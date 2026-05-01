# PhoneGuard Quality Assurance Test Plan

This document outlines a comprehensive, step-by-step testing strategy to verify all features of the PhoneGuard Android app and the Next.js Web Dashboard. Follow these steps to ensure end-to-end functionality.

---

## Phase 1: Initial Setup & Authentication

### 1. Account Creation
- [ ] Open the app on a fresh install.
- [ ] Register a new account with a valid email and password.
- [ ] **Expected Result:** Account is created, user is directed to the email verification screen or setup wizard.

### 2. Login Flow
- [ ] Log out and log back in using the created credentials.
- [ ] Click "Forgot Password", enter the email, and verify the reset link is sent.
- [ ] **Expected Result:** Successful login redirects to the Dashboard. Password reset email arrives.

### 3. Permissions Wizard
- [ ] Proceed through the setup wizard.
- [ ] Grant Location, SMS, Background Services, and Camera permissions.
- [ ] **Expected Result:** The wizard only advances when all required permissions are granted.

---

## Phase 2: Security & Device Administration

### 4. Device Admin Activation
- [ ] Go to the Dashboard, locate the "Device Admin Status" card.
- [ ] Toggle Device Admin ON.
- [ ] **Expected Result:** The Android system prompt appears. Accepting it turns the toggle green.

### 5. Uninstall Protection (Hardened)
- [ ] Attempt to uninstall the app from the Android Home Screen or Settings.
- [ ] **Expected Result:** Android blocks the uninstallation stating the app is an active device administrator.
- [ ] Go to PhoneGuard Dashboard -> Toggle Device Admin OFF.
- [ ] **Expected Result:** You must pass the Android System Lock (PIN/Biometrics) before the app actually deactivates the admin privileges.

### 6. App Lock & Silent Intrusion Capture
- [ ] Go to Settings/Profile and set an **App PIN**.
- [ ] Fully close the app and reopen it.
- [ ] **Expected Result:** The custom PhoneGuard App Lock screen appears.
- [ ] Enter the **wrong PIN** 3 times in a row.
- [ ] **Expected Result:** The app silently captures a photo using the front camera.
- [ ] Enter the correct PIN to unlock. Check the "Intrusion Alerts" card on the Dashboard.
- [ ] **Expected Result:** The captured photo appears in the gallery with a timestamp.

---

## Phase 3: Offline Execution (SMS Commands)

*Note: Requires a second phone to send SMS messages.*

### 7. Trigger Keyword & Trusted Numbers
- [ ] Set your Trigger Keyword (e.g., `#GUARD`).
- [ ] Add the second phone's number to the **Trusted Numbers** list.

### 8. SMS Alarm
- [ ] Send SMS from the trusted number: `#GUARD alarm`
- [ ] **Expected Result:** The phone begins ringing loudly, bypassing silent/Do Not Disturb mode.
- [ ] Send SMS: `#GUARD stop`
- [ ] **Expected Result:** The alarm stops.

### 9. SMS Lock
- [ ] Send SMS from the trusted number: `#GUARD lock`
- [ ] **Expected Result:** The device screen immediately turns off and locks (Requires Device Admin).

### 10. SMS Location Tracking
- [ ] Send SMS from the trusted number: `#GUARD track`
- [ ] **Expected Result:** The phone replies via SMS with Google Maps links containing its live location.

### 11. Unauthorized Access Test
- [ ] Send `#GUARD alarm` from a completely different, **un-trusted** phone number.
- [ ] **Expected Result:** The phone ignores the command.

---

## Phase 4: Web Dashboard & Real-Time Sync

### 12. Dashboard Login
- [ ] Run the Next.js web dashboard (`npm run dev`) and open `localhost:3000`.
- [ ] Log in with the same Firebase credentials used in the app.
- [ ] **Expected Result:** The dashboard loads and successfully syncs the device's Model, OS Version, and Online Status.

### 13. Real-Time Remote Controls
- [ ] Click **"Locate"** on the web dashboard.
- [ ] **Expected Result:** The Android app receives the command instantly via Firestore and updates its location. The Leaflet Map on the web dashboard updates to show the pin.
- [ ] Click **"Sound Alarm"** on the web dashboard.
- [ ] **Expected Result:** The phone immediately rings loudly.
- [ ] Click **"Lock Device"** on the web dashboard.
- [ ] **Expected Result:** The phone screen locks instantly.

### 14. Remote Intrusion Gallery
- [ ] Verify that the Intrusion Photos taken during Phase 2 (Step 6) are visible in the "Intrusion Alerts" section of the web dashboard.

### 15. Admin Role Verification
- [ ] Manually change your user document in the Firebase Console to have `role: 'admin'`.
- [ ] Refresh the web dashboard.
- [ ] **Expected Result:** The "Admin Overview" section appears at the bottom, displaying KPI charts (Total Devices, Online Users) and a comprehensive table of all managed devices.

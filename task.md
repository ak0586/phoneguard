# Lost Phone Finder - Development Roadmap

## Phase 1: Immediate Fixes & Visibility
- [ ] **Fix Activity Logs:** Resolve JSON serialization mismatch between Kotlin and Dart.
- [ ] **Running Actions Monitor:**
    - [ ] Create `ActionMonitorService` (Kotlin) to track active alarm/tracking.
    - [ ] Add `ActiveActions` view in the Dashboard to see what's running.
    - [ ] Add "Stop All" button to locally kill remote-triggered actions.

## Phase 2: User Accounts & Profiles
- [ ] **Firebase Integration:**
    - [ ] Add Firebase Auth (Login, Register).
    - [ ] Implement "Verify Email" banner/warning in Dashboard.
- [ ] **Profile Management:**
    - [ ] Create Profile screen.
    - [ ] Implement Edit Profile (Name, Phone, secondary contact).
- [ ] **Cloud Storage:**
    - [ ] Upload "Thief Selfie" to Firebase Storage.
    - [ ] Store/Sync latest Location to Firestore for remote viewing (web dashboard support).

## Phase 3: Monetization & Polish
- [ ] **Ad System:**
    - [ ] Integrate Google Mobile Ads (AdMob).
    - [ ] Show subtle banner ads and interstitial for premium features.
- [ ] **Subscription Model:**
    - [ ] Integrate RevenueCat or direct Play Billing.
    - [ ] Create "Go Premium" screen with feature unlocks (No ads, Cloud backup).
- [ ] **Payment Integration:**
    - [ ] Integrate Stripe or Razorpay for direct payments.

## Phase 4: Security Enhancements
- [ ] **SIM Change Detection:** Notify trusted numbers if SIM card is swapped.
- [ ] **Uninstall Protection:** Guide user to enable Device Admin + extra hurdles for uninstalling.

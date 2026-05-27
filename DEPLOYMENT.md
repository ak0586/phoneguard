# 🚀 PhoneGuard — Build Pipeline & Production Deployment

This document provides step-by-step instructions on compiling, signing, configuring cloud infrastructure, and releasing PhoneGuard to production.

---

## 1. Keystore Configuration & Application Signing

Before uploading a release build to the Google Play Store, Android requires the application package to be signed with a production keystore.

### Step A: Generate a Release Keystore
Generate a cryptographically secure key file using the Java `keytool` utility:

```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias phoneguard-key-alias
```

*Note: Save this key file securely. If lost, you cannot push updates to existing installations on the Play Store.*

### Step B: Configure signature properties
Create or update [android/key.properties](file:///d:/Flutter%20Apps/phoneguard/android/key.properties) with the keystore details:

```properties
storePassword=keystore_encryption_password
keyPassword=key_alias_password
keyAlias=phoneguard-key-alias
storeFile=D:/Flutter Apps/phoneguard/android/release-keystore.jks
```

### Step C: Link properties to Gradle build
Ensure [android/app/build.gradle](file:///d:/Flutter%20Apps/phoneguard/android/app/build.gradle) reads this file dynamically:

```groovy
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new java.io.FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystoreProperties.size() > 0) {
                storeFile = file(keystoreProperties['storeFile'])
                storePassword = keystoreProperties['storePassword']
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
    }
}
```

---

## 2. Production Compile Pipeline

Compile the application into a highly optimized, obfuscated Android App Bundle (`.aab` format):

```bash
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info/v1.2.5+14
```

### Parameter Breakdown

*   `appbundle`: Builds the target deployment package format containing compiled native architectures (ARM64, ARM32, x86_64).
*   `--release`: Compiles with optimal compiler flags, stripping development debugging overhead.
*   `--obfuscate`: Obfuscates Dart codebase class methods and variable keys to make reverse engineering difficult.
*   `--split-debug-info`: Strips debug symbols from the output package, reducing app download size and saving symbol maps to a local directory for log deobfuscation.

---

## 3. Firebase Console Configuration

Ensure the Firebase console is configured to support production operations:

### Step A: Configure Security Fingerprints
1.  Obtain your production keystore SHA certificate fingerprints:
    ```bash
    keytool -list -v -keystore release-keystore.jks -alias phoneguard-key-alias
    ```
2.  Add both the **SHA-1** and **SHA-256** fingerprints to your Android App settings inside the Firebase Console. This is required for Google Sign-in authentication and FCM notifications.

### Step B: Enable Google Sign-In Client ID
1.  Go to **Authentication** ➔ **Sign-in method** ➔ **Google**.
2.  Enable the provider and save. Firebase generates a web client ID and link tokens automatically.

### Step C: Deploy Firestore Security Rules
Deploy secure, isolated access parameters to your Firestore instance:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /activity_logs/{logId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /system_config/app_version {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

---

## 4. AdMob Ad ID Integration

To serve ads for extended protection:

1.  Add your production AdMob Application ID to [android/app/src/main/AndroidManifest.xml](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/AndroidManifest.xml):
    ```xml
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-################~##########"/>
    ```
2.  Ensure production Ad unit identifiers (Reward Ads and Native Ads) are updated in [ad_service.dart](file:///d:/Flutter%20Apps/phoneguard/lib/data/datasources/ad_service.dart).

---

## 5. CI/CD Deployment Workflow

This configuration automates release generation on tag updates using GitHub Actions.

*   **Config File**: `.github/workflows/deploy.yml`
*   **Workflow Logic**:

```yaml
name: Compile Production Android Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Set up Java Development Kit
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.4'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Decode Keystore Configuration
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/release-keystore.jks
          echo "${{ secrets.KEY_PROPERTIES }}" > android/key.properties
          echo "${{ secrets.GOOGLE_SERVICES_JSON }}" > android/app/google-services.json

      - name: Build signed App Bundle
        run: |
          flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

      - name: Upload Bundle Artifact
        uses: actions/upload-artifact@v3
        with:
          name: phoneguard-release-bundle
          path: build/app/outputs/bundle/release/app-release.aab
```

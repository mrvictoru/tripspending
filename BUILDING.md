# Building TripSpending for Android

This guide covers everything you need to know to build the TripSpending app as an Android APK, create a release build, and publish to the Google Play Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start - Build Debug APK](#quick-start---build-debug-apk)
3. [Build Release APK](#build-release-apk)
4. [App Signing for Release](#app-signing-for-release)
5. [Build App Bundle for Play Store](#build-app-bundle-for-play-store)
6. [Publishing to Google Play Store](#publishing-to-google-play-store)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Install Flutter SDK

Download and install Flutter from [flutter.dev](https://docs.flutter.dev/get-started/install):

```bash
# Verify installation
flutter doctor
```

Make sure you see ✓ for Android toolchain.

### 2. Install Android Studio

1. Download [Android Studio](https://developer.android.com/studio)
2. Install Android SDK (API level 34 recommended)
3. Install Android SDK Build-Tools
4. Install Android SDK Command-line Tools
5. Accept licenses:
   ```bash
   flutter doctor --android-licenses
   ```

### 3. Configure Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable "Maps SDK for Android"
4. Create an API key with Android app restrictions
5. Add the key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_ACTUAL_API_KEY"/>
   ```

### 4. Install Dependencies

```bash
cd frontend
flutter pub get
```

---

## Quick Start - Build Debug APK

The fastest way to get an APK for testing:

```bash
cd frontend

# Build debug APK
flutter build apk --debug

# The APK will be at:
# build/app/outputs/flutter-apk/app-debug.apk
```

**Install on device:**
```bash
# Via ADB (device connected via USB with debugging enabled)
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or transfer the APK file to your phone and install manually
```

---

## Build Release APK

Release APK is optimized, smaller, and faster:

```bash
cd frontend

# Build release APK (without signing, for testing)
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build APK per ABI (Smaller Size)

Split the APK by CPU architecture for smaller file sizes:

```bash
flutter build apk --release --split-per-abi

# Creates multiple APKs:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  (~10MB smaller)
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    (Most common)
# build/app/outputs/flutter-apk/app-x86_64-release.apk       (For emulators)
```

---

## App Signing for Release

To publish on Play Store or distribute a signed APK, you need to sign your app.

### Step 1: Generate a Keystore

```bash
# Create a keystore directory
mkdir -p frontend/android/keystore

# Generate a new keystore
keytool -genkey -v -keystore frontend/android/keystore/release-key.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias tripspending
```

You'll be prompted to enter:
- Keystore password
- Key password
- Your name, organization, city, state, country

⚠️ **IMPORTANT**: Keep your keystore file and passwords safe! You'll need the same keystore to update your app on Play Store.

### Step 2: Configure key.properties

```bash
# Copy the template
cp frontend/android/key.properties.example frontend/android/key.properties

# Edit with your values
nano frontend/android/key.properties
```

Fill in your actual values:
```properties
storeFile=../keystore/release-key.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=tripspending
keyPassword=YOUR_KEY_PASSWORD
```

⚠️ **NEVER commit `key.properties` or your `.jks` file to git!**

### Step 3: Build Signed Release APK

```bash
cd frontend
flutter build apk --release

# Signed APK at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Verify APK Signature

```bash
# Check if APK is signed
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

---

## Build App Bundle for Play Store

Google Play requires Android App Bundle (AAB) format:

```bash
cd frontend

# Build release app bundle
flutter build appbundle --release

# The bundle will be at:
# build/app/outputs/bundle/release/app-release.aab
```

---

## Publishing to Google Play Store

### Step 1: Create Developer Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay the one-time $25 registration fee
3. Complete identity verification

### Step 2: Create Your App

1. Click "Create app"
2. Fill in app details:
   - App name: **TripSpending**
   - Default language: English (or your preferred)
   - App or game: **App**
   - Free or paid: **Free** (recommended to start)

### Step 3: Set Up Your Store Listing

You'll need to provide:

#### App Details
- **Short description** (80 chars max):
  > Track travel expenses by scanning receipts with OCR. Local-first, privacy-focused.

- **Full description** (4000 chars max):
  > TripSpending helps you track your travel expenses effortlessly...
  > (Expand on features, privacy focus, etc.)

#### Graphics Assets
- **App icon**: 512x512 PNG (32-bit with alpha)
- **Feature graphic**: 1024x500 PNG or JPG
- **Screenshots**: 
  - Phone: 2-8 screenshots (16:9 or 9:16)
  - 7-inch tablet: optional
  - 10-inch tablet: optional

#### Categorization
- **Category**: Finance or Travel & Local
- **Tags**: expense tracker, receipt scanner, travel, OCR

### Step 4: Complete Content Rating

1. Go to "Content rating" in Play Console
2. Complete the questionnaire
3. Apply the rating to your app

### Step 5: Set Up Pricing & Distribution

1. Select countries for distribution
2. Confirm content guidelines compliance
3. Acknowledge export laws compliance

### Step 6: Upload Your App Bundle

1. Go to "Production" → "Create new release"
2. Upload your `app-release.aab` file
3. Add release notes
4. Save and review

### Step 7: Review and Publish

1. Review all sections are complete (green checkmarks)
2. Submit for review
3. Wait for approval (usually 1-7 days for new apps)

---

## Troubleshooting

### Common Build Errors

#### "SDK location not found"
Create `frontend/android/local.properties`:
```properties
sdk.dir=/path/to/your/Android/Sdk
flutter.sdk=/path/to/your/flutter
```

#### "Execution failed for task ':app:compileReleaseKotlin'"
```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

#### "AAPT: error: resource not found"
```bash
cd frontend/android
./gradlew clean
cd ..
flutter build apk --release
```

#### Minimum SDK Version Error
The app requires Android 5.0 (API 21) minimum. Ensure your device/emulator meets this.

#### Google Maps Not Showing
1. Verify API key is correct in AndroidManifest.xml
2. Ensure Maps SDK for Android is enabled in Google Cloud Console
3. Check API key restrictions match your app's package name

### Build Size Optimization

To reduce APK size:

```bash
# Use split APKs
flutter build apk --release --split-per-abi

# Or build app bundle (Google Play generates optimized APKs)
flutter build appbundle --release
```

### Testing on Physical Device

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Install release APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## Updating Your App

For updates, increment the version in `pubspec.yaml`:

```yaml
version: 1.0.1+2  # format: major.minor.patch+buildNumber
```

- `1.0.1` = Version name (shown to users)
- `+2` = Version code (must increase with each upload)

Then build and upload the new bundle to Play Console.

---

## Security Checklist

Before publishing:

- [ ] Remove any debug/test API keys
- [ ] Add your production Google Maps API key
- [ ] Ensure `key.properties` is in `.gitignore`
- [ ] Keep your keystore backed up securely
- [ ] Test the release APK on multiple devices
- [ ] Verify all permissions are necessary
- [ ] Test offline functionality
- [ ] Review privacy policy requirements

---

## Additional Resources

- [Flutter Android Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Play Store Guidelines](https://play.google.com/about/developer-content-policy/)

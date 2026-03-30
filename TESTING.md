# Local Testing Guide

## Prerequisites

- Flutter SDK installed and on PATH (`flutter doctor` passes)
- A connected device or running emulator
- Java 8+ (for Android builds)

---

## 1. Flutter Unit & Widget Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run with verbose output
flutter test --reporter expanded

# Run with coverage (requires lcov installed)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Golden file test

The screenshot test in `test/screenshot_test.dart` uses golden files for visual regression. The reference image is stored at `test/goldens/fitworld_preview.png`.

```bash
# Run the golden test
flutter test test/screenshot_test.dart

# Update golden files after intentional UI changes
flutter test --update-goldens test/screenshot_test.dart
```

---

## 2. Running Without Firebase (Demo Mode)

The app detects a missing Firebase configuration and starts in demo mode automatically — no extra setup needed. In this mode:

- Firebase Auth, Firestore, and notifications are disabled
- Characters can still be added manually via the "ADD WARRIOR" / "ADD RANGER" buttons in the HUD
- The Flame game world renders normally
- Status bar shows "Avvio in modalità demo" (Starting in demo mode)

This is the fastest way to test game rendering and UI without any backend setup.

```bash
flutter run
```

---

## 3. Running With Firebase Emulators

For full end-to-end testing including Firestore persistence and Cloud Functions:

### Step 1 — Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 2 — Start the emulators

```bash
cd functions
npm install
npm run serve
# This builds the TypeScript and starts: Functions + Firestore emulators
```

The emulator UI is available at `http://localhost:4000` by default.

### Step 3 — Point the Flutter app at the emulators

In `lib/main.dart`, after `Firebase.initializeApp()`, add emulator overrides:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Inside main(), after Firebase.initializeApp():
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
```

> Remove these lines before building for production.

### Step 4 — Run the app

```bash
flutter run
```

The app will connect to the local emulators. Characters and world state will be stored in the emulated Firestore and cleared when the emulator restarts.

---

## 4. Testing Health Data Integration

### Android — Health Connect

Health data on Android requires a physical or virtual device with Health Connect installed. Health Connect is not available on standard Android emulators by default.

**Option A: Physical Android device**
1. Install the Health Connect app from the Play Store
2. Grant the app permissions when prompted on first launch
3. Add sample workout data in Health Connect or via another fitness app

**Option B: Android emulator with Health Connect**
1. Use an emulator with Play Store support (Pixel device image)
2. Install Health Connect from Play Store on the emulator
3. Use the Health Connect app to manually add exercise sessions for testing

### iOS — HealthKit

HealthKit requires a **physical iOS device** — it cannot be tested in the iOS simulator.

1. Connect a physical iPhone
2. Build and run the app: `flutter run -d <device-id>`
3. Grant health permissions when prompted
4. Add workout data via the Health app or Apple Watch

### Bypassing Health Data (Manual Testing)

The HUD buttons "ADD WARRIOR" and "ADD RANGER" add characters directly without reading health data. Use these to test character spawning, rendering, and game mechanics without a health data source.

---

## 5. Testing Cloud Functions Locally

```bash
cd functions
npm run serve
```

### Trigger the nightly decay manually

With the emulator running, call the decay function via the Firebase Emulator UI (`http://localhost:4000`) or using the Firebase CLI:

```bash
firebase functions:shell
# Inside the shell:
nightlyDecay()
```

### Inspect Firestore data

Open `http://localhost:4000/firestore` to browse all documents, inspect character HP values, and verify decay results in real time.

---

## 6. Build Variants

```bash
# Debug build (default for flutter run)
flutter run --debug

# Profile build (performance testing, no debug overhead)
flutter run --profile

# Release build
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS (requires Xcode)
```

> Release builds require a signing config. See the TODOs in `android/app/build.gradle` for signing setup.

---

## 7. Useful Flutter Commands

```bash
# Check environment health
flutter doctor -v

# List connected devices
flutter devices

# Clean build cache (fixes most build errors)
flutter clean && flutter pub get

# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/
```

# FitWorld

A Flutter mobile game that turns your real workouts into RPG characters. Fitness activity tracked via Health Connect (Android) or HealthKit (iOS) spawns in-game heroes that live, grow, and die based on how active you are.

## How It Works

Each workout session generates a character whose class and stats are derived from the activity type and intensity:

| Workout | Character Class | Primary Stat |
|---|---|---|
| Strength training | Warrior | STR |
| Running / Walking / Hiking | Ranger | SPD |
| Cycling | Knight | STR + SPD |
| Swimming | Mage | WILL |
| HIIT | Assassin | DEX |
| Yoga / Pilates | Druid | WILL |

Characters start with HP scaled to workout intensity (`50 + intensity * 0.5`). They lose 3 HP per day of inactivity. When HP reaches 0 they are deleted. Keep working out to keep your team alive.

World health (0–100%) reflects the average HP across all your characters and is displayed in the game HUD.

## Architecture

```
fitworld/
├── lib/
│   ├── main.dart               # Entry point, Firebase init, app shell
│   ├── game/                   # Flame engine components
│   │   ├── fitworld_game.dart  # Main game class, world rendering
│   │   └── character_sprite.dart
│   ├── models/                 # Data models
│   │   ├── character.dart      # Character stats, class, HP logic
│   │   └── workout_session.dart
│   └── services/
│       ├── world_controller.dart     # Startup orchestration, sync flow
│       ├── firestore_service.dart    # Firestore CRUD (characters, world state)
│       ├── health_service.dart       # Health Connect / HealthKit integration
│       └── notification_service.dart # FCM + local notifications
├── functions/                  # Firebase Cloud Functions (TypeScript)
│   └── src/
│       ├── index.ts            # Function exports
│       ├── nightlyDecay.ts     # Scheduled job at 02:00 UTC (decay + notifications)
│       └── onCharacterCreated.ts # Welcome notification trigger
├── android/                    # Android native config + Health Connect permissions
├── ios/                        # iOS native config
└── test/
    ├── widget_test.dart
    └── screenshot_test.dart    # Golden file UI test
```

**Tech stack:**
- Flutter 3.x / Dart ^3.6.2
- [Flame](https://flame-engine.org/) 1.22.0 — 2D game engine
- Firebase (Firestore, Auth, Cloud Messaging)
- Health 12.2.0 — Health Connect / HealthKit
- Firebase Cloud Functions (TypeScript, Node 20)

## Prerequisites

- Flutter SDK (Dart ^3.6.2) — [install guide](https://docs.flutter.dev/get-started/install)
- Android Studio or Xcode (for device/emulator)
- A Firebase project with Firestore, Auth, and Cloud Messaging enabled
- Node.js 20+ and Firebase CLI (for Cloud Functions)

**Android:** Health Connect requires Android 9+ (API 28+). The Health Connect app must be installed on the device.

**iOS:** HealthKit is available on iOS 8+. Testing health data requires a physical device.

## Firebase Setup

The app runs in **demo mode** if Firebase is not configured (no crash, health sync and persistence are disabled).

To enable full functionality:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Anonymous Authentication**, **Cloud Firestore**, and **Cloud Messaging**
3. Register your Android app (`com.fitworld.fitworld`) and download `google-services.json` → place it in `android/app/`
4. Register your iOS app and download `GoogleService-Info.plist` → place it in `ios/Runner/`
5. Run `flutterfire configure` or follow the [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview)

Firestore data structure:
```
users/{userId}/
  characters/{charId}   # Character documents
  meta/world            # World health state
```

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run on a specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

## Cloud Functions

```bash
cd functions
npm install

# Local development with emulator
npm run serve

# Deploy to Firebase
npm run deploy
```

The `nightlyDecay` function runs every day at 02:00 UTC. It reduces all characters' HP by 3, sends push notifications for characters with low HP or that have died, and recalculates world health.

## Testing

See [TESTING.md](TESTING.md) for a full local testing guide.

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

# scenario

A new Flutter project with Firebase as backend.

## Firebase setup

1. **Install FlutterFire CLI and log in**
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   ```

2. **Configure Firebase for the project**
   From the project root run:
   ```bash
   flutterfire configure
   ```
   This will:
   - Create or link a Firebase project
   - Register Android (com.scenario.scenario) and iOS apps
   - Generate `lib/firebase_options.dart` and add `google-services.json` / `GoogleService-Info.plist`

3. **Run the app**
   ```bash
   flutter pub get
   flutter run
   ```

To add more Firebase products (Auth, Firestore, etc.), add the package and run `flutterfire configure` again:
```bash
flutter pub add firebase_auth cloud_firestore
flutterfire configure
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# Android dev
./run_android_emulator.sh dev --build
# Android prod
./run_android_emulator.sh prod --build

# iOS dev
./run_ios_simulator.sh dev --build
# iOS prod
./run_ios_simulator.sh prod --build

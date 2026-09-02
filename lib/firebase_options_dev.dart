// Firebase options для dev-окружения (scenario-ba26a).
// Сгенерировано вручную из google-services.json / GoogleService-Info.plist (dev).
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DevFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DevFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZHt5DxJiNqXzrqAW99FX1y6-8UPX0ykI',
    appId: '1:602717699795:android:5ba28bf2cc6335e1db9e26',
    messagingSenderId: '602717699795',
    projectId: 'scenario-ba26a',
    storageBucket: 'scenario-ba26a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRJZjAxkR61jZjwTutBPx2H73jqUZQC5w',
    appId: '1:602717699795:ios:368d1dd99f856220db9e26',
    messagingSenderId: '602717699795',
    projectId: 'scenario-ba26a',
    storageBucket: 'scenario-ba26a.firebasestorage.app',
    iosBundleId: 'com.scenario.scenario',
  );
}
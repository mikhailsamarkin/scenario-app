// Firebase options для prod-окружения (scenario-prod-491c).
// Сгенерировано вручную из google-services.json / GoogleService-Info.plist (prod).
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class ProdFirebaseOptions {
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
          'ProdFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiUWYW-hVtZB5Fhrq0eg3acsj9RsCRh1g',
    appId: '1:268811118114:android:1e280a0d804959fb4b8c7b',
    messagingSenderId: '268811118114',
    projectId: 'scenario-prod-491c',
    storageBucket: 'scenario-prod-491c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPq_I3AqN50gx0hAzMIZ8L567Z9LDD8FM',
    appId: '1:268811118114:ios:ac89edeebea89d184b8c7b',
    messagingSenderId: '268811118114',
    projectId: 'scenario-prod-491c',
    storageBucket: 'scenario-prod-491c.firebasestorage.app',
    iosBundleId: 'com.scenario.scenario',
  );
}
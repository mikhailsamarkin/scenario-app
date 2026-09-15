import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_config.dart';
import 'data/firestore/aggregate_repository.dart';
import 'firestore_config.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('startup: binding ok');

  // Инициализация Firebase с options текущего окружения (dev/prod).
  await Firebase.initializeApp(
    options: AppConfig.firebaseOptions,
  );
  print('startup: firebase ok');

  // Отчёты о сбоях (US-E6-05, A-41): сбор включён для dev и prod.
  // Обёрнуто в try/catch: если нативный компонент Crashlytics недоступен
  // (например, в release без Gradle-плагина), не роняем старт приложения.
  var crashlyticsReady = false;
  try {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(true);
    crashlyticsReady = true;
  } catch (e) {
    debugPrint('startup: crashlytics unavailable: $e');
  }
  // Перехват Dart-ошибок в Crashlytics (US-E6-05): иначе сбои UI-потока
  // не попадают в отчёты.
  if (crashlyticsReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  print('startup: crashlytics ok');

  // Включение Firestore persistence для офлайн-чтения кэша (A-20).
  enableFirestorePersistence();
  print('startup: persistence ok');

  // Инициализация Supabase (медиа) для текущего окружения.
  await initSupabase();
  print('startup: supabase ok');

  runApp(ScenarioApp(
    repository: FirestoreAggregateRepository(FirebaseFirestore.instance),
  ));
  print('startup: runApp scheduled');
}
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

  // Инициализация Firebase с options текущего окружения (dev/prod).
  await Firebase.initializeApp(
    options: AppConfig.firebaseOptions,
  );

  // Отчёты о сбоях (US-E6-05, A-41): сбор включён для dev и prod.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(true);

  // Включение Firestore persistence для офлайн-чтения кэша (A-20).
  enableFirestorePersistence();

  // Инициализация Supabase (медиа) для текущего окружения.
  await initSupabase();

  runApp(ScenarioApp(
    repository: FirestoreAggregateRepository(FirebaseFirestore.instance),
  ));
}
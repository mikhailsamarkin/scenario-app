// Конфигурация Cloud Firestore (A-20): включение persistence для
// офлайн-чтения кэшированных документов (US-E2-05, NFR-SR-3).
//
// Вызывается один раз при старте приложения (после Firebase.initializeApp)
// и до первого чтения документов.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Включает Firestore persistence (A-20).
///
/// Кэширует прочитанные документы на диске, чтобы при отсутствии сети
/// витрина/сценарий/игра открывались из локального кэша без блокирующей
/// ошибки (AC-01, UC-07).
void enableFirestorePersistence() {
  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
}
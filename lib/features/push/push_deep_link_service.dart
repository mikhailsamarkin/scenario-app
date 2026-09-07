// Deep link из push на экран сценария (SP-E3-04).
//
// Читает `scenarioId` из payload FCM (A-13) и навигирует на экран сценария.
// Холодный старт — через getInitialMessage (AC-02); фоновый тап — через
// onMessageOpenedApp (AC-01). Зависит от абстракции [PushDeepLinkSource]
// для тестируемости.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Ключ scenarioId в payload FCM (A-13).
const String kScenarioIdKey = 'scenarioId';

/// Источник deep link из push (абстракция для тестируемости).
abstract interface class PushDeepLinkSource {
  /// Сценарий из уведомления, открывшего приложение из terminated-состояния.
  Future<String?> getInitialScenarioId();

  /// Поток scenarioId при тапе по уведомлению из фонового состояния.
  Stream<String?> onScenarioOpened();
}

/// Реализация поверх FirebaseMessaging.
class FirebaseMessagingDeepLinkSource implements PushDeepLinkSource {
  FirebaseMessagingDeepLinkSource(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getInitialScenarioId() async {
    final message = await _messaging.getInitialMessage();
    return _scenarioId(message);
  }

  @override
  Stream<String?> onScenarioOpened() {
    return FirebaseMessaging.onMessageOpenedApp.map(_scenarioId);
  }

  String? _scenarioId(RemoteMessage? message) {
    if (message == null) return null;
    final value = message.data[kScenarioIdKey];
    return value is String && value.isNotEmpty ? value : null;
  }
}

/// Сервис обработки deep link из push.
class PushDeepLinkService {
  PushDeepLinkService(this._source);

  final PushDeepLinkSource _source;

  /// scenarioId из уведомления, открывшего приложение (холодный старт).
  Future<String?> getInitialScenarioId() => _source.getInitialScenarioId();

  /// Поток scenarioId при тапе по уведомлению из фона.
  Stream<String?> onScenarioOpened() => _source.onScenarioOpened();
}
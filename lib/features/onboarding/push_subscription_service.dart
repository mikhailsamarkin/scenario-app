// Подписка на push-уведомления (SP-E3-02).
//
// Запрашивает разрешение на уведомления и подписывает на FCM topic
// `new_scenarios` (A-8a, SR-PUSH-1). Без разрешения подписка не выполняется
// (AC-02). Зависит от абстрактного [PushMessaging] для тестируемости.

import 'package:firebase_messaging/firebase_messaging.dart';

/// Topic новых сценариев (SR-PUSH-1).
const String kNewScenariosTopic = 'new_scenarios';

/// Абстракция над FirebaseMessaging (для тестируемости).
abstract interface class PushMessaging {
  Future<NotificationSettings> requestPermission();
  Future<void> subscribeToTopic(String topic);
}

/// Реализация поверх FirebaseMessaging.
class FirebaseMessagingAdapter implements PushMessaging {
  FirebaseMessagingAdapter(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<NotificationSettings> requestPermission() =>
      _messaging.requestPermission();

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);
}

/// Сервис подписки на уведомления о новых сценариях.
class PushSubscriptionService {
  PushSubscriptionService(this._messaging);

  final PushMessaging _messaging;

  /// Запрашивает разрешение и при согласии подписывает на topic.
  ///
  /// Возвращает true, если подписка выполнена; false — если разрешение
  /// не выдано (подписка не выполняется, AC-02).
  Future<bool> subscribeToNewScenarios() async {
    final settings = await _messaging.requestPermission();
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) {
      return false;
    }
    await _messaging.subscribeToTopic(kNewScenariosTopic);
    return true;
  }
}
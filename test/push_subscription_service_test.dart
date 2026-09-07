// Unit-тесты сервиса подписки на push (SP-E3-02).
//
// Покрывают AC-01 (при разрешении подписка на topic new_scenarios) и
// AC-02 (без разрешения подписка не выполняется). PushMessaging — фейк.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/features/onboarding/push_subscription_service.dart';

/// Фейк над PushMessaging: настраиваемый статус разрешения.
class _FakePushMessaging implements PushMessaging {
  _FakePushMessaging({required this.status});

  AuthorizationStatus status;
  String? subscribedTopic;

  @override
  Future<NotificationSettings> requestPermission() async {
    return NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.enabled,
      authorizationStatus: status,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.whenAuthenticated,
      timeSensitive: AppleNotificationSetting.enabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.enabled,
    );
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    subscribedTopic = topic;
  }
}

void main() {
  test('AC-01: при авторизации подписывается на topic new_scenarios', () async {
    final faker = _FakePushMessaging(status: AuthorizationStatus.authorized);
    final service = PushSubscriptionService(faker);

    final ok = await service.subscribeToNewScenarios();

    expect(ok, isTrue);
    expect(faker.subscribedTopic, equals('new_scenarios'));
    expect(kNewScenariosTopic, equals('new_scenarios'));
  });

  test('AC-02: при отказе подписка не выполняется', () async {
    final faker = _FakePushMessaging(status: AuthorizationStatus.denied);
    final service = PushSubscriptionService(faker);

    final ok = await service.subscribeToNewScenarios();

    expect(ok, isFalse);
    expect(faker.subscribedTopic, isNull);
  });
}
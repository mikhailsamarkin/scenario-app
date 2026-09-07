// Unit-тесты аналитики воронки шаринга (SP-E5-04).
//
// Покрывают AC-01 (share_attempt с scenario_id) и AC-02 (share_success при
// success, share_dismissed при отмене). AnalyticsService — фейк.

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scenario/analytics/analytics_events.dart';
import 'package:scenario/analytics/analytics_service.dart';
import 'package:scenario/features/share/share_analytics_service.dart';

/// Фейк над AnalyticsLogger.
class _FakeLogger implements AnalyticsLogger {
  final List<(String, Map<String, Object>?)> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

void main() {
  test('AC-01: share_attempt с scenario_id при тапе', () async {
    final logger = _FakeLogger();
    final service = ShareAnalyticsService(AnalyticsService(logger));

    await service.logShareAttempt('s1');

    expect(logger.events[0].$1, equals(kEventShareAttempt));
    expect(logger.events[0].$2, equals({kParamScenarioId: 's1'}));
  });

  test('AC-02: share_success при status == success', () async {
    final logger = _FakeLogger();
    final service = ShareAnalyticsService(AnalyticsService(logger));

    await service.logShareResult('s1', const ShareResult('', ShareResultStatus.success));

    expect(logger.events[0].$1, equals(kEventShareSuccess));
  });

  test('AC-02/TC-03: share_dismissed при отмене, без ложного success', () async {
    final logger = _FakeLogger();
    final service = ShareAnalyticsService(AnalyticsService(logger));

    await service.logShareResult('s1', const ShareResult('', ShareResultStatus.dismissed));

    expect(logger.events[0].$1, equals(kEventShareDismissed));
    expect(logger.events[0].$1, isNot(equals(kEventShareSuccess)));
  });
}
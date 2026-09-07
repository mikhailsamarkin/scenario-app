// Unit-тесты сервиса аналитики (SP-E6-01).
//
// Покрывают AC-01 (имена событий из реестра) и базовые события (AC-02).
// AnalyticsLogger — фейк.

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/analytics/analytics_events.dart';
import 'package:scenario/analytics/analytics_service.dart';

/// Фейк над AnalyticsLogger: запоминает события.
class _FakeLogger implements AnalyticsLogger {
  final List<(String, Map<String, Object>?)> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

void main() {
  test('AC-01: scenario_open с scenario_id из реестра', () async {
    final logger = _FakeLogger();
    final service = AnalyticsService(logger);

    await service.logScenarioOpen('s1');

    expect(logger.events.length, equals(1));
    expect(logger.events[0].$1, equals(kEventScenarioOpen));
    expect(logger.events[0].$1, equals('scenario_open'));
    expect(logger.events[0].$2, equals({kParamScenarioId: 's1'}));
  });

  test('AC-01: game_open с game_id из реестра', () async {
    final logger = _FakeLogger();
    final service = AnalyticsService(logger);

    await service.logGameOpen('g1');

    expect(logger.events[0].$1, equals(kEventGameOpen));
    expect(logger.events[0].$2, equals({kParamGameId: 'g1'}));
  });

  test('AC-01: share_attempt и share_success (US-E5-04)', () async {
    final logger = _FakeLogger();
    final service = AnalyticsService(logger);

    await service.logShareAttempt('s1');
    await service.logShareSuccess('s1');

    expect(logger.events[0].$1, equals(kEventShareAttempt));
    expect(logger.events[1].$1, equals(kEventShareSuccess));
  });
}
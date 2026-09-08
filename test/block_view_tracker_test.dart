// Unit-тесты трекера block_view (SP-E6-03).
//
// Покрывают AC-01 (порог ≥50% и ≥300 ms) и AC-02 (одно срабатывание на
// блок за сессию экрана). Время инжектируется для контроля debounce.

import 'dart:core';

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/analytics/analytics_events.dart';
import 'package:scenario/analytics/analytics_service.dart';
import 'package:scenario/analytics/block_view_tracker.dart';

/// Фейк над AnalyticsLogger: запоминает события.
class _FakeLogger implements AnalyticsLogger {
  final List<(String, Map<String, Object>?)> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

/// Управляемые часы для контроля времени.
class _FakeClock {
  _FakeClock(this._start);

  final DateTime _start;
  Duration _elapsed = Duration.zero;

  DateTime now() => _start.add(_elapsed);

  void advance(Duration d) {
    _elapsed += d;
  }
}

void main() {
  test('AC-01: block_view при ≥50% площади и ≥300 ms', () async {
    final logger = _FakeLogger();
    final clock = _FakeClock(DateTime.utc(2026, 9, 8));
    final tracker = BlockViewTracker(
      AnalyticsService(logger),
      now: clock.now,
    );

    tracker.onVisibilityChanged('b1', 0.6);
    clock.advance(Duration(milliseconds: 200));
    tracker.onVisibilityChanged('b1', 0.6);
    expect(logger.events.length, equals(0));

    clock.advance(Duration(milliseconds: 200));
    tracker.onVisibilityChanged('b1', 0.6);
    expect(logger.events.length, equals(1));
    expect(logger.events[0].$1, equals(kEventBlockView));
    expect(logger.events[0].$2, equals({kParamBlockId: 'b1'}));
  });

  test('AC-01: быстрый проскок <300 ms не срабатывает', () async {
    final logger = _FakeLogger();
    final clock = _FakeClock(DateTime.utc(2026, 9, 8));
    final tracker = BlockViewTracker(
      AnalyticsService(logger),
      now: clock.now,
    );

    tracker.onVisibilityChanged('b1', 0.6);
    clock.advance(Duration(milliseconds: 100));
    // Блок ушёл ниже порога до истечения 300 ms.
    tracker.onVisibilityChanged('b1', 0.1);
    clock.advance(Duration(milliseconds: 500));
    tracker.onVisibilityChanged('b1', 0.6);

    expect(logger.events.length, equals(0));
  });

  test('AC-02: одно срабатывание на блок за сессию экрана', () async {
    final logger = _FakeLogger();
    final clock = _FakeClock(DateTime.utc(2026, 9, 8));
    final tracker = BlockViewTracker(
      AnalyticsService(logger),
      now: clock.now,
    );

    tracker.onVisibilityChanged('b1', 0.6);
    clock.advance(Duration(milliseconds: 400));
    tracker.onVisibilityChanged('b1', 0.6);
    expect(logger.events.length, equals(1));

    // Скролл туда-обратно — повторного события нет.
    tracker.onVisibilityChanged('b1', 0.1);
    clock.advance(Duration(milliseconds: 400));
    tracker.onVisibilityChanged('b1', 0.6);
    expect(logger.events.length, equals(1));
  });

  test('AC-02: resetSession позволяет сработать снова (сессия = жизнь экрана)',
      () async {
    final logger = _FakeLogger();
    final clock = _FakeClock(DateTime.utc(2026, 9, 8));
    final tracker = BlockViewTracker(
      AnalyticsService(logger),
      now: clock.now,
    );

    tracker.onVisibilityChanged('b1', 0.6);
    clock.advance(Duration(milliseconds: 400));
    tracker.onVisibilityChanged('b1', 0.6);
    expect(logger.events.length, equals(1));

    // Уход с экрана сбрасывает сессию; при возврате блок может сработать.
    tracker.resetSession();
    tracker.onVisibilityChanged('b1', 0.6);
    clock.advance(Duration(milliseconds: 400));
    tracker.onVisibilityChanged('b1', 0.6);
    expect(logger.events.length, equals(2));
  });
}
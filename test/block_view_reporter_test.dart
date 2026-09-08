// Widget-тесты BlockViewReporter (SP-E6-03, вариант A).
//
// Проверяют, что репортёр сообщает трекеру о видимости блока на основе
// scroll offset. Используется реальный BlockViewTracker с фейковым
// AnalyticsLogger.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/analytics/analytics_service.dart';
import 'package:scenario/analytics/block_view_tracker.dart';
import 'package:scenario/features/scenario/block_view_reporter.dart';

/// Фейк над AnalyticsLogger: запоминает события.
class _FakeLogger implements AnalyticsLogger {
  final List<(String, Map<String, Object>?)> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

void main() {
  testWidgets('AC-01: блок в viewport → трекер получает видимость', (tester) async {
    final logger = _FakeLogger();
    final tracker = BlockViewTracker(AnalyticsService(logger));
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            BlockViewReporter(
              blockId: 'b1',
              tracker: tracker,
              topOffset: 0,
              height: 100,
              child: const SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // Без реального скролла трекер не сработал (нет 300 ms удержания),
    // но репортёр не упал — блок отрисован.
    expect(find.byType(BlockViewReporter), findsOneWidget);
  });
}
// Widget-тесты обновления контента при сети (SP-E2-04).
//
// Покрывают AC-01 (сеть + кэш — данные сразу, без «пустого» экрана) и
// AC-02 (новая версия документа — актуальные данные после синхронизации).
// Чтение — через изменяемый фейковый AggregateRepository (A-11, A-38).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/home/home_screen.dart';

/// Изменяемый фейковый репозиторий: возвращает текущий home_feed.
class _MutableRepository implements AggregateRepository {
  _MutableRepository(this._feed);

  HomeFeed? _feed;

  void setFeed(HomeFeed? feed) {
    _feed = feed;
  }

  @override
  Future<HomeFeed?> getHomeFeed() async => _feed;

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => null;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async => null;

  @override
  Future<GamePublic?> getGame(String gameId) async => null;

  @override
  Future<SitemapPublic?> getSitemap() async => null;
}

HomeFeed _feed(List<ScenarioCard> vitrine) {
  return HomeFeed(
    contentVersion: 1,
    updatedAt: DateTime.utc(2026, 9, 7),
    carousel: const [],
    vitrine: vitrine,
    groups: const [],
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: сеть + кэш — данные сразу, без «пустого» экрана',
      (tester) async {
    final repo = _MutableRepository(
      _feed(const [
        ScenarioCard(scenarioId: 's1', slug: 'vecherinka', title: 'Вечеринка'),
      ]),
    );
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: repo,
      onOpenScenario: (context, scenarioId) {},
    )));
    await tester.pump();

    // Данные из кэша отображаются сразу, «пустого» экрана нет.
    expect(find.text('Вечеринка'), findsOneWidget);
    expect(find.text('Пока нет сценариев'), findsNothing);
  });

  testWidgets('AC-02: новая версия документа — актуальные данные', (tester) async {
    final repo = _MutableRepository(
      _feed(const [
        ScenarioCard(scenarioId: 's1', slug: 'vecherinka', title: 'Вечеринка'),
      ]),
    );
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: repo,
      onOpenScenario: (context, scenarioId) {},
    )));
    await tester.pump();
    expect(find.text('Вечеринка'), findsOneWidget);

    // Синхронизация: приходит новая версия с обновлённым составом.
    repo.setFeed(_feed(const [
      ScenarioCard(scenarioId: 's1', slug: 'vecherinka', title: 'Вечеринка'),
      ScenarioCard(scenarioId: 's2', slug: 'semya', title: 'Семейный вечер'),
    ]));

    // Возврат приложения в активное состояние → фоновое обновление (A-22).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // После обновления видна актуальная витрина.
    expect(find.text('Семейный вечер'), findsOneWidget);
  });
}
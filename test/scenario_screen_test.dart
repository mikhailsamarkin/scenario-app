// Widget-тесты экрана сценария (SP-E2-02).
//
// Покрывают AC-01 (обоснование выше списка игр; порядок из данных) и
// AC-02 (переносы строк в whyTheseGames сохраняются). Чтение — через
// фейковый AggregateRepository (A-11, A-38).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/scenario/scenario_screen.dart';

/// Фейковый репозиторий, возвращающий заданный сценарий.
class _FakeRepository implements AggregateRepository {
  _FakeRepository(this._scenario);

  final ScenarioPublic _scenario;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async => _scenario;

  @override
  Future<HomeFeed?> getHomeFeed() async => null;

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => null;

  @override
  Future<GamePublic?> getGame(String gameId) async => null;

  @override
  Future<SitemapPublic?> getSitemap() async => null;
}

ScenarioPublic _buildScenario() {
  return ScenarioPublic(
    id: 's1',
    slug: 'vecherinka',
    title: 'Вечеринка',
    subtitle: 'Для компании друзей',
    whyTheseGames: 'Первая строка\nВторая строка',
    seoTitle: 'Вечеринка',
    games: const [
      ScenarioGameRef(
        gameId: 'g1',
        slug: 'dixit',
        title: 'Dixit',
        shortDescription: 'Ассоциации',
      ),
      ScenarioGameRef(
        gameId: 'g2',
        slug: 'codenames',
        title: 'Кодовые имена',
        shortDescription: 'Шпионы',
      ),
    ],
    contentVersion: 1,
    updatedAt: DateTime.utc(2026, 9, 7),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: обоснование выше списка игр, порядок из данных',
      (tester) async {
    var openedGameId = '';
    var openedScenarioId = '';

    await tester.pumpWidget(_wrap(ScenarioScreen(
      scenarioId: 's1',
      repository: _FakeRepository(_buildScenario()),
      onOpenGame: (context, gameId, scenarioId) {
        openedGameId = gameId;
        openedScenarioId = scenarioId;
      },
    )));
    await tester.pump();

    // Заголовок и обоснование присутствуют.
    expect(find.text('Вечеринка'), findsOneWidget);
    expect(find.text('Почему эти игры подходят'), findsOneWidget);

    // Обе игры в списке, в порядке из данных.
    expect(find.text('Dixit'), findsOneWidget);
    expect(find.text('Кодовые имена'), findsOneWidget);

    // Тап по игре открывает экран игры с gameId и scenarioId (US-E2-03).
    await tester.tap(find.text('Dixit'));
    await tester.pump();
    expect(openedGameId, equals('g1'));
    expect(openedScenarioId, equals('s1'));
  });

  testWidgets('AC-02: переносы строк в whyTheseGames сохраняются',
      (tester) async {
    await tester.pumpWidget(_wrap(ScenarioScreen(
      scenarioId: 's1',
      repository: _FakeRepository(_buildScenario()),
      onOpenGame: (context, gameId, scenarioId) {},
    )));
    await tester.pump();

    // Текст с \n отображается целиком (переносы сохраняются визуально).
    expect(find.text('Первая строка\nВторая строка'), findsOneWidget);
  });
}
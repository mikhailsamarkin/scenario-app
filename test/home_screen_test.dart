// Widget-тесты главного экрана (SP-E2-01).
//
// Покрывают AC-01 (витрина в порядке и составе с сервера) и AC-02
// (название и опциональный подзаголовок из данных). Чтение — через
// фейковый AggregateRepository (A-11, A-38).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/home/home_screen.dart';

/// Фейковый репозиторий, возвращающий заданный home_feed.
class _FakeRepository implements AggregateRepository {
  _FakeRepository(this._feed);

  final HomeFeed? _feed;

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

HomeFeed _buildFeed() {
  return HomeFeed(
    contentVersion: 1,
    updatedAt: DateTime.utc(2026, 9, 7),
    carousel: const [],
    vitrine: const [
      ScenarioCard(
        scenarioId: 's1',
        slug: 'vecherinka',
        title: 'Вечеринка',
        subtitle: 'Для компании друзей',
      ),
      ScenarioCard(
        scenarioId: 's2',
        slug: 'semya',
        title: 'Семейный вечер',
      ),
    ],
    groups: const [],
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: витрина в порядке и составе с сервера', (tester) async {
    var openedScenarioId = '';

    await tester.pumpWidget(_wrap(HomeScreen(
      repository: _FakeRepository(_buildFeed()),
      onOpenScenario: (context, scenarioId) {
        openedScenarioId = scenarioId;
      },
    )));
    await tester.pump();

    // Обе карточки в порядке из данных.
    expect(find.text('Вечеринка'), findsOneWidget);
    expect(find.text('Семейный вечер'), findsOneWidget);

    // Тап по карточке открывает сценарий (US-E2-02).
    await tester.tap(find.text('Вечеринка'));
    await tester.pump();
    expect(openedScenarioId, equals('s1'));
  });

  testWidgets('AC-02: название и опциональный подзаголовок из данных',
      (tester) async {
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: _FakeRepository(_buildFeed()),
      onOpenScenario: (context, scenarioId) {},
    )));
    await tester.pump();

    // Название и подзаголовок там, где задан.
    expect(find.text('Вечеринка'), findsOneWidget);
    expect(find.text('Для компании друзей'), findsOneWidget);
    // У карточки без подзаголовка — только название.
    expect(find.text('Семейный вечер'), findsOneWidget);
  });

  testWidgets('пустая витрина — заглушка', (tester) async {
    final empty = HomeFeed(
      contentVersion: 1,
      updatedAt: DateTime.utc(2026, 9, 7),
      carousel: const [],
      vitrine: const [],
      groups: const [],
    );
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: _FakeRepository(empty),
      onOpenScenario: (context, scenarioId) {},
    )));
    await tester.pump();

    expect(find.text('Пока нет сценариев'), findsOneWidget);
  });

  testWidgets('AC-02: офлайн без кэша — состояние «нет сети»', (tester) async {
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: _FakeRepository(null),
      onOpenScenario: (context, scenarioId) {},
      isOffline: true,
    )));
    await tester.pump();

    expect(find.text('Нет сети. Проверьте подключение.'), findsOneWidget);
  });

  testWidgets('AC-01: офлайн с кэшем — данные рендерятся без ошибки',
      (tester) async {
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: _FakeRepository(_buildFeed()),
      onOpenScenario: (context, scenarioId) {},
      isOffline: true,
    )));
    await tester.pump();

    // Данные из кэша отображаются, ошибки нет.
    expect(find.text('Вечеринка'), findsOneWidget);
    expect(find.text('Нет сети. Проверьте подключение.'), findsNothing);
  });

  testWidgets('US-E7-01: группы смысла отображаются и открываются',
      (tester) async {
    var openedGroupId = '';
    final feed = HomeFeed(
      contentVersion: 1,
      updatedAt: DateTime.utc(2026, 9, 7),
      carousel: const [],
      vitrine: const [],
      groups: const [
        GroupRef(semanticGroupId: 'vdvoem', slug: 'vdvoem', title: 'Вдвоём'),
        GroupRef(semanticGroupId: 's-detmi', slug: 's-detmi', title: 'С детьми'),
      ],
    );
    await tester.pumpWidget(_wrap(HomeScreen(
      repository: _FakeRepository(feed),
      onOpenScenario: (context, scenarioId) {},
      onOpenGroup: (context, groupId) {
        openedGroupId = groupId;
      },
    )));
    await tester.pump();

    // Группы из данных видны.
    expect(find.text('Вдвоём'), findsOneWidget);
    expect(find.text('С детьми'), findsOneWidget);

    // Тап по группе открывает её (AC-02).
    await tester.tap(find.text('Вдвоём'));
    await tester.pump();
    expect(openedGroupId, equals('vdvoem'));
  });
}
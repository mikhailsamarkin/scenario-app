// Widget-тесты экрана группы смысла (SP-E7-01).
//
// Покрывают AC-02 (тап по группе → список сценариев из контентной
// конфигурации). Чтение — через фейковый AggregateRepository (A-11, A-38).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/group/group_screen.dart';

/// Фейковый репозиторий, возвращающий заданную группу.
class _FakeRepository implements AggregateRepository {
  _FakeRepository(this._group);

  final SemanticGroupPublic? _group;

  @override
  Future<HomeFeed?> getHomeFeed() async => null;

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => _group;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async => null;

  @override
  Future<GamePublic?> getGame(String gameId) async => null;

  @override
  Future<SitemapPublic?> getSitemap() async => null;
}

SemanticGroupPublic _buildGroup() {
  return SemanticGroupPublic(
    id: 'vdvoem',
    title: 'Вдвоём',
    slug: 'vdvoem',
    listOrder: 1,
    isPastArchive: false,
    scenarios: const [
      ScenarioCard(
        scenarioId: 's1',
        slug: 'semya',
        title: 'Семейный вечер',
      ),
      ScenarioCard(
        scenarioId: 's2',
        slug: 'vecherinka',
        title: 'Вечеринка',
      ),
    ],
    contentVersion: 1,
    updatedAt: DateTime.utc(2026, 9, 7),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-02: экран группы показывает сценарии из конфигурации',
      (tester) async {
    var openedScenarioId = '';

    await tester.pumpWidget(_wrap(GroupScreen(
      groupId: 'vdvoem',
      repository: _FakeRepository(_buildGroup()),
      onOpenScenario: (context, scenarioId) {
        openedScenarioId = scenarioId;
      },
    )));
    await tester.pump();

    // Заголовок группы и сценарии из данных.
    expect(find.text('Вдвоём'), findsWidgets);
    expect(find.text('Семейный вечер'), findsOneWidget);
    expect(find.text('Вечеринка'), findsOneWidget);

    // Тап по сценарию открывает его (US-E2-02).
    await tester.tap(find.text('Семейный вечер'));
    await tester.pump();
    expect(openedScenarioId, equals('s1'));
  });

  testWidgets('пустая группа — заглушка', (tester) async {
    final empty = SemanticGroupPublic(
      id: 'vdvoem',
      title: 'Вдвоём',
      slug: 'vdvoem',
      isPastArchive: false,
      scenarios: const [],
      contentVersion: 1,
      updatedAt: DateTime.utc(2026, 9, 7),
    );
    await tester.pumpWidget(_wrap(GroupScreen(
      groupId: 'vdvoem',
      repository: _FakeRepository(empty),
      onOpenScenario: (context, scenarioId) {},
    )));
    await tester.pump();

    expect(find.text('Пока нет сценариев'), findsOneWidget);
  });

  testWidgets('AC-02: офлайн без кэша — состояние «нет сети»', (tester) async {
    await tester.pumpWidget(_wrap(GroupScreen(
      groupId: 'vdvoem',
      repository: _FakeRepository(null),
      onOpenScenario: (context, scenarioId) {},
      isOffline: true,
    )));
    await tester.pump();

    expect(find.text('Нет сети. Проверьте подключение.'), findsOneWidget);
  });
}
// Базовый smoke-тест: корневой виджет приложения строится без ошибок.
//
// Полноценные сценарии экранов покрыты в home/scenario/game/onboarding
// _screen_test.dart с фейковым репозиторием; здесь проверяется только, что
// ScenarioApp (точка входа + навигация) конструируется и рендерит онбординг
// при первом запуске (флаг «пройден» не установлен).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/app.dart';
import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';

/// Фейковый репозиторий с пустой витриной.
class _EmptyRepository implements AggregateRepository {
  @override
  Future<HomeFeed?> getHomeFeed() async => null;

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => null;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async => null;

  @override
  Future<GamePublic?> getGame(String gameId) async => null;

  @override
  Future<SitemapPublic?> getSitemap() async => null;
}

void main() {
  testWidgets('ScenarioApp строится и рендерит онбординг при первом запуске',
      (WidgetTester tester) async {
    await tester.pumpWidget(ScenarioApp(repository: _EmptyRepository()));
    await tester.pump();

    // При первом запуске (флаг не установлен) показывается онбординг.
    expect(find.text('Добро пожаловать'), findsOneWidget);
  });
}
// Базовые тесты корневого виджета и навигации (US-E2-07).
//
// Покрывают TC-01 (точка входа — витрина), TC-02/TC-03 (переходы
// Home → Scenario → Game). Онбординг при первом запуске (флаг не установлен)
// тоже проверяется. Репозиторий и источники — фейки.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/analytics/analytics_service.dart';
import 'package:scenario/app.dart';
import 'package:scenario/data/contract/enums.dart';
import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/onboarding/onboarding_prefs.dart';
import 'package:scenario/features/link/universal_link_service.dart';
import 'package:scenario/features/push/push_deep_link_service.dart';
import 'package:scenario/force_update/force_update_checker.dart';

/// Фейковый репозиторий с заданной витриной и сценарием.
class _FakeRepository implements AggregateRepository {
  HomeFeed? _feed;

  void setFeed(HomeFeed feed) => _feed = feed;

  @override
  Future<HomeFeed?> getHomeFeed() async => _feed;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async {
    if (scenarioId != 's1') return null;
    return ScenarioPublic(
      id: scenarioId,
      slug: 's1',
      title: 'Сценарий',
      whyTheseGames: 'Почему эти игры',
      seoTitle: 'Сценарий',
      games: const [
        ScenarioGameRef(gameId: 'g1', slug: 'g1', title: 'Игра', shortDescription: 'Описание'),
      ],
      contentVersion: 1,
      updatedAt: DateTime.utc(2026, 9, 7),
    );
  }

  @override
  Future<GamePublic?> getGame(String gameId) async {
    if (gameId != 'g1') return null;
    return GamePublic(
      id: gameId,
      slug: 'g1',
      title: 'Игра',
      seoTitle: 'Игра',
      seoDescription: 'Описание',
      playersHint: PlayersHint.players24,
      durationBucket: DurationBucket.short,
      ageHint: AgeHint.family,
      rulesComplexity: RulesComplexity.easy,
      carousel: const [],
      scenarios: const [],
      contentVersion: 1,
      updatedAt: DateTime.utc(2026, 9, 7),
    );
  }

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => null;

  @override
  Future<SitemapPublic?> getSitemap() async => null;
}

/// Источник флага «онбординг пройден» (настраиваемый).
class _OnboardingStatus implements OnboardingStatusSource {
  _OnboardingStatus(this.completed);

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;
}

/// Фейковый источник deep link (без уведомлений).
class _NoDeepLinkSource implements PushDeepLinkSource {
  @override
  Future<String?> getInitialScenarioId() async => null;

  @override
  Stream<String?> onScenarioOpened() => const Stream.empty();
}

/// Фейковый источник Universal Links (без ссылок).
class _NoLinkSource implements LinkSource {
  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> onLink() => const Stream.empty();
}

HomeFeed _feed() => HomeFeed(
      contentVersion: 1,
      updatedAt: DateTime.utc(2026, 9, 7),
      carousel: const [],
      vitrine: const [
        ScenarioCard(scenarioId: 's1', slug: 's1', title: 'Сценарий'),
      ],
      groups: const [],
    );

/// Фейковый логгер аналитики: запоминает события.
class _FakeAnalyticsLogger implements AnalyticsLogger {
  final List<(String, Map<String, Object>?)> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

/// Фейковый Remote Config: не форсирует обновление.
class _NoForceUpdateSource implements RemoteConfigSource {
  @override
  Future<RemoteConfigValues> fetch() async => RemoteConfigValues(0, 0);
}

ScenarioApp _app(AggregateRepository repo, {required bool onboarding}) {
  return ScenarioApp(
    repository: repo,
    deepLinkSource: _NoDeepLinkSource(),
    linkSource: _NoLinkSource(),
    onboardingStatusSource: _OnboardingStatus(onboarding),
    analyticsLogger: _FakeAnalyticsLogger(),
    remoteConfigSource: _NoForceUpdateSource(),
  );
}

void main() {
  testWidgets('AC-01: точка входа — витрина при пройденном онбординге',
      (WidgetTester tester) async {
    final repo = _FakeRepository();
    repo.setFeed(_feed());
    await tester.pumpWidget(_app(repo, onboarding: true));
    await tester.pumpAndSettle();

    // Витрина отображается (не онбординг).
    expect(find.text('Сценарий'), findsOneWidget);
    expect(find.text('Добро пожаловать'), findsNothing);
  });

  testWidgets('AC-02: переход Home → Scenario → Game', (tester) async {
    // Высокая поверхность: карточки по макету ниже первого экрана.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repo = _FakeRepository();
    repo.setFeed(_feed());
    await tester.pumpWidget(_app(repo, onboarding: true));
    await tester.pumpAndSettle();

    // Тап по сценарию → экран сценария (уникальный текст whyTheseGames,
    // капс-заголовок по макету SP-E9-01).
    await tester.tap(find.text('Сценарий'));
    await tester.pumpAndSettle();
    expect(find.text('ПОЧЕМУ ЭТИ ИГРЫ ПОДХОДЯТ'), findsOneWidget);

    // Тап по игре → экран игры.
    await tester.tap(find.text('Игра'));
    await tester.pumpAndSettle();
    expect(find.text('Назад'), findsOneWidget);
  });

  testWidgets('онбординг при первом запуске', (tester) async {
    final repo = _FakeRepository();
    await tester.pumpWidget(_app(repo, onboarding: false));
    await tester.pump();

    expect(find.text('Выбери ситуацию — получи игру'), findsOneWidget);
  });
}
// Unit-тесты сервиса Universal Links (SP-E5-02).
//
// Покрывают AC-01 (URL → slug → id → открытие сценария). LinkSource и
// репозиторий — фейки.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/link/universal_link_service.dart';

/// Фейк над LinkSource.
class _FakeLinkSource implements LinkSource {
  _FakeLinkSource({this.initialLink});

  Uri? initialLink;

  @override
  Future<Uri?> getInitialLink() async => initialLink;

  @override
  Stream<Uri> onLink() => const Stream.empty();
}

/// Фейковый репозиторий с sitemap.
class _FakeRepository implements AggregateRepository {
  @override
  Future<SitemapPublic?> getSitemap() async => SitemapPublic(
        scenarioEntries: const [
          SitemapEntry(slug: 'vecherinka', id: 'vecherinka'),
          SitemapEntry(slug: 'semya', id: 'semya'),
        ],
        gameEntries: const [],
        contentVersion: 1,
        updatedAt: DateTime.utc(2026, 9, 7),
      );

  @override
  Future<HomeFeed?> getHomeFeed() async => null;

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => null;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async => null;

  @override
  Future<GamePublic?> getGame(String gameId) async => null;
}

void main() {
  test('AC-01: parseScenarioSlug извлекает slug из URL', () {
    final service = UniversalLinkService(_FakeLinkSource(), _FakeRepository());
    final uri = Uri.parse('https://scenario-games.ru/scenario/vecherinka');
    expect(service.parseScenarioSlug(uri), equals('vecherinka'));
  });

  test('AC-01: не-сценарный URL → null', () {
    final service = UniversalLinkService(_FakeLinkSource(), _FakeRepository());
    expect(
      service.parseScenarioSlug(Uri.parse('https://scenario-games.ru/other/x')),
      isNull,
    );
  });

  test('AC-01: slug → scenarioId через sitemap', () async {
    final service = UniversalLinkService(_FakeLinkSource(), _FakeRepository());
    expect(await service.resolveScenarioId('vecherinka'), equals('vecherinka'));
    expect(await service.resolveScenarioId('nope'), isNull);
  });

  test('AC-01: initial link → scenarioId (холодный старт)', () async {
    final source = _FakeLinkSource(
      initialLink: Uri.parse('https://scenario-games.ru/scenario/semya'),
    );
    final service = UniversalLinkService(source, _FakeRepository());
    expect(await service.getInitialScenarioId(), equals('semya'));
  });
}
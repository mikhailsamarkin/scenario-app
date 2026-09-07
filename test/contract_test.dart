// Контрактные тесты моделей публичных агрегатов (SP-E0-01).
//
// Проверяют: (1) строгий парсинг JSON → модели (TC-03/TC-04: имена полей
// и enum соответствуют контракту), (2) round-trip toJson/fromJson,
// (3) game_detail через shortDescriptionForScenario (A-12).

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/content_contract.dart';
import 'package:scenario/data/contract/enums.dart';
import 'package:scenario/data/contract/models.dart';

void main() {
  test('enum storage keys соответствуют СТ §4.1', () {
    expect(PlayersHint.players24.storageKey, equals('players_2_4'));
    expect(PlayersHint.players5Plus.storageKey, equals('players_5_plus'));
    expect(DurationBucket.mainEvent.storageKey, equals('main_event'));
    expect(AgeHint.family.storageKey, equals('age_family'));
    expect(RulesComplexity.heavy.storageKey, equals('heavy'));
    expect(FrameType.mechanicCloseup.storageKey, equals('mechanic_closeup'));

    expect(PlayersHint.isValidKey('players_2_5'), isTrue);
    expect(PlayersHint.isValidKey('players_9'), isFalse);
    expect(DurationBucket.isValidKey('warmup'), isTrue);
    expect(DurationBucket.isValidKey('epic'), isFalse);
  });

  test('пути публичных агрегатов соответствуют контракту', () {
    expect(homeFeedPath(), equals('home_feed/main'));
    expect(semanticGroupPublicPath('g1'), equals('semantic_groups_public/g1'));
    expect(scenarioPublicPath('s1'), equals('scenario_public/s1'));
    expect(gamePublicPath('g1'), equals('game_public/g1'));
    expect(sitemapPublicPath(), equals('sitemap_public/main'));
    expect(kContentContractVersion, equals(2));
  });

  test('HomeFeed: строгий парсинг и round-trip', () {
    final json = {
      'contentVersion': 3,
      'updatedAt': '2026-09-03T08:00:00Z',
      'carousel': [
        {
          'imageRef': 'games/g1/teaser.jpg',
          'frameType': 'teaser',
          'caption': 'Кап',
          'alt': 'Альт',
        },
      ],
      'vitrine': [
        {
          'scenarioId': 's1',
          'slug': 'vecherinka',
          'title': 'Вечеринка',
          'subtitle': 'Тизер',
        },
      ],
      'groups': [
        {'semanticGroupId': 'g1', 'slug': 'semya', 'title': 'Семейные'},
      ],
    };

    final feed = HomeFeed.fromJson(json);
    expect(feed.contentVersion, equals(3));
    expect(feed.carousel.single.frameType, equals(FrameType.teaser));
    expect(feed.vitrine.single.slug, equals('vecherinka'));
    expect(feed.groups.single.semanticGroupId, equals('g1'));

    final round = HomeFeed.fromJson(feed.toJson());
    expect(round.toJson(), equals(feed.toJson()));
  });

  test('ScenarioPublic: игры с enum и shortDescription', () {
    final json = {
      'id': 's1',
      'slug': 'vecherinka',
      'title': 'Вечеринка',
      'whyTheseGames': 'Почему эти игры',
      'seoTitle': 'Вечеринка — подборка настольных игр',
      'games': [
        {
          'gameId': 'g1',
          'slug': 'munchkin',
          'title': 'Манчкин',
          'shortDescription': 'Коротко в контексте',
          'playersHint': 'players_2_6',
          'durationBucket': 'evening',
          'ageHint': 'age_adults',
          'rulesComplexity': 'normal',
        },
      ],
      'semanticGroupIds': ['g1'],
      'contentVersion': 2,
      'updatedAt': '2026-09-03T08:00:00Z',
    };

    final scenario = ScenarioPublic.fromJson(json);
    final game = scenario.games.single;
    expect(game.playersHint, equals(PlayersHint.players26));
    expect(game.durationBucket, equals(DurationBucket.evening));
    expect(game.ageHint, equals(AgeHint.adults));
    expect(game.rulesComplexity, equals(RulesComplexity.normal));
    expect(scenario.semanticGroupIds, equals(['g1']));

    final round = ScenarioPublic.fromJson(scenario.toJson());
    expect(round.toJson(), equals(scenario.toJson()));
  });

  test('GamePublic: game_detail через shortDescriptionForScenario (A-12)', () {
    final json = {
      'id': 'g1',
      'slug': 'munchkin',
      'title': 'Манчкин',
      'seoTitle': 'Манчкин — карточная игра про подземелья',
      'seoDescription': 'Юмористическая карточная игра про приключения в подземелье.',
      'playersHint': 'players_2_6',
      'durationBucket': 'evening',
      'ageHint': 'age_adults',
      'rulesComplexity': 'normal',
      'carousel': [
        {'imageRef': 'games/g1/box.jpg', 'frameType': 'box'},
      ],
      'scenarios': [
        {
          'scenarioId': 's1',
          'slug': 'vecherinka',
          'title': 'Вечеринка',
          'shortDescription': 'Описание в контексте s1',
        },
      ],
      'contentVersion': 1,
      'updatedAt': '2026-09-03T08:00:00Z',
    };

    final game = GamePublic.fromJson(json);
    expect(
      game.shortDescriptionForScenario('s1'),
      equals('Описание в контексте s1'),
    );
    expect(game.shortDescriptionForScenario('missing'), isNull);

    final round = GamePublic.fromJson(game.toJson());
    expect(round.toJson(), equals(game.toJson()));
  });

  test('SitemapPublic: списки slug + id для SSG', () {
    final json = {
      'scenarioEntries': [
        {'slug': 'vecherinka', 'id': 'vecherinka'},
        {'slug': 'semya', 'id': 'semya'},
      ],
      'gameEntries': [
        {'slug': 'munchkin', 'id': 'munchkin'},
      ],
      'contentVersion': 1,
      'updatedAt': '2026-09-03T08:00:00Z',
    };

    final sitemap = SitemapPublic.fromJson(json);
    expect(sitemap.scenarioEntries.length, equals(2));
    expect(sitemap.scenarioEntries[0].slug, equals('vecherinka'));
    expect(sitemap.scenarioEntries[0].id, equals('vecherinka'));
    expect(sitemap.gameEntries.length, equals(1));
    expect(sitemap.gameEntries[0].slug, equals('munchkin'));

    final round = SitemapPublic.fromJson(sitemap.toJson());
    expect(round.toJson(), equals(sitemap.toJson()));
  });

  test('неизвестный enum-ключ бросает ошибку (TC-04)', () {
    expect(
      () => PlayersHint.fromStorageKey('players_9'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => FrameType.fromStorageKey('unknown'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('ScenarioPublic: отсутствие обязательного seoTitle бросает ошибку (SP-E1-04)', () {
    final json = {
      'id': 's1',
      'slug': 'vecherinka',
      'title': 'Вечеринка',
      'whyTheseGames': 'Почему эти игры',
      'games': <Map<String, dynamic>>[],
      'contentVersion': 1,
      'updatedAt': '2026-09-03T08:00:00Z',
    };
    expect(() => ScenarioPublic.fromJson(json), throwsA(anything));
  });

  test('GamePublic: отсутствие обязательных seoTitle/seoDescription бросает ошибку (SP-E1-04)', () {
    final json = {
      'id': 'g1',
      'slug': 'munchkin',
      'title': 'Манчкин',
      'playersHint': 'players_2_6',
      'durationBucket': 'evening',
      'ageHint': 'age_adults',
      'rulesComplexity': 'normal',
      'carousel': <Map<String, dynamic>>[],
      'scenarios': <Map<String, dynamic>>[],
      'contentVersion': 1,
      'updatedAt': '2026-09-03T08:00:00Z',
    };
    expect(() => GamePublic.fromJson(json), throwsA(anything));
  });
}
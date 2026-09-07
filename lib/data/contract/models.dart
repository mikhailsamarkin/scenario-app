// Модели единого контракта данных (SP-E0-01): публичные агрегаты,
// которые читают МП (Flutter) и Next.js (SSG).
//
// Соответствует §4.2–§4.6 спеки и СТ §4/§5 (A-10, A-12, A-38).
// Все модели иммьютабельны; парсинг строгий (типы и enum проверяются),
// чтобы исключить недокументированные обязательные поля (TC-04).

import 'enums.dart';

/// Слайд карусели (CR-5). Иммьютабелен (все поля final).
class Slide {
  const Slide({
    required this.imageRef,
    required this.frameType,
    this.caption,
    this.alt,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      imageRef: json['imageRef'] as String,
      frameType: FrameType.fromStorageKey(json['frameType'] as String),
      caption: json['caption'] as String?,
      alt: json['alt'] as String?,
    );
  }

  /// Ссылка на объект в Supabase Storage (ED-14); публичный URL —
  /// по правилу `supabasePublicUrl(path)` (A-39).
  final String imageRef;

  /// Тип кадра: teaser|box|in_play|mechanic_closeup (CR-5).
  final FrameType frameType;

  final String? caption;
  final String? alt;

  Map<String, dynamic> toJson() => {
        'imageRef': imageRef,
        'frameType': frameType.storageKey,
        if (caption != null) 'caption': caption,
        if (alt != null) 'alt': alt,
      };
}

/// Карточка сценария на главном экране / в группе (§4.2).
/// Иммьютабельна (все поля final).
class ScenarioCard {
  const ScenarioCard({
    required this.scenarioId,
    required this.slug,
    required this.title,
    this.subtitle,
    this.imageRef,
    this.alt,
  });

  factory ScenarioCard.fromJson(Map<String, dynamic> json) {
    return ScenarioCard(
      scenarioId: json['scenarioId'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageRef: json['imageRef'] as String?,
      alt: json['alt'] as String?,
    );
  }

  final String scenarioId;
  final String slug;
  final String title;
  final String? subtitle;
  final String? imageRef;
  final String? alt;

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'slug': slug,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (imageRef != null) 'imageRef': imageRef,
        if (alt != null) 'alt': alt,
      };
}

/// Ссылка на группу смысла на главном экране (§4.2).
/// Иммьютабельна (все поля final).
class GroupRef {
  const GroupRef({
    required this.semanticGroupId,
    required this.slug,
    required this.title,
  });

  factory GroupRef.fromJson(Map<String, dynamic> json) {
    return GroupRef(
      semanticGroupId: json['semanticGroupId'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
    );
  }

  final String semanticGroupId;
  final String slug;
  final String title;

  Map<String, dynamic> toJson() => {
        'semanticGroupId': semanticGroupId,
        'slug': slug,
        'title': title,
      };
}

/// Публичный агрегат `home_feed/main` (§4.2). Агрегат главного экрана МП.
/// Иммьютабелен (все поля final).
class HomeFeed {
  const HomeFeed({
    required this.contentVersion,
    required this.updatedAt,
    required this.carousel,
    required this.vitrine,
    required this.groups,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    return HomeFeed(
      contentVersion: json['contentVersion'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      carousel: (json['carousel'] as List<dynamic>)
          .map((e) => Slide.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      vitrine: (json['vitrine'] as List<dynamic>)
          .map((e) => ScenarioCard.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      groups: (json['groups'] as List<dynamic>)
          .map((e) => GroupRef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int contentVersion;
  final DateTime updatedAt;
  final List<Slide> carousel;
  final List<ScenarioCard> vitrine;
  final List<GroupRef> groups;

  Map<String, dynamic> toJson() => {
        'contentVersion': contentVersion,
        'updatedAt': updatedAt.toIso8601String(),
        'carousel': carousel.map((e) => e.toJson()).toList(growable: false),
        'vitrine': vitrine.map((e) => e.toJson()).toList(growable: false),
        'groups': groups.map((e) => e.toJson()).toList(growable: false),
      };
}

/// Публичный агрегат группы смысла `semantic_groups_public/{id}` (§4.3).
/// Иммьютабелен (все поля final).
class SemanticGroupPublic {
  const SemanticGroupPublic({
    required this.id,
    required this.title,
    required this.slug,
    this.listOrder,
    required this.isPastArchive,
    required this.scenarios,
    required this.contentVersion,
    required this.updatedAt,
  });

  factory SemanticGroupPublic.fromJson(Map<String, dynamic> json) {
    return SemanticGroupPublic(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      listOrder: json['listOrder'] as int?,
      isPastArchive: json['isPastArchive'] as bool,
      scenarios: (json['scenarios'] as List<dynamic>)
          .map((e) => ScenarioCard.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      contentVersion: json['contentVersion'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String title;
  final String slug;
  final int? listOrder;
  final bool isPastArchive;
  final List<ScenarioCard> scenarios;
  final int contentVersion;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        if (listOrder != null) 'listOrder': listOrder,
        'isPastArchive': isPastArchive,
        'scenarios': scenarios.map((e) => e.toJson()).toList(growable: false),
        'contentVersion': contentVersion,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Игра в контексте сценария (`scenario_public.games[]`, §4.4).
/// `shortDescription` из связи scenario_games (CR-4) — описание игры
/// в контексте сценария. Иммьютабелен (все поля final).
class ScenarioGameRef {
  const ScenarioGameRef({
    required this.gameId,
    required this.slug,
    required this.title,
    required this.shortDescription,
    this.imageRef,
    this.alt,
    this.playersHint,
    this.durationBucket,
    this.ageHint,
    this.rulesComplexity,
  });

  factory ScenarioGameRef.fromJson(Map<String, dynamic> json) {
    return ScenarioGameRef(
      gameId: json['gameId'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String,
      imageRef: json['imageRef'] as String?,
      alt: json['alt'] as String?,
      playersHint: json['playersHint'] == null
          ? null
          : PlayersHint.fromStorageKey(json['playersHint'] as String),
      durationBucket: json['durationBucket'] == null
          ? null
          : DurationBucket.fromStorageKey(json['durationBucket'] as String),
      ageHint: json['ageHint'] == null
          ? null
          : AgeHint.fromStorageKey(json['ageHint'] as String),
      rulesComplexity: json['rulesComplexity'] == null
          ? null
          : RulesComplexity.fromStorageKey(
              json['rulesComplexity'] as String,
            ),
    );
  }

  final String gameId;
  final String slug;
  final String title;
  final String shortDescription;
  final String? imageRef;
  final String? alt;
  final PlayersHint? playersHint;
  final DurationBucket? durationBucket;
  final AgeHint? ageHint;
  final RulesComplexity? rulesComplexity;

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'slug': slug,
        'title': title,
        'shortDescription': shortDescription,
        if (imageRef != null) 'imageRef': imageRef,
        if (alt != null) 'alt': alt,
        if (playersHint != null) 'playersHint': playersHint!.storageKey,
        if (durationBucket != null)
          'durationBucket': durationBucket!.storageKey,
        if (ageHint != null) 'ageHint': ageHint!.storageKey,
        if (rulesComplexity != null)
          'rulesComplexity': rulesComplexity!.storageKey,
      };
}

/// Публичный агрегат сценария `scenario_public/{scenarioId}` (§4.4).
/// Иммьютабелен (все поля final).
class ScenarioPublic {
  const ScenarioPublic({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle,
    required this.whyTheseGames,
    required this.seoTitle,
    this.seoDescription,
    this.shareTitle,
    this.shareText,
    this.shareImageUrl,
    this.publishedAt,
    required this.games,
    this.semanticGroupIds = const [],
    required this.contentVersion,
    required this.updatedAt,
  });

  factory ScenarioPublic.fromJson(Map<String, dynamic> json) {
    return ScenarioPublic(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      whyTheseGames: json['whyTheseGames'] as String,
      seoTitle: json['seoTitle'] as String,
      seoDescription: json['seoDescription'] as String?,
      shareTitle: json['shareTitle'] as String?,
      shareText: json['shareText'] as String?,
      shareImageUrl: json['shareImageUrl'] as String?,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      games: (json['games'] as List<dynamic>)
          .map((e) => ScenarioGameRef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      semanticGroupIds: (json['semanticGroupIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(growable: false),
      contentVersion: json['contentVersion'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String? subtitle;
  final String whyTheseGames;
  final String seoTitle;
  final String? seoDescription;
  final String? shareTitle;
  final String? shareText;
  final String? shareImageUrl;
  final DateTime? publishedAt;
  final List<ScenarioGameRef> games;
  final List<String> semanticGroupIds;
  final int contentVersion;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'whyTheseGames': whyTheseGames,
        'seoTitle': seoTitle,
        if (seoDescription != null) 'seoDescription': seoDescription,
        if (shareTitle != null) 'shareTitle': shareTitle,
        if (shareText != null) 'shareText': shareText,
        if (shareImageUrl != null) 'shareImageUrl': shareImageUrl,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
        'games': games.map((e) => e.toJson()).toList(growable: false),
        'semanticGroupIds': semanticGroupIds,
        'contentVersion': contentVersion,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Сценарий, где участвует игра (`game_public.scenarios[]`, §4.5).
/// Несёт `shortDescription` в контексте сценария (A-12 game_detail).
/// Иммьютабелен (все поля final).
class GameScenarioRef {
  const GameScenarioRef({
    required this.scenarioId,
    required this.slug,
    required this.title,
    required this.shortDescription,
  });

  factory GameScenarioRef.fromJson(Map<String, dynamic> json) {
    return GameScenarioRef(
      scenarioId: json['scenarioId'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String,
    );
  }

  final String scenarioId;
  final String slug;
  final String title;
  final String shortDescription;

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'slug': slug,
        'title': title,
        'shortDescription': shortDescription,
      };
}

/// Публичный агрегат игры `game_public/{gameId}` (§4.5).
/// Иммьютабелен (все поля final).
class GamePublic {
  const GamePublic({
    required this.id,
    required this.slug,
    required this.title,
    required this.seoTitle,
    required this.seoDescription,
    required this.playersHint,
    required this.durationBucket,
    required this.ageHint,
    required this.rulesComplexity,
    required this.carousel,
    required this.scenarios,
    required this.contentVersion,
    required this.updatedAt,
  });

  factory GamePublic.fromJson(Map<String, dynamic> json) {
    return GamePublic(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      seoTitle: json['seoTitle'] as String,
      seoDescription: json['seoDescription'] as String,
      playersHint: PlayersHint.fromStorageKey(json['playersHint'] as String),
      durationBucket: DurationBucket.fromStorageKey(
        json['durationBucket'] as String,
      ),
      ageHint: AgeHint.fromStorageKey(json['ageHint'] as String),
      rulesComplexity: RulesComplexity.fromStorageKey(
        json['rulesComplexity'] as String,
      ),
      carousel: (json['carousel'] as List<dynamic>)
          .map((e) => Slide.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      scenarios: (json['scenarios'] as List<dynamic>)
          .map((e) => GameScenarioRef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      contentVersion: json['contentVersion'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String seoTitle;
  final String seoDescription;
  final PlayersHint playersHint;
  final DurationBucket durationBucket;
  final AgeHint ageHint;
  final RulesComplexity rulesComplexity;
  final List<Slide> carousel;
  final List<GameScenarioRef> scenarios;
  final int contentVersion;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'seoTitle': seoTitle,
        'seoDescription': seoDescription,
        'playersHint': playersHint.storageKey,
        'durationBucket': durationBucket.storageKey,
        'ageHint': ageHint.storageKey,
        'rulesComplexity': rulesComplexity.storageKey,
        'carousel': carousel.map((e) => e.toJson()).toList(growable: false),
        'scenarios': scenarios.map((e) => e.toJson()).toList(growable: false),
        'contentVersion': contentVersion,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// `shortDescription` для контекстного сценария (A-12 game_detail).
  /// Возвращает null, если сценарий не найден в списке.
  String? shortDescriptionForScenario(String scenarioId) {
    for (final s in scenarios) {
      if (s.scenarioId == scenarioId) return s.shortDescription;
    }
    return null;
  }
}

/// Публичный агрегат `sitemap_public/main` (§4.6) — список опубликованных
/// slug для SSG (A-10b, A-10d), без N+1 по коллекциям.
/// Иммьютабелен (все поля final).
class SitemapPublic {
  const SitemapPublic({
    required this.scenarioSlugs,
    required this.gameSlugs,
    required this.contentVersion,
    required this.updatedAt,
  });

  factory SitemapPublic.fromJson(Map<String, dynamic> json) {
    return SitemapPublic(
      scenarioSlugs: (json['scenarioSlugs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      gameSlugs: (json['gameSlugs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      contentVersion: json['contentVersion'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final List<String> scenarioSlugs;
  final List<String> gameSlugs;
  final int contentVersion;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'scenarioSlugs': scenarioSlugs,
        'gameSlugs': gameSlugs,
        'contentVersion': contentVersion,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
// Единый контракт данных (SP-E0-01): пути коллекций/документов Firestore
// и версия контракта.
//
// Источник правды (закрыт для клиентского read — A-38):
//   games, scenarios, semantic_groups, scenario_semantic_groups, scenario_games
// Публичные агрегаты (read-only для клиентов — A-10, A-12):
//   home_feed/main, semantic_groups_public/{id}, scenario_public/{scenarioId},
//   game_public/{gameId}, sitemap_public/main
//
// Имена фиксируются здесь как единая точка согласования для МП и SSG.

/// Версия контракта данных. Растёт при несовместимых изменениях схемы
/// (связка с A-44 contentVersion / content_schema_version).
const int kContentContractVersion = 1;

/// Пути коллекций-источников правды (закрыты для клиентского read).
abstract final class SourceCollections {
  static const String games = 'games';
  static const String scenarios = 'scenarios';
  static const String semanticGroups = 'semantic_groups';
  static const String scenarioSemanticGroups = 'scenario_semantic_groups';
  static const String scenarioGames = 'scenario_games';
}

/// Пути публичных агрегатов (read-only для клиентов).
abstract final class PublicCollections {
  static const String homeFeed = 'home_feed';
  static const String semanticGroupsPublic = 'semantic_groups_public';
  static const String scenarioPublic = 'scenario_public';
  static const String gamePublic = 'game_public';
  static const String sitemapPublic = 'sitemap_public';
}

/// Имена документов-синглтонов в публичных коллекциях.
abstract final class PublicDocuments {
  static const String homeFeedMain = 'main';
  static const String sitemapMain = 'main';
}

/// Полный путь к документу `home_feed/main`.
String homeFeedPath() => '${PublicCollections.homeFeed}/${PublicDocuments.homeFeedMain}';

/// Полный путь к документу `semantic_groups_public/{id}`.
String semanticGroupPublicPath(String id) =>
    '${PublicCollections.semanticGroupsPublic}/$id';

/// Полный путь к документу `scenario_public/{scenarioId}`.
String scenarioPublicPath(String scenarioId) =>
    '${PublicCollections.scenarioPublic}/$scenarioId';

/// Полный путь к документу `game_public/{gameId}`.
String gamePublicPath(String gameId) => '${PublicCollections.gamePublic}/$gameId';

/// Полный путь к документу `sitemap_public/main`.
String sitemapPublicPath() =>
    '${PublicCollections.sitemapPublic}/${PublicDocuments.sitemapMain}';
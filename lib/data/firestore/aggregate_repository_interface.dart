// Интерфейс чтения публичных агрегатов (SP-E0-01).
//
// МП читает данные через Firestore SDK с прямым доступом к опубликованным
// коллекциям (A-11); черновики клиенту недоступны (A-38). Реализации:
//   - FirestoreAggregateRepository — чтение из Firestore (боевой);
//   - тестовые фейки — для контрактных тестов.

import '../contract/models.dart';

abstract interface class AggregateRepository {
  /// `home_feed/main` — агрегат главного экрана. null, если документ не найден.
  Future<HomeFeed?> getHomeFeed();

  /// `semantic_groups_public/{id}`. null, если документ не найден.
  Future<SemanticGroupPublic?> getSemanticGroup(String id);

  /// `scenario_public/{scenarioId}`. null, если документ не найден.
  Future<ScenarioPublic?> getScenario(String scenarioId);

  /// `game_public/{gameId}`. null, если документ не найден.
  Future<GamePublic?> getGame(String gameId);

  /// `sitemap_public/main`. null, если документ не найден.
  Future<SitemapPublic?> getSitemap();
}
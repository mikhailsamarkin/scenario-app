// Репозиторий чтения публичных агрегатов (SP-E0-01).
//
// Читает ТОЛЬКО публичные коллекции (read-only — A-10, A-12):
//   home_feed/main, semantic_groups_public/{id}, scenario_public/{scenarioId},
//   game_public/{gameId}, sitemap_public/main
//
// Источник правды (games, scenarios, ...) закрыт для клиентского read (A-38)
// — репозиторий никогда не обращается к нему напрямую.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../contract/content_contract.dart';
import '../contract/models.dart';

/// Читает `home_feed/main`.
Future<HomeFeed?> fetchHomeFeed(FirebaseFirestore db) async {
  return _readDoc<HomeFeed>(db, homeFeedPath(), HomeFeed.fromJson);
}

/// Читает `semantic_groups_public/{id}`.
Future<SemanticGroupPublic?> fetchSemanticGroupPublic(
  FirebaseFirestore db,
  String id,
) async {
  return _readDoc<SemanticGroupPublic>(
    db,
    semanticGroupPublicPath(id),
    SemanticGroupPublic.fromJson,
  );
}

/// Читает `scenario_public/{scenarioId}`.
Future<ScenarioPublic?> fetchScenarioPublic(
  FirebaseFirestore db,
  String scenarioId,
) async {
  return _readDoc<ScenarioPublic>(
    db,
    scenarioPublicPath(scenarioId),
    ScenarioPublic.fromJson,
  );
}

/// Читает `game_public/{gameId}`.
Future<GamePublic?> fetchGamePublic(FirebaseFirestore db, String gameId) async {
  return _readDoc<GamePublic>(
    db,
    gamePublicPath(gameId),
    GamePublic.fromJson,
  );
}

/// Читает `sitemap_public/main`.
Future<SitemapPublic?> fetchSitemapPublic(FirebaseFirestore db) async {
  return _readDoc<SitemapPublic>(db, sitemapPublicPath(), SitemapPublic.fromJson);
}

Future<T?> _readDoc<T>(
  FirebaseFirestore db,
  String path,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final snap = await db.doc(path).get();
  if (!snap.exists) return null;
  return fromJson(snap.data()!);
}
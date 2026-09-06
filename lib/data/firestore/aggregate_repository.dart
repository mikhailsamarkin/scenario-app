// Реализация чтения публичных агрегатов через Firestore SDK (A-11).
//
// Читает только публичные коллекции (SP-E0-01 §4.2–§4.6); черновики
// недоступны клиенту (A-38) — правила Firestore это гарантируют.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../contract/content_contract.dart';
import '../contract/models.dart';
import 'aggregate_repository_interface.dart';

/// Ошибка чтения агрегата (документ не найден / невалидные данные).
class AggregateReadException implements Exception {
  const AggregateReadException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'AggregateReadException: $message';
}

class FirestoreAggregateRepository implements AggregateRepository {
  FirestoreAggregateRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<HomeFeed?> getHomeFeed() async {
    final snap = await _firestore.doc(homeFeedPath()).get();
    if (!snap.exists) return null;
    return HomeFeed.fromJson(snap.data()!);
  }

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async {
    final snap = await _firestore.doc(semanticGroupPublicPath(id)).get();
    if (!snap.exists) return null;
    return SemanticGroupPublic.fromJson(snap.data()!);
  }

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async {
    final snap = await _firestore.doc(scenarioPublicPath(scenarioId)).get();
    if (!snap.exists) return null;
    return ScenarioPublic.fromJson(snap.data()!);
  }

  @override
  Future<GamePublic?> getGame(String gameId) async {
    final snap = await _firestore.doc(gamePublicPath(gameId)).get();
    if (!snap.exists) return null;
    return GamePublic.fromJson(snap.data()!);
  }

  @override
  Future<SitemapPublic?> getSitemap() async {
    final snap = await _firestore.doc(sitemapPublicPath()).get();
    if (!snap.exists) return null;
    return SitemapPublic.fromJson(snap.data()!);
  }
}
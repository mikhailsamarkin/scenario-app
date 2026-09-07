// Universal Links / App Links (SP-E5-02).
//
// Обрабатывает HTTPS-ссылку `https://scenario-games.ru/scenario/{slug}`
// (A-23): извлекает slug, находит scenarioId через sitemap (A-13) и
// возвращает его для навигации. Зависит от абстракций [LinkSource] и
// [SitemapResolver] для тестируемости.

import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../data/firestore/aggregate_repository_interface.dart';

/// Базовый URL сценария (A-23).
const String kScenarioBaseUrl = 'https://scenario-games.ru/scenario';

/// Источник входящих ссылок (абстракция для тестируемости).
abstract interface class LinkSource {
  /// Ссылка, открывшая приложение из terminated-состояния (холодный старт).
  Future<Uri?> getInitialLink();

  /// Поток ссылок при открытии из фона.
  Stream<Uri> onLink();
}

/// Реализация поверх app_links.
class AppLinksSource implements LinkSource {
  AppLinksSource(this._appLinks);

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> onLink() => _appLinks.uriLinkStream;
}

/// Сервис обработки Universal Links.
class UniversalLinkService {
  UniversalLinkService(this._source, this._repository);

  final LinkSource _source;
  final AggregateRepository _repository;

  /// Извлекает slug из URL сценария (A-23).
  String? parseScenarioSlug(Uri uri) {
    if (uri.host != 'scenario-games.ru') return null;
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments[0] != 'scenario') return null;
    final slug = segments[1];
    return slug.isEmpty ? null : slug;
  }

  /// Находит scenarioId по slug через sitemap (A-13).
  Future<String?> resolveScenarioId(String slug) async {
    final sitemap = await _repository.getSitemap();
    final entry = sitemap?.scenarioEntries
        .where((e) => e.slug == slug)
        .firstOrNull;
    return entry?.id;
  }

  /// Обрабатывает ссылку: slug → scenarioId.
  Future<String?> scenarioIdFromUri(Uri uri) async {
    final slug = parseScenarioSlug(uri);
    if (slug == null) return null;
    return resolveScenarioId(slug);
  }

  /// scenarioId из initial link (холодный старт).
  Future<String?> getInitialScenarioId() async {
    final uri = await _source.getInitialLink();
    if (uri == null) return null;
    return scenarioIdFromUri(uri);
  }

  /// Поток scenarioId при открытии ссылки из фона.
  Stream<String?> onScenarioOpened() {
    return _source.onLink().asyncMap(scenarioIdFromUri);
  }
}
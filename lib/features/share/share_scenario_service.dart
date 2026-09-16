// Шаринг сценария через системный share (SP-E5-01).
//
// Формирует текст и URL с UTM из полей контента (US-E1-04, A-23) и вызывает
// платформенный share sheet (A-18, FR-M-7). Зависит от абстракции
// [ShareLauncher] для тестируемости.

import 'package:share_plus/share_plus.dart';

import '../../data/contract/models.dart';
import 'share_analytics_service.dart';

/// Базовый URL сценария (A-23).
const String kScenarioBaseUrl = 'https://scenario-games.ru/scenario';

/// UTM-источник для шаринга (A-25).
const String kShareUtmSource = 'share';

/// Запускает системный share (абстракция для тестируемости).
abstract interface class ShareLauncher {
  Future<ShareResult> share({required String text, required String uri});
}

/// Реализация поверх share_plus.
class SharePlusLauncher implements ShareLauncher {
  SharePlusLauncher({Future<ShareResult> Function(ShareParams params)? share})
      : _share = share ?? SharePlus.instance.share;

  final Future<ShareResult> Function(ShareParams params) _share;

  @override
  Future<ShareResult> share({required String text, required String uri}) {
    // share_plus запрещает передавать text и uri одновременно
    // (ArgumentError: "uri and text cannot be provided at the same time"),
    // поэтому ссылку добавляем в текст одной строкой.
    final message = uri.isEmpty ? text : '$text\n$uri';
    return _share(ShareParams(text: message));
  }
}

/// Сервис шаринга сценария.
class ShareScenarioService {
  ShareScenarioService(this._launcher, {ShareAnalyticsService? analytics})
      : _analytics = analytics;

  final ShareLauncher _launcher;
  final ShareAnalyticsService? _analytics;

  /// Формирует URL сценария с UTM (A-23, A-25).
  String buildShareUrl(String slug) {
    return '$kScenarioBaseUrl/$slug?utm_source=$kShareUtmSource';
  }

  /// Формирует текст шаринга из полей контента (AC-02, US-E1-04).
  String buildShareText(ScenarioPublic scenario) {
    return scenario.shareText ?? scenario.title;
  }

  /// Делится сценарием: текст из данных + URL с UTM (AC-01).
  /// Логирует попытку и результат шаринга (US-E5-04).
  Future<void> shareScenario(ScenarioPublic scenario) async {
    final text = buildShareText(scenario);
    final url = buildShareUrl(scenario.slug);
    await _analytics?.logShareAttempt(scenario.id);
    final result = await _launcher.share(text: text, uri: url);
    await _analytics?.logShareResult(scenario.id, result);
  }
}
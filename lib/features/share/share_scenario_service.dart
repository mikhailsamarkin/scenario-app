// Шаринг сценария через системный share (SP-E5-01).
//
// Формирует текст и URL с UTM из полей контента (US-E1-04, A-23) и вызывает
// платформенный share sheet (A-18, FR-M-7). Зависит от абстракции
// [ShareLauncher] для тестируемости.

import 'package:share_plus/share_plus.dart';

import '../../data/contract/models.dart';

/// Базовый URL сценария (A-23).
const String kScenarioBaseUrl = 'https://scenario-games.ru/scenario';

/// UTM-источник для шаринга (A-25).
const String kShareUtmSource = 'share';

/// Запускает системный share (абстракция для тестируемости).
abstract interface class ShareLauncher {
  Future<void> share({required String text, required String uri});
}

/// Реализация поверх share_plus.
class SharePlusLauncher implements ShareLauncher {
  @override
  Future<void> share({required String text, required String uri}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, uri: Uri.parse(uri)),
    );
  }
}

/// Сервис шаринга сценария.
class ShareScenarioService {
  ShareScenarioService(this._launcher);

  final ShareLauncher _launcher;

  /// Формирует URL сценария с UTM (A-23, A-25).
  String buildShareUrl(String slug) {
    return '$kScenarioBaseUrl/$slug?utm_source=$kShareUtmSource';
  }

  /// Формирует текст шаринга из полей контента (AC-02, US-E1-04).
  String buildShareText(ScenarioPublic scenario) {
    return scenario.shareText ?? scenario.title;
  }

  /// Делится сценарием: текст из данных + URL с UTM (AC-01).
  Future<void> shareScenario(ScenarioPublic scenario) async {
    final text = buildShareText(scenario);
    final url = buildShareUrl(scenario.slug);
    await _launcher.share(text: text, uri: url);
  }
}
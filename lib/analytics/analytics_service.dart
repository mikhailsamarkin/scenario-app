// Сервис аналитики (SP-E6-01, A-34).
//
// Отправляет события через Firebase Analytics / GA4. Имена событий — из
// реестра analytics_events.dart (A-35, AC-01). Зависит от абстракции
// [AnalyticsLogger] для тестируемости.

import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_events.dart';

/// Логирует события аналитики (абстракция для тестируемости).
abstract interface class AnalyticsLogger {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
}

/// Реализация поверх Firebase Analytics.
class FirebaseAnalyticsLogger implements AnalyticsLogger {
  FirebaseAnalyticsLogger(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }
}

/// Сервис аналитики МП.
class AnalyticsService {
  AnalyticsService(this._logger);

  final AnalyticsLogger _logger;

  /// Открытие сценария (scenario_open) с источником (SP-E6-02, A-35).
  Future<void> logScenarioOpen(String scenarioId, ScenarioOpenSource source) {
    return _logger.logEvent(
      kEventScenarioOpen,
      parameters: {
        kParamScenarioId: scenarioId,
        kParamSource: source.storageKey,
      },
    );
  }

  /// Открытие игры (game_open).
  Future<void> logGameOpen(String gameId) {
    return _logger.logEvent(
      kEventGameOpen,
      parameters: {kParamGameId: gameId},
    );
  }

  /// Попытка шаринга (share_attempt, US-E5-04).
  Future<void> logShareAttempt(String scenarioId) {
    return _logger.logEvent(
      kEventShareAttempt,
      parameters: {kParamScenarioId: scenarioId},
    );
  }

  /// Успешный шаринг (share_success, US-E5-04).
  Future<void> logShareSuccess(String scenarioId) {
    return _logger.logEvent(
      kEventShareSuccess,
      parameters: {kParamScenarioId: scenarioId},
    );
  }

  /// Отмена шаринга (share_dismissed, US-E5-04).
  Future<void> logShareDismissed(String scenarioId) {
    return _logger.logEvent(
      kEventShareDismissed,
      parameters: {kParamScenarioId: scenarioId},
    );
  }

  /// Достижение блока (block_view, US-E6-03).
  Future<void> logBlockView(String blockId) {
    return _logger.logEvent(
      kEventBlockView,
      parameters: {kParamBlockId: blockId},
    );
  }
}
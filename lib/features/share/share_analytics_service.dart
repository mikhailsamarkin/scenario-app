// Аналитика воронки шаринга (SP-E5-04).
//
// Логирует попытку шаринга (share_attempt) и результат (share_success /
// share_dismissed) по реестру имён A-35 (US-E6-01). Успех фиксируется только
// при ShareResult.status == success (AC-02, TC-03).

import 'package:share_plus/share_plus.dart';

import '../../analytics/analytics_service.dart';

/// Сервис аналитики воронки шаринга.
class ShareAnalyticsService {
  ShareAnalyticsService(this._analytics);

  final AnalyticsService _analytics;

  /// Логирует попытку шаринга (AC-01).
  Future<void> logShareAttempt(String scenarioId) {
    return _analytics.logShareAttempt(scenarioId);
  }

  /// Логирует результат шаринга по статусу (AC-02).
  Future<void> logShareResult(String scenarioId, ShareResult result) {
    if (result.status == ShareResultStatus.success) {
      return _analytics.logShareSuccess(scenarioId);
    }
    // Отмена/недоступность — не ложный success (TC-03).
    return _analytics.logShareDismissed(scenarioId);
  }
}
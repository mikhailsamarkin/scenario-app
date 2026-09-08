// Трекер событий block_view (SP-E6-03, A-36).
//
// Следит за долей видимой площади именованных блоков и отправляет
// `block_view` один раз на блок за сессию экрана при выполнении порога
// A-36: ≥50% площади видимо ≥300 ms (debounce). Экран сообщает долю
// видимой площади через [onVisibilityChanged]; трекер сам решает, когда
// сработать. Время инжектируется для тестируемости.

import 'dart:core';

import 'analytics_service.dart';

/// Порог видимой площади блока (A-36).
const double kBlockViewVisibleFraction = 0.5;

/// Минимальное удержание блока в viewport (A-36).
const Duration kBlockViewHoldDuration = Duration(milliseconds: 300);

/// Трекер block_view (SP-E6-03).
class BlockViewTracker {
  BlockViewTracker(this._analytics, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AnalyticsService _analytics;
  final DateTime Function() _now;

  /// Когда блок стал видимым на ≥50% (null — ниже порога).
  final Map<String, DateTime?> _visibleSince = {};

  /// Блоки, для которых событие уже отправлено за сессию экрана (AC-02).
  final Set<String> _fired = {};

  /// Сообщает о доле видимой площади блока (0.0–1.0).
  ///
  /// Вызывается экраном при изменении скролла/видимости. Срабатывание —
  /// при удержании ≥50% видимости ≥300 ms; одно на блок за сессию (A-36).
  void onVisibilityChanged(String blockId, double visibleFraction) {
    if (visibleFraction >= kBlockViewVisibleFraction) {
      if (_fired.contains(blockId)) return;
      final now = _now();
      final since = _visibleSince[blockId];
      if (since == null) {
        _visibleSince[blockId] = now;
      } else if (now.difference(since) >= kBlockViewHoldDuration) {
        _fired.add(blockId);
        _visibleSince.remove(blockId);
        _analytics.logBlockView(blockId);
      }
    } else {
      _visibleSince.remove(blockId);
    }
  }

  /// Сбрасывает состояние за сессию экрана (AC-02).
  ///
  /// Вызывается при уходе с экрана, чтобы при возврате блок мог снова
  /// сработать (сессия = жизнь экрана, вариант А).
  void resetSession() {
    _fired.clear();
    _visibleSince.clear();
  }
}
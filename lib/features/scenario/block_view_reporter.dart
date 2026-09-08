// Отчёт о видимости блока для block_view (SP-E6-03, вариант A).
//
// Обёртка над именованным блоком: подписывается на скролл (Scrollable) и
// при изменении позиции вычисляет, виден ли блок в viewport, передавая
// трекеру долю видимой площади. Вариант A — упрощённый: блок считается
// видимым на 100%, когда его верхняя граница в пределах viewport, иначе 0.
//
// Точный расчёт ≥50% площади (A-36) — follow-up; трекер уже применяет
// порог и debounce 300 ms.

import 'package:flutter/material.dart';

import '../../analytics/block_view_tracker.dart';

/// Обёртка блока, сообщающая трекеру о видимости (вариант A).
class BlockViewReporter extends StatelessWidget {
  const BlockViewReporter({
    super.key,
    required this.blockId,
    required this.tracker,
    required this.topOffset,
    required this.height,
    required this.child,
  });

  /// Стабильный идентификатор блока (A-35).
  final String blockId;

  /// Трекер block_view (может быть null — аналитика не подключена).
  final BlockViewTracker? tracker;

  /// Смещение верхней границы блока от начала контента (px).
  final double topOffset;

  /// Высота блока (px).
  final double height;

  /// Содержимое блока.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null || tracker == null) {
      return child;
    }
    final offset = position.pixels;
    final viewport = position.viewportDimension;
    // Блок виден, если его верхняя граница в пределах viewport.
    final visible = offset <= topOffset && topOffset < offset + viewport;
    tracker!.onVisibilityChanged(blockId, visible ? 1.0 : 0.0);
    return child;
  }
}
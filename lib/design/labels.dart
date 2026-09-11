// Подписи на русском для контракта (SP-E9-01): переносятся из
// game_screen.dart и приводятся к формулировкам макетов
// (docs/figma/screens/*.md, ED-2).

import '../data/contract/enums.dart';

/// Подпись на русском для [DurationBucket] (у enum нет uiLabel).
String durationBucketLabel(DurationBucket value) {
  switch (value) {
    case DurationBucket.warmup:
      return 'Разминка';
    case DurationBucket.short:
      return 'Короткая партия';
    case DurationBucket.evening:
      return 'Партия на вечер';
    case DurationBucket.long:
      return 'Долгая партия';
    case DurationBucket.mainEvent:
      return 'На весь вечер';
  }
}

/// Подпись на русском для [RulesComplexity] (у enum нет uiLabel).
String rulesComplexityLabel(RulesComplexity value) {
  switch (value) {
    case RulesComplexity.easy:
      return 'Быстро объяснить';
    case RulesComplexity.normal:
      return 'Средняя сложность';
    case RulesComplexity.heavy:
      return 'Нужно вникнуть';
  }
}

/// Подпись состава игроков для чипсов («3–6 игр.», как в макете).
String playersChipLabel(PlayersHint value) => '${value.uiLabel} игр.';

/// Склонение существительного «игра» для счётчика: 1 игра / 2 игры / 5 игр.
String gamesPlural(int count) {
  if (count % 10 == 1 && count % 100 != 11) return 'игра';
  if ({2, 3, 4}.contains(count % 10) &&
      !(count % 100 >= 12 && count % 100 <= 14)) {
    return 'игры';
  }
  return 'игр';
}

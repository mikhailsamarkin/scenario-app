// Единый контракт данных (SP-E0-01): закрытые enum-типы публичных агрегатов.
//
// Значения соответствуют СТ §4.1 (CR-4.1) и §4.7 спеки. В Firestore хранится
// строковый ключ; подпись на русском — в UI (ED-2).
//
// Валидация при записи — Firestore Rules (allowlist); в коде Flutter —
// enum/sealed class с тем же набором (СТ §4.1).

/// Состав игроков (CR-4.1 п.1). Ключ → подпись в UI на русском.
enum PlayersHint {
  players1('players_1', '1'),
  players2('players_2', '2'),
  players24('players_2_4', '2–4'),
  players25('players_2_5', '2–5'),
  players26('players_2_6', '2–6'),
  players5Plus('players_5_plus', '5+');

  const PlayersHint(this.storageKey, this.uiLabel);

  /// Ключ хранения в Firestore.
  final String storageKey;

  /// Подпись в UI на русском.
  final String uiLabel;

  static PlayersHint fromStorageKey(String key) {
    for (final v in PlayersHint.values) {
      if (v.storageKey == key) return v;
    }
    throw ArgumentError.value(key, 'key', 'Unknown PlayersHint storage key');
  }

  static bool isValidKey(String key) =>
      PlayersHint.values.any((v) => v.storageKey == key);
}

/// Длительность партии (CR-4.1 п.2).
enum DurationBucket {
  warmup('warmup'),
  short('short'),
  evening('evening'),
  long('long'),
  mainEvent('main_event');

  const DurationBucket(this.storageKey);

  final String storageKey;

  static DurationBucket fromStorageKey(String key) {
    for (final v in DurationBucket.values) {
      if (v.storageKey == key) return v;
    }
    throw ArgumentError.value(
      key,
      'key',
      'Unknown DurationBucket storage key',
    );
  }

  static bool isValidKey(String key) =>
      DurationBucket.values.any((v) => v.storageKey == key);
}

/// Аудитория по возрасту (CR-4.1 п.3). Ключ → подпись в UI на русском.
enum AgeHint {
  kids('age_kids', 'Детские'),
  family('age_family', 'Семейные'),
  adults('age_adults', 'Взрослые');

  const AgeHint(this.storageKey, this.uiLabel);

  final String storageKey;
  final String uiLabel;

  static AgeHint fromStorageKey(String key) {
    for (final v in AgeHint.values) {
      if (v.storageKey == key) return v;
    }
    throw ArgumentError.value(key, 'key', 'Unknown AgeHint storage key');
  }

  static bool isValidKey(String key) =>
      AgeHint.values.any((v) => v.storageKey == key);
}

/// Сложность правил (CR-4.1 п.4).
enum RulesComplexity {
  easy('easy'),
  normal('normal'),
  heavy('heavy');

  const RulesComplexity(this.storageKey);

  final String storageKey;

  static RulesComplexity fromStorageKey(String key) {
    for (final v in RulesComplexity.values) {
      if (v.storageKey == key) return v;
    }
    throw ArgumentError.value(
      key,
      'key',
      'Unknown RulesComplexity storage key',
    );
  }

  static bool isValidKey(String key) =>
      RulesComplexity.values.any((v) => v.storageKey == key);
}

/// Тип кадра слайда карусели (CR-5). Минимум один слайд с frameType == teaser.
enum FrameType {
  teaser('teaser'),
  box('box'),
  inPlay('in_play'),
  mechanicCloseup('mechanic_closeup');

  const FrameType(this.storageKey);

  final String storageKey;

  static FrameType fromStorageKey(String key) {
    for (final v in FrameType.values) {
      if (v.storageKey == key) return v;
    }
    throw ArgumentError.value(key, 'key', 'Unknown FrameType storage key');
  }

  static bool isValidKey(String key) =>
      FrameType.values.any((v) => v.storageKey == key);
}
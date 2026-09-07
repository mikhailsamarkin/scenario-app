// Политика дискового кэша изображений (A-21a, NFR-SR-6).
//
// Реализует LRU-вытеснение с верхним пределом суммарного размера
// (для MVP — 100–150 МБ). Чистый Dart, не зависит от конкретного пакета
// кэша (ED-13/ADR-004–009): выбранный tech lead'ом пакет может использовать
// эту политику либо быть заменён ею как «эквивалент» (A-21). Контракт
// данных не затрагивается.

/// Верхний предел дискового кэша изображений по умолчанию, байт (A-21a).
///
/// Верхняя граница диапазона 100–150 МБ из A-21a/NFR-SR-6; значение
/// конфигурируемо (для тестов и dev можно задать низкий лимит).
const int kImageCacheDefaultMaxBytes = 150 * 1024 * 1024;

/// LRU-кэш с верхним пределом суммарного размера (A-21a, NFR-SR-6).
///
/// Хранит пары ключ → значение и размер каждой записи в байтах. При
/// добавлении, если суммарный размер превышает [maxBytes], вытесняются
/// наименее недавно использованные записи (LRU). Кэш не растёт бесконечно
/// (TC-03) и повторно отдаёт недавно использованные записи (TC-01).
class LruCache<K, V> {
  LruCache({required this.maxBytes}) : assert(maxBytes > 0);

  /// Верхний предел суммарного размера кэша в байтах (A-21a).
  final int maxBytes;

  final Map<K, _Entry<V>> _entries = <K, _Entry<V>>{};
  final List<K> _lruOrder = <K>[];

  int _totalBytes = 0;

  /// Текущий суммарный размер кэша в байтах.
  int get sizeBytes => _totalBytes;

  /// Число записей в кэше.
  int get length => _entries.length;

  /// Возвращает значение по [key] и помечает его как недавно использованное,
  /// либо null, если записи нет.
  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;
    _touch(key);
    return entry.value;
  }

  /// Добавляет или обновляет запись [key] со значением [value] и размером
  /// [sizeBytes]. Если размер одной записи превышает [maxBytes], она не
  /// кэшируется (нет смысла хранить запись больше лимита).
  void put(K key, V value, {required int sizeBytes}) {
    if (sizeBytes > maxBytes) {
      _remove(key);
      return;
    }
    final existing = _entries[key];
    if (existing != null) {
      _totalBytes -= existing.sizeBytes;
    }
    _entries[key] = _Entry<V>(value, sizeBytes);
    _totalBytes += sizeBytes;
    _touch(key);
    _evict();
  }

  /// Удаляет запись [key], если она есть.
  void remove(K key) => _remove(key);

  /// Очищает кэш.
  void clear() {
    _entries.clear();
    _lruOrder.clear();
    _totalBytes = 0;
  }

  void _touch(K key) {
    _lruOrder.remove(key);
    _lruOrder.add(key);
  }

  void _remove(K key) {
    final entry = _entries.remove(key);
    if (entry != null) {
      _totalBytes -= entry.sizeBytes;
    }
    _lruOrder.remove(key);
  }

  /// Вытесняет наименее недавно использованные записи, пока суммарный
  /// размер не станет ≤ [maxBytes] (LRU, A-21a).
  void _evict() {
    while (_totalBytes > maxBytes && _lruOrder.isNotEmpty) {
      _remove(_lruOrder.first);
    }
  }
}

class _Entry<V> {
  _Entry(this.value, this.sizeBytes);

  final V value;
  final int sizeBytes;
}
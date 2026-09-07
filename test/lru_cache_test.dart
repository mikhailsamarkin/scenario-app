// Unit-тесты политики LRU-кэша изображений (SP-E2-06).
//
// Покрывают TC-01 (повторное чтение из кэша) и TC-03 (лимит диска:
// LRU-вытеснение, кэш не растёт бесконечно) на уровне политики (A-21a,
// NFR-SR-6). Слой unit — без сети и диска; интеграцию с пакетом кэша и
// экраном карусели закрывают US-E2-03 и ED-13/ADR-004–009.

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/cache/lru_cache.dart';

void main() {
  group('LruCache', () {
    test('повторное чтение возвращает значение из кэша (TC-01)', () {
      final cache = LruCache<String, String>(maxBytes: 100);
      cache.put('a', 'A', sizeBytes: 10);

      expect(cache.get('a'), equals('A'));
      expect(cache.length, equals(1));
      expect(cache.sizeBytes, equals(10));
    });

    test('недавно использованная запись не вытесняется первой (TC-01)', () {
      final cache = LruCache<String, String>(maxBytes: 30);
      cache.put('a', 'A', sizeBytes: 10);
      cache.put('b', 'B', sizeBytes: 10);
      cache.put('c', 'C', sizeBytes: 10);

      // Обращение к 'a' делает её самой свежей.
      cache.get('a');

      // Добавление вытесняет самую старую ('b'), но не 'a'.
      cache.put('d', 'D', sizeBytes: 10);

      expect(cache.get('a'), equals('A'));
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), equals('C'));
      expect(cache.get('d'), equals('D'));
    });

    test('LRU-вытеснение при превышении лимита, кэш не растёт (TC-03)', () {
      final cache = LruCache<String, String>(maxBytes: 25);
      cache.put('a', 'A', sizeBytes: 10);
      cache.put('b', 'B', sizeBytes: 10);
      cache.put('c', 'C', sizeBytes: 10);

      // 30 > 25 → вытесняется самая старая 'a'.
      expect(cache.length, equals(2));
      expect(cache.sizeBytes, lessThanOrEqualTo(25));
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals('B'));
      expect(cache.get('c'), equals('C'));
    });

    test('запись больше лимита не кэшируется (TC-03)', () {
      final cache = LruCache<String, String>(maxBytes: 10);
      cache.put('big', 'B', sizeBytes: 20);

      expect(cache.length, equals(0));
      expect(cache.sizeBytes, equals(0));
      expect(cache.get('big'), isNull);
    });

    test('обновление записи корректирует суммарный размер', () {
      final cache = LruCache<String, String>(maxBytes: 100);
      cache.put('a', 'A', sizeBytes: 10);
      cache.put('a', 'A2', sizeBytes: 30);

      expect(cache.length, equals(1));
      expect(cache.sizeBytes, equals(30));
      expect(cache.get('a'), equals('A2'));
    });

    test('remove и clear сбрасывают состояние', () {
      final cache = LruCache<String, String>(maxBytes: 100);
      cache.put('a', 'A', sizeBytes: 10);
      cache.put('b', 'B', sizeBytes: 20);

      cache.remove('a');
      expect(cache.get('a'), isNull);
      expect(cache.sizeBytes, equals(20));

      cache.clear();
      expect(cache.length, equals(0));
      expect(cache.sizeBytes, equals(0));
      expect(cache.get('b'), isNull);
    });

    test('значение по умолчанию — верхняя граница 150 МБ (A-21a)', () {
      expect(kImageCacheDefaultMaxBytes, equals(150 * 1024 * 1024));
    });
  });
}
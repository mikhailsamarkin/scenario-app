// Unit-тесты проверки принудительного обновления (SP-E6-06).
//
// Покрывают AC-01 (min_supported_build выше текущей) и AC-02
// (несовместимая content_schema_version). RemoteConfigSource — фейк.

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/force_update/force_update_checker.dart';

/// Фейк над RemoteConfigSource: возвращает заданные значения.
class _FakeRemoteConfig implements RemoteConfigSource {
  _FakeRemoteConfig(this._values);

  final RemoteConfigValues _values;

  @override
  Future<RemoteConfigValues> fetch() async => _values;
}

void main() {
  test('AC-01: min_supported_build выше текущей сборки → обновление', () async {
    final checker = ForceUpdateChecker(
      _FakeRemoteConfig(RemoteConfigValues(5, 2)),
    );

    expect(await checker.isUpdateRequired(), isTrue);
  });

  test('AC-01: совместимая сборка → обновление не требуется', () async {
    final checker = ForceUpdateChecker(
      _FakeRemoteConfig(RemoteConfigValues(1, 2)),
    );

    expect(await checker.isUpdateRequired(), isFalse);
  });

  test('AC-02: content_schema_version выше поддерживаемой → обновление',
      () async {
    final checker = ForceUpdateChecker(
      _FakeRemoteConfig(RemoteConfigValues(1, 3)),
    );

    expect(await checker.isUpdateRequired(), isTrue);
  });

  test('AC-02: равная content_schema_version → обновление не требуется',
      () async {
    final checker = ForceUpdateChecker(
      _FakeRemoteConfig(RemoteConfigValues(1, 2)),
    );

    expect(await checker.isUpdateRequired(), isFalse);
  });
}
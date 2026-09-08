// Проверка принудительного обновления (SP-E6-06, A-45, ADR-013).
//
// Сравнивает параметры Remote Config (`min_supported_build`,
// `content_schema_version`) с локальными значениями сборки и схемы. При
// несовместимости приложение показывает блокирующий экран обновления.
// Источник Remote Config инжектируется для тестируемости.

import 'dart:core';

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Текущий номер сборки (из `version` в pubspec.yaml: `1.0.0+1`).
const int kCurrentBuildNumber = 1;

/// Версия схемы контента, поддерживаемая клиентом (A-44, ADR-013).
const int kSupportedContentSchemaVersion = 2;

/// Ключ параметра Remote Config: минимально поддерживаемая сборка (A-45).
const String kRemoteConfigMinBuild = 'min_supported_build';

/// Ключ параметра Remote Config: версия схемы контента (A-45, ADR-013).
const String kRemoteConfigSchemaVersion = 'content_schema_version';

/// Значения Remote Config, влияющие на принудительное обновление (A-45).
class RemoteConfigValues {
  RemoteConfigValues(this.minSupportedBuild, this.contentSchemaVersion);

  /// Минимально поддерживаемый номер сборки.
  final int minSupportedBuild;

  /// Версия схемы контента в данных.
  final int contentSchemaVersion;
}

/// Источник Remote Config (абстракция для тестируемости).
abstract interface class RemoteConfigSource {
  Future<RemoteConfigValues> fetch();
}

/// Реализация поверх Firebase Remote Config (US-E6-06, A-45).
class FirebaseRemoteConfigSource implements RemoteConfigSource {
  FirebaseRemoteConfigSource(this._config);

  final FirebaseRemoteConfig _config;

  @override
  Future<RemoteConfigValues> fetch() async {
    await _config.fetchAndActivate();
    return RemoteConfigValues(
      _config.getInt(kRemoteConfigMinBuild),
      _config.getInt(kRemoteConfigSchemaVersion),
    );
  }
}

/// Проверяет совместимость сборки и схемы контента (A-45).
class ForceUpdateChecker {
  ForceUpdateChecker(
    this._source, {
    this.currentBuildNumber = kCurrentBuildNumber,
    this.supportedContentSchemaVersion = kSupportedContentSchemaVersion,
  });

  final RemoteConfigSource _source;
  final int currentBuildNumber;
  final int supportedContentSchemaVersion;

  /// true, если требуется принудительное обновление (AC-01, AC-02).
  Future<bool> isUpdateRequired() async {
    final rc = await _source.fetch();
    if (rc.minSupportedBuild > currentBuildNumber) return true;
    if (rc.contentSchemaVersion > supportedContentSchemaVersion) return true;
    return false;
  }
}
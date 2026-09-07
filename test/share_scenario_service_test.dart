// Unit-тесты сервиса шаринга сценария (SP-E5-01).
//
// Покрывают AC-01 (URL с UTM и текст) и AC-02 (текст из полей контента).
// ShareLauncher — фейк.

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scenario/data/contract/models.dart';
import 'package:scenario/features/share/share_scenario_service.dart';

/// Фейк над ShareLauncher: запоминает переданные текст и URL.
class _FakeLauncher implements ShareLauncher {
  String? text;
  String? uri;

  @override
  Future<ShareResult> share({required String text, required String uri}) async {
    this.text = text;
    this.uri = uri;
    return const ShareResult('', ShareResultStatus.success);
  }
}

ScenarioPublic _scenario({String? shareText}) {
  return ScenarioPublic(
    id: 's1',
    slug: 'vecherinka',
    title: 'Вечеринка',
    whyTheseGames: 'Почему',
    seoTitle: 'Вечеринка',
    shareText: shareText,
    games: const [],
    contentVersion: 1,
    updatedAt: DateTime.utc(2026, 9, 7),
  );
}

void main() {
  test('AC-01: URL сценария с UTM', () {
    final service = ShareScenarioService(_FakeLauncher());
    expect(
      service.buildShareUrl('vecherinka'),
      equals('https://scenario-games.ru/scenario/vecherinka?utm_source=share'),
    );
  });

  test('AC-02: текст из shareText, не заглушка', () {
    final service = ShareScenarioService(_FakeLauncher());
    final scenario = _scenario(shareText: 'Подборка для компании');
    expect(service.buildShareText(scenario), equals('Подборка для компании'));
  });

  test('AC-02: fallback на title, если shareText нет', () {
    final service = ShareScenarioService(_FakeLauncher());
    final scenario = _scenario();
    expect(service.buildShareText(scenario), equals('Вечеринка'));
  });

  test('AC-01: share передаёт текст и URL', () async {
    final launcher = _FakeLauncher();
    final service = ShareScenarioService(launcher);
    final scenario = _scenario(shareText: 'Подборка');

    await service.shareScenario(scenario);

    expect(launcher.text, equals('Подборка'));
    expect(
      launcher.uri,
      equals('https://scenario-games.ru/scenario/vecherinka?utm_source=share'),
    );
  });
}
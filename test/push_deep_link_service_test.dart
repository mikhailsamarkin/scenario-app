// Unit-тесты сервиса deep link из push (SP-E3-04).
//
// Покрывают AC-01 (тап по push → scenarioId) и AC-02 (холодный старт →
// восстановление маршрута). PushDeepLinkSource — фейк.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/features/push/push_deep_link_service.dart';

/// Фейк над PushDeepLinkSource.
class _FakeSource implements PushDeepLinkSource {
  _FakeSource({this.initialScenarioId, this.openedScenarioIds = const []});

  String? initialScenarioId;
  List<String?> openedScenarioIds;

  @override
  Future<String?> getInitialScenarioId() async => initialScenarioId;

  @override
  Stream<String?> onScenarioOpened() async* {
    for (final id in openedScenarioIds) {
      yield id;
    }
  }
}

void main() {
  test('AC-02: холодный старт возвращает scenarioId из уведомления', () async {
    final source = _FakeSource(initialScenarioId: 'vecherinka');
    final service = PushDeepLinkService(source);

    final id = await service.getInitialScenarioId();

    expect(id, equals('vecherinka'));
  });

  test('AC-02: без уведомления scenarioId отсутствует', () async {
    final source = _FakeSource(initialScenarioId: null);
    final service = PushDeepLinkService(source);

    final id = await service.getInitialScenarioId();

    expect(id, isNull);
  });

  test('AC-01: тап по push из фона даёт scenarioId', () async {
    final source = _FakeSource(openedScenarioIds: ['semya']);
    final service = PushDeepLinkService(source);

    final ids = <String?>[];
    final sub = service.onScenarioOpened().listen(ids.add);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(ids, equals(['semya']));
  });
}
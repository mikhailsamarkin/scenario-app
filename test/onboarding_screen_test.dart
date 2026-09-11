// Widget-тесты онбординга (SP-E3-01, редизайн SP-E9-01).
//
// Покрывают AC-01 (объяснение «ситуация → игры» на первом шаге) и AC-02
// (отказ от push не блокирует переход к витрине). Шагов три; третий —
// запрос push с выбором из двух кнопок.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/features/onboarding/onboarding_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: онбординг объясняет «ситуация → игры»', (tester) async {
    await tester.pumpWidget(_wrap(OnboardingScreen(
      onCompleted: (context) {},
    )));
    await tester.pump();

    // Первый шаг объясняет модель «ситуация → игры».
    expect(find.text('Выбери ситуацию — получи игру'), findsOneWidget);
    expect(find.textContaining('Не знаете, в какую игру'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    // Переход по шагам.
    await tester.tap(find.text('Далее'));
    await tester.pump();
    expect(find.text('Подборки от людей, а не алгоритмов'), findsOneWidget);

    await tester.tap(find.text('Далее'));
    await tester.pump();
    // Третий шаг — запрос push (SP-E9-01: 3 шага вместо 4).
    expect(find.text('Новые сценарии — в уведомлениях'), findsOneWidget);
    expect(find.text('Разрешить уведомления'), findsOneWidget);
    expect(find.text('Начать без уведомлений'), findsOneWidget);
  });

  testWidgets('AC-02: отказ от push не блокирует переход к витрине',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(_wrap(OnboardingScreen(
      onCompleted: (context) {
        completed = true;
      },
    )));
    await tester.pump();

    // Пройти два шага ценности до шага запроса push.
    await tester.tap(find.text('Далее'));
    await tester.pump();
    await tester.tap(find.text('Далее'));
    await tester.pump();
    expect(find.text('Новые сценарии — в уведомлениях'), findsOneWidget);

    // Отказ («Начать без уведомлений») завершает онбординг без блокировки.
    await tester.tap(find.text('Начать без уведомлений'));
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('«Разрешить уведомления» подписывает и завершает',
      (tester) async {
    var completed = false;
    var allowPushCalled = false;
    await tester.pumpWidget(_wrap(OnboardingScreen(
      onCompleted: (context) {
        completed = true;
      },
      onAllowPush: () async {
        allowPushCalled = true;
      },
    )));
    await tester.pump();

    await tester.tap(find.text('Далее'));
    await tester.pump();
    await tester.tap(find.text('Далее'));
    await tester.pump();

    await tester.tap(find.text('Разрешить уведомления'));
    await tester.pump();
    expect(allowPushCalled, isTrue);
    expect(completed, isTrue);
  });

  testWidgets('«Пропустить» завершает онбординг сразу', (tester) async {
    var completed = false;
    await tester.pumpWidget(_wrap(OnboardingScreen(
      onCompleted: (context) {
        completed = true;
      },
    )));
    await tester.pump();

    await tester.tap(find.text('Пропустить'));
    await tester.pump();
    expect(completed, isTrue);
  });
}

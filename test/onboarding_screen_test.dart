// Widget-тесты онбординга (SP-E3-01).
//
// Покрывают AC-01 (объяснение «ситуация → игры») и AC-02 (отказ от push
// не блокирует переход к витрине). Онбординг — изолированный экран с
// колбэком завершения.

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
    expect(find.text('Выберите ситуацию'), findsOneWidget);
    expect(find.textContaining('Сценарий — это ситуация'), findsOneWidget);

    // Переход по шагам.
    await tester.tap(find.text('Далее'));
    await tester.pump();
    expect(find.text('Получите подборку игр'), findsOneWidget);

    await tester.tap(find.text('Далее'));
    await tester.pump();
    expect(find.text('Выбирайте и играйте'), findsOneWidget);
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

    // Пройти шаги ценности до шага запроса push.
    await tester.tap(find.text('Далее'));
    await tester.pump();
    await tester.tap(find.text('Далее'));
    await tester.pump();
    await tester.tap(find.text('Далее'));
    await tester.pump();

    // Шаг запроса push.
    expect(find.text('Уведомления о новинках'), findsOneWidget);

    // Отказ («Позже») завершает онбординг без блокировки.
    await tester.tap(find.text('Позже'));
    await tester.pump();
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
// Widget-тесты экрана принудительного обновления (SP-E6-06).
//
// Покрывают AC-01 (блокирующий экран при несовместимости). Текст —
// placeholder (US-E8-04).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/force_update/update_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: экран обновления блокирует основной контент',
      (tester) async {
    await tester.pumpWidget(_wrap(UpdateScreen()));
    await tester.pump();

    expect(find.text('Обновите приложение'), findsOneWidget);
    expect(find.textContaining('Доступна новая версия'), findsOneWidget);
  });
}
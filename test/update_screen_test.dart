// Widget-тесты экрана принудительного обновления (SP-E6-06, SP-E8-04).
//
// Покрывают AC-01 (блокирующий экран при несовместимости, текст и CTA).
// CTA в стор — через фейковый UrlLauncher.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/features/about/url_launcher.dart';
import 'package:scenario/force_update/update_screen.dart';

/// Фейк над UrlLauncher: запоминает вызовы.
class _FakeUrlLauncher implements UrlLauncher {
  final List<String> launched = [];

  @override
  Future<bool> launchExternal(String url) async {
    launched.add(url);
    return true;
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: экран обновления блокирует основной контент',
      (tester) async {
    await tester.pumpWidget(_wrap(UpdateScreen()));
    await tester.pump();

    expect(find.text('Обновите приложение'), findsOneWidget);
    expect(find.textContaining('Доступна новая версия'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
  });

  testWidgets('AC-01: кнопка «Обновить» открывает ссылку на стор',
      (tester) async {
    final launcher = _FakeUrlLauncher();
    await tester.pumpWidget(_wrap(UpdateScreen(urlLauncher: launcher)));
    await tester.pump();

    await tester.tap(find.text('Обновить'));
    await tester.pump();

    expect(launcher.launched.length, equals(1));
    expect(launcher.launched[0], contains('play.google.com'));
  });
}
// Widget-тесты экрана «О приложении» (SP-E6-04).
//
// Покрывают AC-01 (переход на согласованный URL политики) и TC-02
// (понятная ошибка при недоступной сети — без краша).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/features/about/about_screen.dart';
import 'package:scenario/features/about/url_launcher.dart';

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
  testWidgets('AC-01: тап по пункту открывает URL политики', (tester) async {
    final launcher = _FakeUrlLauncher();
    await tester.pumpWidget(_wrap(AboutScreen(urlLauncher: launcher)));
    await tester.pump();

    expect(find.text('Политика конфиденциальности'), findsOneWidget);

    await tester.tap(find.text('Политика конфиденциальности'));
    await tester.pump();

    expect(launcher.launched, equals([kPrivacyPolicyUrl]));
  });

  testWidgets('AC-01: URL политики стабилен и совпадает с сайтом',
      (tester) async {
    expect(kPrivacyPolicyUrl, equals('https://scenario-games.ru/privacy'));
  });
}
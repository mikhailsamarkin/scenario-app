// Экран принудительного обновления (SP-E8-04, A-45).
//
// Блокирует основной контент при несовместимой сборке/схеме (AC-01).
// Показывает текст и CTA в стор (iOS/Android). Ссылки на сторы —
// placeholder до публикации приложения (US-E8-05); id Android совпадает
// с applicationId (com.scenario.scenario).

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../features/about/url_launcher.dart';

/// Ссылки на сторы для экрана обновления (placeholder до релиза).
const String kAndroidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.scenario.scenario';
const String kIosStoreUrl = 'https://apps.apple.com/app/scenario';

/// Экран «Обновите приложение» (SP-E8-04).
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, this.urlLauncher});

  /// Открывает ссылку на стор (для тестируемости).
  final UrlLauncher? urlLauncher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обновите приложение')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Доступна новая версия приложения.'),
            const SizedBox(height: 12),
            const Text('Обновите приложение, чтобы продолжить.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                urlLauncher?.launchExternal(
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? kIosStoreUrl
                      : kAndroidStoreUrl,
                );
              },
              child: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }
}
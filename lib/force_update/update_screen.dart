// Экран принудительного обновления (SP-E6-06, A-45).
//
// Блокирует основной контент при несовместимой сборке/схеме (AC-01).
// Текст и ссылки на сторы — placeholder; готовая политика и CTA — US-E8-04.

import 'package:flutter/material.dart';

/// Экран «Обновите приложение» (SP-E6-06).
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

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
          ],
        ),
      ),
    );
  }
}
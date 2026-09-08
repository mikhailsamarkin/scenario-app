// Экран «О приложении» (SP-E6-04).
//
// Содержит пункт «Политика конфиденциальности», открывающий согласованный
// URL во внешнем браузере (SR-PRIV-5, AC-01). URL стабилен и совпадает с
// сайтом (US-E8-02).

import 'package:flutter/material.dart';

import 'url_launcher.dart';

/// Постоянный URL политики конфиденциальности (SR-PRIV-5, US-E6-04).
const String kPrivacyPolicyUrl = 'https://scenario-games.ru/privacy';

/// Экран «О приложении» (SP-E6-04).
class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
    required this.urlLauncher,
  });

  /// Открывает URL во внешнем браузере (для тестируемости).
  final UrlLauncher urlLauncher;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Политика конфиденциальности'),
            subtitle: const Text(kPrivacyPolicyUrl),
            onTap: () {
              widget.urlLauncher.launchExternal(kPrivacyPolicyUrl);
            },
          ),
        ],
      ),
    );
  }
}
// Открытие внешних URL (SP-E6-04).
//
// Открывает политику конфиденциальности во внешнем браузере (SR-PRIV-5,
// AC-01). Зависит от абстракции [UrlLauncher] для тестируемости.

import 'package:url_launcher/url_launcher.dart';

/// Открывает URL во внешнем браузере (абстракция для тестируемости).
abstract interface class UrlLauncher {
  Future<bool> launchExternal(String url);
}

/// Реализация поверх url_launcher: внешний браузер (US-E6-04).
class PlatformUrlLauncher implements UrlLauncher {
  @override
  Future<bool> launchExternal(String url) async {
    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
}
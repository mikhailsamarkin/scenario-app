// Инициализация Supabase (медиа, ED-14).
// Использует конфигурацию окружения из AppConfig.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// Инициализирует Supabase для текущего окружения.
/// Вызывается один раз при старте приложения (после Firebase.initializeApp).
Future<void> initSupabase() async {
  final url = AppConfig.supabaseUrl;
  final anonKey = AppConfig.supabaseAnonKey;

  if (url.isEmpty || anonKey.isEmpty) {
    throw StateError(
      'Supabase не настроен: передайте --dart-define=SUPABASE_ANON_KEY_DEV '
      '(или _PROD) при сборке.',
    );
  }

  await Supabase.initialize(url: url, publishableKey: anonKey);
}

/// Доступ к клиенту Supabase (после initSupabase).
SupabaseClient get supabase => Supabase.instance.client;

/// Публичный URL объекта в бакете games.
/// path — путь внутри бакета, например 'games/{id}/image.jpg'.
String supabasePublicUrl(String path) {
  final url = AppConfig.supabaseUrl;
  return '$url/storage/v1/object/public/$path';
}
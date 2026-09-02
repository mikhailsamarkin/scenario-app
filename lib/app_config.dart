// Конфигурация окружения приложения (dev/prod).
// Выбор окружения: --dart-define=APP_ENV=dev|prod (по умолчанию dev).
// Flutter flavors (dev/prod) задают applicationId и google-services.json;
// APP_ENV выбирает Firebase/Supabase конфигурацию в рантайме.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'firebase_options_dev.dart';
import 'firebase_options_prod.dart';

enum AppEnv { dev, prod }

class AppConfig {
  AppConfig._();

  static const String _envRaw = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnv get env {
    switch (_envRaw) {
      case 'prod':
        return AppEnv.prod;
      case 'dev':
        return AppEnv.dev;
      default:
        throw ArgumentError('Unknown APP_ENV: $_envRaw');
    }
  }

  static bool get isProd => env == AppEnv.prod;
  static bool get isDev => env == AppEnv.dev;

  /// Firebase options для текущего окружения.
  static FirebaseOptions get firebaseOptions {
    switch (env) {
      case AppEnv.dev:
        return DevFirebaseOptions.currentPlatform;
      case AppEnv.prod:
        return ProdFirebaseOptions.currentPlatform;
    }
  }

  /// Supabase URL для текущего окружения.
  static String get supabaseUrl {
    switch (env) {
      case AppEnv.dev:
        return 'https://bzraqbhydmklvpfqiidl.supabase.co';
      case AppEnv.prod:
        return 'https://sjxmmqnejolgtwcfjzsd.supabase.co';
    }
  }

  /// Supabase anon key для текущего окружения.
  static String get supabaseAnonKey {
    switch (env) {
      case AppEnv.dev:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY_DEV',
          defaultValue: '',
        );
      case AppEnv.prod:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY_PROD',
          defaultValue: '',
        );
    }
  }

  /// Имя проекта Firebase (для логирования/диагностики).
  static String get projectId {
    switch (env) {
      case AppEnv.dev:
        return 'scenario-ba26a';
      case AppEnv.prod:
        return 'scenario-prod-491c';
    }
  }
}
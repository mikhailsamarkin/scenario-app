// Точка входа приложения и навигация Home → Scenario → Game (A-15).
//
// Связывает экраны (SP-E2-01/02/03) с реальным репозиторием Firestore
// (A-11, A-38) и Navigator'ом. Колбэки экранов (onOpenScenario/onOpenGame)
// переводят на соответствующие экраны через Navigator.push.

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

import 'analytics/analytics_events.dart';
import 'analytics/analytics_service.dart';
import 'analytics/block_view_tracker.dart';
import 'data/firestore/aggregate_repository_interface.dart';
import 'features/about/about_screen.dart';
import 'features/about/url_launcher.dart';
import 'features/game/game_screen.dart';
import 'features/group/group_screen.dart';
import 'features/home/home_screen.dart';
import 'features/link/universal_link_service.dart';
import 'features/onboarding/onboarding_prefs.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/push_subscription_service.dart';
import 'features/push/push_deep_link_service.dart';
import 'features/scenario/scenario_screen.dart';
import 'features/share/share_scenario_service.dart';
import 'force_update/force_update_checker.dart';
import 'force_update/update_screen.dart';

/// Корневой виджет приложения с навигацией (A-15).
class ScenarioApp extends StatefulWidget {
  const ScenarioApp({
    super.key,
    required this.repository,
    this.deepLinkSource,
    this.linkSource,
    this.onboardingStatusSource,
    this.analyticsLogger,
    this.urlLauncher,
    this.remoteConfigSource,
  });

  /// Источник данных (в боевом коде — Firestore, A-11/A-38).
  final AggregateRepository repository;

  /// Источник deep link из push (для тестируемости; по умолчанию — FCM).
  final PushDeepLinkSource? deepLinkSource;

  /// Источник Universal Links (для тестируемости; по умолчанию — app_links).
  final LinkSource? linkSource;

  /// Источник флага «онбординг пройден» (для тестируемости).
  final OnboardingStatusSource? onboardingStatusSource;

  /// Логгер аналитики (для тестируемости; по умолчанию — Firebase).
  final AnalyticsLogger? analyticsLogger;

  /// Открывает URL во внешнем браузере (для тестируемости).
  final UrlLauncher? urlLauncher;

  /// Источник Remote Config (для тестируемости; по умолчанию — не форсить).
  final RemoteConfigSource? remoteConfigSource;

  @override
  State<ScenarioApp> createState() => _ScenarioAppState();
}

class _ScenarioAppState extends State<ScenarioApp> {
  late Future<bool> _onboardingFuture;
  late Future<bool> _forceUpdateFuture;
  late final PushDeepLinkService _deepLinkService;
  late final UniversalLinkService _universalLinkService;
  late final AnalyticsService _analytics;
  late final BlockViewTracker _blockViewTracker;
  StreamSubscription<String?>? _deepLinkSub;
  StreamSubscription<String?>? _universalLinkSub;

  @override
  void initState() {
    super.initState();
    _onboardingFuture =
        (widget.onboardingStatusSource ?? SharedPrefsOnboardingStatus())
            .isCompleted();
    _forceUpdateFuture = ForceUpdateChecker(
      widget.remoteConfigSource ?? FirebaseRemoteConfigSource(FirebaseRemoteConfig.instance),
    ).isUpdateRequired();
    _analytics = AnalyticsService(
      widget.analyticsLogger ?? FirebaseAnalyticsLogger(FirebaseAnalytics.instance),
    );
    _blockViewTracker = BlockViewTracker(_analytics);
    _deepLinkService = PushDeepLinkService(
      widget.deepLinkSource ??
          FirebaseMessagingDeepLinkSource(FirebaseMessaging.instance),
    );
    _universalLinkService = UniversalLinkService(
      widget.linkSource ?? AppLinksSource(AppLinks()),
      widget.repository,
    );
    _listenDeepLinks();
    _listenUniversalLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _universalLinkSub?.cancel();
    super.dispose();
  }

  /// Обработка Universal Links: холодный старт (getInitialLink) и фоновое
  /// открытие (uriLinkStream) → навигация на сценарий (AC-01).
  void _listenUniversalLinks() {
    _universalLinkService.getInitialScenarioId().then((scenarioId) {
      if (scenarioId != null && mounted) {
        _openScenario(scenarioId, ScenarioOpenSource.deeplink);
      }
    });
    _universalLinkSub =
        _universalLinkService.onScenarioOpened().listen((scenarioId) {
      if (scenarioId != null && mounted) {
        _openScenario(scenarioId, ScenarioOpenSource.deeplink);
      }
    });
  }

  /// Обработка тапа по push: холодный старт (getInitialMessage) и фоновый
  /// тап (onMessageOpenedApp) → навигация на экран сценария (AC-01, AC-02).
  void _listenDeepLinks() {
    _deepLinkService.getInitialScenarioId().then((scenarioId) {
      if (scenarioId != null && mounted) {
        _openScenario(scenarioId, ScenarioOpenSource.push);
      }
    });
    _deepLinkSub = _deepLinkService.onScenarioOpened().listen((scenarioId) {
      if (scenarioId != null && mounted) {
        _openScenario(scenarioId, ScenarioOpenSource.push);
      }
    });
  }

  void _openScenario(String scenarioId, ScenarioOpenSource source) {
    _analytics.logScenarioOpen(scenarioId, source);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScenarioRoute(
          scenarioId: scenarioId,
          repository: widget.repository,
          blockViewTracker: _blockViewTracker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: _forceUpdateFuture,
        builder: (context, snapshot) {
          if (snapshot.data ?? false) {
            return _UpdateRoute();
          }
          return FutureBuilder<bool>(
            future: _onboardingFuture,
            builder: (context, snapshot) {
              final completed = snapshot.data ?? false;
              if (completed) {
                return _HomeRoute(
                  repository: widget.repository,
                  analytics: _analytics,
                  urlLauncher: widget.urlLauncher ?? PlatformUrlLauncher(),
                  blockViewTracker: _blockViewTracker,
                );
              }
              return _OnboardingRoute(
                repository: widget.repository,
                onCompleted: (context) {
                  markOnboardingCompleted();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _HomeRoute(
                        repository: widget.repository,
                        analytics: _analytics,
                        urlLauncher: widget.urlLauncher ?? PlatformUrlLauncher(),
                        blockViewTracker: _blockViewTracker,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Маршрут экрана принудительного обновления (US-E6-06).
class _UpdateRoute extends StatelessWidget {
  const _UpdateRoute();

  @override
  Widget build(BuildContext context) {
    return UpdateScreen();
  }
}

/// Маршрут онбординга первого запуска.
class _OnboardingRoute extends StatelessWidget {
  const _OnboardingRoute({required this.repository, required this.onCompleted});

  final AggregateRepository repository;
  final OnboardingCompleted onCompleted;

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onCompleted: onCompleted,
      onAllowPush: () async {
        final service = PushSubscriptionService(
          FirebaseMessagingAdapter(FirebaseMessaging.instance),
        );
        await service.subscribeToNewScenarios();
      },
    );
  }
}

/// Маршрут главного экрана (витрина сценариев).
class _HomeRoute extends StatelessWidget {
  const _HomeRoute({
    required this.repository,
    required this.analytics,
    required this.urlLauncher,
    required this.blockViewTracker,
  });

  final AggregateRepository repository;
  final AnalyticsService analytics;
  final UrlLauncher urlLauncher;
  final BlockViewTracker blockViewTracker;

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      repository: repository,
      onOpenAbout: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _AboutRoute(urlLauncher: urlLauncher)),
        );
      },
      onOpenScenario: (context, scenarioId) {
        analytics.logScenarioOpen(scenarioId, ScenarioOpenSource.home);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ScenarioRoute(
              scenarioId: scenarioId,
              repository: repository,
              blockViewTracker: blockViewTracker,
            ),
          ),
        );
      },
      onOpenGroup: (context, groupId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _GroupRoute(
              groupId: groupId,
              repository: repository,
              blockViewTracker: blockViewTracker,
            ),
          ),
        );
      },
    );
  }
}

/// Маршрут экрана группы смысла (US-E7-01).
class _GroupRoute extends StatelessWidget {
  const _GroupRoute({
    required this.groupId,
    required this.repository,
    required this.blockViewTracker,
  });

  final String groupId;
  final AggregateRepository repository;
  final BlockViewTracker blockViewTracker;

  @override
  Widget build(BuildContext context) {
    return GroupScreen(
      groupId: groupId,
      repository: repository,
      onOpenScenario: (context, scenarioId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ScenarioRoute(
              scenarioId: scenarioId,
              repository: repository,
              blockViewTracker: blockViewTracker,
            ),
          ),
        );
      },
    );
  }
}

/// Маршрут экрана «О приложении» (US-E6-04).
class _AboutRoute extends StatelessWidget {
  const _AboutRoute({required this.urlLauncher});

  final UrlLauncher urlLauncher;

  @override
  Widget build(BuildContext context) {
    return AboutScreen(urlLauncher: urlLauncher);
  }
}

/// Маршрут экрана сценария.
class _ScenarioRoute extends StatelessWidget {
  const _ScenarioRoute({
    required this.scenarioId,
    required this.repository,
    required this.blockViewTracker,
  });

  final String scenarioId;
  final AggregateRepository repository;
  final BlockViewTracker blockViewTracker;

  @override
  Widget build(BuildContext context) {
    final shareService = ShareScenarioService(SharePlusLauncher());
    return ScenarioScreen(
      scenarioId: scenarioId,
      repository: repository,
      blockViewTracker: blockViewTracker,
      onShare: (scenario) {
        shareService.shareScenario(scenario);
      },
      onOpenGame: (context, gameId, scenarioId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _GameRoute(
              gameId: gameId,
              scenarioId: scenarioId,
              repository: repository,
              blockViewTracker: blockViewTracker,
            ),
          ),
        );
      },
    );
  }
}

/// Маршрут экрана игры.
class _GameRoute extends StatelessWidget {
  const _GameRoute({
    required this.gameId,
    required this.scenarioId,
    required this.repository,
    required this.blockViewTracker,
  });

  final String gameId;
  final String scenarioId;
  final AggregateRepository repository;
  final BlockViewTracker blockViewTracker;

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      gameId: gameId,
      scenarioId: scenarioId,
      repository: repository,
      blockViewTracker: blockViewTracker,
    );
  }
}
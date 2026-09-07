// Точка входа приложения и навигация Home → Scenario → Game (A-15).
//
// Связывает экраны (SP-E2-01/02/03) с реальным репозиторием Firestore
// (A-11, A-38) и Navigator'ом. Колбэки экранов (onOpenScenario/onOpenGame)
// переводят на соответствующие экраны через Navigator.push.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'data/firestore/aggregate_repository_interface.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_prefs.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/push_subscription_service.dart';
import 'features/push/push_deep_link_service.dart';
import 'features/scenario/scenario_screen.dart';
import 'features/share/share_scenario_service.dart';

/// Корневой виджет приложения с навигацией (A-15).
class ScenarioApp extends StatefulWidget {
  const ScenarioApp({
    super.key,
    required this.repository,
    this.deepLinkSource,
    this.onboardingStatusSource,
  });

  /// Источник данных (в боевом коде — Firestore, A-11/A-38).
  final AggregateRepository repository;

  /// Источник deep link из push (для тестируемости; по умолчанию — FCM).
  final PushDeepLinkSource? deepLinkSource;

  /// Источник флага «онбординг пройден» (для тестируемости).
  final OnboardingStatusSource? onboardingStatusSource;

  @override
  State<ScenarioApp> createState() => _ScenarioAppState();
}

class _ScenarioAppState extends State<ScenarioApp> {
  late Future<bool> _onboardingFuture;
  late final PushDeepLinkService _deepLinkService;
  StreamSubscription<String?>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _onboardingFuture =
        (widget.onboardingStatusSource ?? SharedPrefsOnboardingStatus())
            .isCompleted();
    _deepLinkService = PushDeepLinkService(
      widget.deepLinkSource ??
          FirebaseMessagingDeepLinkSource(FirebaseMessaging.instance),
    );
    _listenDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  /// Обработка тапа по push: холодный старт (getInitialMessage) и фоновый
  /// тап (onMessageOpenedApp) → навигация на экран сценария (AC-01, AC-02).
  void _listenDeepLinks() {
    _deepLinkService.getInitialScenarioId().then((scenarioId) {
      if (scenarioId != null && mounted) {
        _openScenario(scenarioId);
      }
    });
    _deepLinkSub = _deepLinkService.onScenarioOpened().listen((scenarioId) {
      if (scenarioId != null && mounted) {
        _openScenario(scenarioId);
      }
    });
  }

  void _openScenario(String scenarioId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScenarioRoute(
          scenarioId: scenarioId,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: _onboardingFuture,
        builder: (context, snapshot) {
          final completed = snapshot.data ?? false;
          if (completed) {
            return _HomeRoute(repository: widget.repository);
          }
          return _OnboardingRoute(
            repository: widget.repository,
            onCompleted: (context) {
              markOnboardingCompleted();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => _HomeRoute(repository: widget.repository),
                ),
              );
            },
          );
        },
      ),
    );
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
  const _HomeRoute({required this.repository});

  final AggregateRepository repository;

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      repository: repository,
      onOpenScenario: (context, scenarioId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ScenarioRoute(
              scenarioId: scenarioId,
              repository: repository,
            ),
          ),
        );
      },
    );
  }
}

/// Маршрут экрана сценария.
class _ScenarioRoute extends StatelessWidget {
  const _ScenarioRoute({required this.scenarioId, required this.repository});

  final String scenarioId;
  final AggregateRepository repository;

  @override
  Widget build(BuildContext context) {
    final shareService = ShareScenarioService(SharePlusLauncher());
    return ScenarioScreen(
      scenarioId: scenarioId,
      repository: repository,
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
  });

  final String gameId;
  final String scenarioId;
  final AggregateRepository repository;

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      gameId: gameId,
      scenarioId: scenarioId,
      repository: repository,
    );
  }
}
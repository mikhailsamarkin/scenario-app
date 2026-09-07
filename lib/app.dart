// Точка входа приложения и навигация Home → Scenario → Game (A-15).
//
// Связывает экраны (SP-E2-01/02/03) с реальным репозиторием Firestore
// (A-11, A-38) и Navigator'ом. Колбэки экранов (onOpenScenario/onOpenGame)
// переводят на соответствующие экраны через Navigator.push.

import 'package:flutter/material.dart';

import 'data/firestore/aggregate_repository_interface.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_prefs.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/scenario/scenario_screen.dart';

/// Корневой виджет приложения с навигацией (A-15).
class ScenarioApp extends StatefulWidget {
  const ScenarioApp({super.key, required this.repository});

  /// Источник данных (в боевом коде — Firestore, A-11/A-38).
  final AggregateRepository repository;

  @override
  State<ScenarioApp> createState() => _ScenarioAppState();
}

class _ScenarioAppState extends State<ScenarioApp> {
  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = isOnboardingCompleted();
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
    return ScenarioScreen(
      scenarioId: scenarioId,
      repository: repository,
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
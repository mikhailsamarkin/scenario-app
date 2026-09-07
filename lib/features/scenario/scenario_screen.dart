// Экран сценария (SP-E2-02): блок «почему эти игры подходят» выше списка
// игр (FR-M-2, версия 0.9+ БТ), переносы строк сохраняются (A-4a).
//
// Читает `scenario_public/{scenarioId}` через `AggregateRepository`
// (A-11, A-38). Переход на экран игры (US-E2-03) — через инжектируемый
// колбэк `onOpenGame(gameId, scenarioId)` для тестируемости.

import 'package:flutter/material.dart';

import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../supabase_config.dart';

/// Открывает экран игры (US-E2-03) с контекстом сценария.
typedef ScenarioOpenGame =
    void Function(BuildContext context, String gameId, String scenarioId);

/// Экран сценария (SP-E2-02).
class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({
    super.key,
    required this.scenarioId,
    required this.repository,
    required this.onOpenGame,
    this.isOffline = false,
  });

  /// ID сценария (`scenario_public/{scenarioId}`).
  final String scenarioId;

  /// Источник данных `scenario_public` (A-11, A-38).
  final AggregateRepository repository;

  /// Переход на экран игры (US-E2-03).
  final ScenarioOpenGame onOpenGame;

  /// Офлайн-режим: при отсутствии кэша показать «нет сети» (AC-02).
  final bool isOffline;

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  late Future<ScenarioPublic?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getScenario(widget.scenarioId);
  }

  void _reload() {
    setState(() {
      _future = widget.repository.getScenario(widget.scenarioId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сценарий')),
      body: FutureBuilder<ScenarioPublic?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error!);
          }
          final scenario = snapshot.data;
          if (scenario == null) {
            // Офлайн без кэша — понятное состояние «нет сети» (AC-02).
            if (widget.isOffline) {
              return const Center(child: Text('Нет сети. Проверьте подключение.'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _ScenarioContent(
            scenario: scenario,
            onOpenGame: widget.onOpenGame,
          );
        },
      ),
    );
  }

  Widget _errorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Не удалось загрузить сценарий: $error'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _reload, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _ScenarioContent extends StatelessWidget {
  const _ScenarioContent({required this.scenario, required this.onOpenGame});

  final ScenarioPublic scenario;
  final ScenarioOpenGame onOpenGame;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scenario.title, style: textTheme.headlineMedium),
              if (scenario.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(scenario.subtitle!, style: textTheme.bodyMedium),
              ],
              // Блок обоснования — выше списка игр (AC-01, FR-M-2).
              const SizedBox(height: 16),
              Text('Почему эти игры подходят', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              // Plain text с сохранением переносов \n (AC-02, A-4a).
              Text(
                scenario.whyTheseGames,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        // Список игр в порядке из данных (AC-01).
        for (final game in scenario.games)
          _GameTile(
            game: game,
            scenarioId: scenario.id,
            onOpenGame: onOpenGame,
          ),
      ],
    );
  }
}

/// Карточка игры в списке сценария.
class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.scenarioId,
    required this.onOpenGame,
  });

  final ScenarioGameRef game;
  final String scenarioId;
  final ScenarioOpenGame onOpenGame;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(game.title),
      subtitle: Text(game.shortDescription),
      leading: game.imageRef == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image.network(
                  supabasePublicUrl(game.imageRef!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
      onTap: () {
        onOpenGame(context, game.gameId, scenarioId);
      },
    );
  }
}
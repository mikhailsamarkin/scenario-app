// Экран сценария (SP-E2-02, редизайн SP-E9-01): hero-фото с капс-категорией
// (заголовок группы смысла), интро-подзаголовок и «Поделиться», блок
// «почему эти игры подходят» выше списка игр (FR-M-2, версия 0.9+ БТ),
// переносы строк сохраняются (A-4a). Вёрстка — по
// docs/figma/screens/scenario.md.
//
// Читает `scenario_public/{scenarioId}` через `AggregateRepository`
// (A-11, A-38). Hero-фото и категория догружаются из карточек
// `home_feed`/`semantic_groups_public` (в scenario_public их нет).
// Переход на экран игры — через инжектируемый колбэк
// `onOpenGame(gameId, scenarioId)`.

import 'package:flutter/material.dart';

import '../../analytics/analytics_events.dart';
import '../../analytics/block_view_tracker.dart';
import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/labels.dart';
import '../../design/widgets.dart';
import 'block_view_reporter.dart';

/// Открывает экран игры (US-E2-03) с контекстом сценария.
typedef ScenarioOpenGame =
    void Function(BuildContext context, String gameId, String scenarioId);

/// Действие «Поделиться» (US-E5-01).
typedef ScenarioShare = void Function(ScenarioPublic scenario);

/// Экран сценария (SP-E2-02, SP-E9-01).
class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({
    super.key,
    required this.scenarioId,
    required this.repository,
    required this.onOpenGame,
    this.onShare,
    this.isOffline = false,
    this.blockViewTracker,
  });

  /// ID сценария (`scenario_public/{scenarioId}`).
  final String scenarioId;

  /// Источник данных `scenario_public` (A-11, A-38).
  final AggregateRepository repository;

  /// Переход на экран игры (US-E2-03).
  final ScenarioOpenGame onOpenGame;

  /// Действие «Поделиться» (US-E5-01).
  final ScenarioShare? onShare;

  /// Офлайн-режим: при отсутствии кэша показать «нет сети» (AC-02).
  final bool isOffline;

  /// Трекер block_view (US-E6-03); null — аналитика не подключена.
  final BlockViewTracker? blockViewTracker;

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

/// Сценарий + заголовок первой группы смысла (капс-категория hero).
class _ScenarioView {
  const _ScenarioView(this.scenario, this.category, this.heroImageRef);

  final ScenarioPublic scenario;
  final String? category;
  final String? heroImageRef;
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  late Future<_ScenarioView?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ScenarioView?> _load() async {
    final scenario = await widget.repository.getScenario(widget.scenarioId);
    if (scenario == null) return null;
    // Категория и hero-фото догружаются независимо; их отсутствие не
    // ломает экран (офлайн-кэш мог не содержать группу/фид).
    final category = await _categoryOf(scenario);
    final heroImageRef = await _heroImageOf(scenario);
    return _ScenarioView(scenario, category, heroImageRef);
  }

  /// Заголовок первой группы смысла сценария (для капс-категории hero).
  Future<String?> _categoryOf(ScenarioPublic scenario) async {
    if (scenario.semanticGroupIds.isEmpty) return null;
    try {
      final group = await widget.repository
          .getSemanticGroup(scenario.semanticGroupIds.first);
      return group?.title;
    } on Exception {
      return null;
    }
  }

  /// Фото карточки сценария из `home_feed` (в scenario_public изображения
  /// нет; чтение кэшируется, работает и при входе по deep link).
  Future<String?> _heroImageOf(ScenarioPublic scenario) async {
    try {
      final feed = await widget.repository.getHomeFeed();
      if (feed == null) return null;
      for (final card in feed.vitrine) {
        if (card.scenarioId == scenario.id) return card.imageRef;
      }
      for (final group in feed.groups) {
        final groupDoc = await widget.repository
            .getSemanticGroup(group.semanticGroupId);
        for (final card in groupDoc?.scenarios ?? const <ScenarioCard>[]) {
          if (card.scenarioId == scenario.id) return card.imageRef;
        }
      }
    } on Exception {
      return null;
    }
    return null;
  }

  @override
  void dispose() {
    // Сессия экрана заканчивается при уходе со страницы (US-E6-03, A-36).
    widget.blockViewTracker?.resetSession();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: FutureBuilder<_ScenarioView?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error!);
          }
          final data = snapshot.data;
          if (data == null) {
            // Офлайн без кэша — понятное состояние «нет сети» (AC-02).
            if (widget.isOffline) {
              return _messageScreen('Нет сети. Проверьте подключение.');
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _ScenarioContent(
            scenario: data.scenario,
            category: data.category,
            heroImageRef: data.heroImageRef,
            onOpenGame: widget.onOpenGame,
            onShare: widget.onShare,
            blockViewTracker: widget.blockViewTracker,
          );
        },
      ),
    );
  }

  Widget _errorState(Object error) {
    return _messageScreen(
      'Не удалось загрузить сценарий',
      action: FilledButton(onPressed: _reload, child: const Text('Повторить')),
      details: '$error',
    );
  }

  Widget _messageScreen(String message, {Widget? action, String? details}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(details, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}

class _ScenarioContent extends StatelessWidget {
  const _ScenarioContent({
    required this.scenario,
    required this.category,
    required this.heroImageRef,
    required this.onOpenGame,
    this.onShare,
    this.blockViewTracker,
  });

  final ScenarioPublic scenario;
  final String? category;
  final String? heroImageRef;
  final ScenarioOpenGame onOpenGame;
  final ScenarioShare? onShare;
  final BlockViewTracker? blockViewTracker;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HeroBlock(
          imageRef: heroImageRef,
          height: 420,
          category: category?.toUpperCase(),
          title: scenario.title,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        // Интро: подзаголовок курсивом + «Поделиться» (US-E5-01).
        if (scenario.subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(scenario.subtitle!, style: AppTypography.scenarioIntro),
                ),
                if (onShare != null) ...[
                  const SizedBox(width: 12),
                  PillButton(
                    onPressed: () => onShare!(scenario),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ios_share, size: 16, color: AppColors.textOnLight),
                        SizedBox(width: 6),
                        Text(
                          'Поделиться',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        // Блок обоснования — выше списка игр (AC-01, FR-M-2) на
        // чередующейся полосе.
        BlockViewReporter(
          blockId: kBlockScenarioWhy,
          tracker: blockViewTracker,
          topOffset: 500,
          height: 160,
          child: Container(
            color: AppColors.bgCreamAlt,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CapsHeader('Почему эти игры подходят'),
                const SizedBox(height: 10),
                // Plain text с сохранением переносов \n (AC-02, A-4a).
                Text(scenario.whyTheseGames, style: AppTypography.bodyOnLight),
              ],
            ),
          ),
        ),
        // Список игр в порядке из данных (AC-01) с чипсами характеристик.
        BlockViewReporter(
          blockId: kBlockScenarioGames,
          tracker: blockViewTracker,
          topOffset: 700,
          height: 400,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CapsHeader(
                  'В подборке · ${scenario.games.length} '
                  '${gamesPlural(scenario.games.length)}',
                ),
                const SizedBox(height: 12),
                for (final game in scenario.games)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GameListCard(
                      title: game.title,
                      imageRef: game.imageRef,
                      chips: _chips(game),
                      onTap: () => onOpenGame(context, game.gameId, scenario.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _chips(ScenarioGameRef game) {
    return [
      if (game.playersHint != null) playersChipLabel(game.playersHint!),
      if (game.durationBucket != null)
        durationBucketLabel(game.durationBucket!),
      if (game.rulesComplexity != null)
        rulesComplexityLabel(game.rulesComplexity!),
    ];
  }
}

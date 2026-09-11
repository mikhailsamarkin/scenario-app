// Экран игры (SP-E2-03, редизайн SP-E9-01): hero-карусель во всю ширину
// с точками и бейджем caption, сетка 2×2 характеристик «КРАТКО», краткое
// описание в контексте сценария (FR-M-2, CR-4.1, CR-5, A-12, ED-9).
// Вёрстка — по docs/figma/screens/game.md.
//
// Читает `game_public/{gameId}` через `AggregateRepository` (A-11, A-38).

import 'package:flutter/material.dart';

import '../../analytics/analytics_events.dart';
import '../../analytics/block_view_tracker.dart';
import '../../cache/cached_network_image_widget.dart';
import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/labels.dart';
import '../../design/widgets.dart';
import '../../supabase_config.dart';
import '../scenario/block_view_reporter.dart';

/// Вызывает виджет изображения слайдов карусели.
///
/// По умолчанию — [`CachedNetworkImageWidget`]; в тестах подставляется
/// заглушка, чтобы не зависеть от плагина дискового кэша.
typedef GameSlideImageBuilder =
    Widget Function(BuildContext context, Slide slide);

Widget _defaultSlideImage(BuildContext context, Slide slide) {
  return CachedNetworkImageWidget(
    url: supabasePublicUrl(slide.imageRef),
    fit: BoxFit.cover,
    placeholder: Container(
      color: AppColors.bgDark,
      child: const Center(child: CircularProgressIndicator()),
    ),
    errorWidget: Container(
      color: AppColors.bgDark,
      child: const Icon(Icons.broken_image),
    ),
  );
}

/// Экран игры (SP-E2-03, SP-E9-01).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameId,
    required this.scenarioId,
    required this.repository,
    this.slideImageBuilder = _defaultSlideImage,
    this.isOffline = false,
    this.blockViewTracker,
  });

  /// ID игры (`game_public/{gameId}`).
  final String gameId;

  /// ID открытого сценария — контекст для краткого описания (AC-03).
  final String scenarioId;

  /// Источник данных `game_public` (A-11, A-38).
  final AggregateRepository repository;

  /// Фабрика виджета изображения слайда (тестируемость).
  final GameSlideImageBuilder slideImageBuilder;

  /// Офлайн-режим: при отсутствии кэша показать «нет сети» (AC-02).
  final bool isOffline;

  /// Трекер block_view (US-E6-03); null — аналитика не подключена.
  final BlockViewTracker? blockViewTracker;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Future<GamePublic?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getGame(widget.gameId);
  }

  @override
  void dispose() {
    // Сессия экрана заканчивается при уходе со страницы (US-E6-03, A-36).
    widget.blockViewTracker?.resetSession();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.getGame(widget.gameId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: FutureBuilder<GamePublic?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error!);
          }
          final game = snapshot.data;
          if (game == null) {
            // Офлайн без кэша — понятное состояние «нет сети» (AC-02).
            if (widget.isOffline) {
              return _messageScreen('Нет сети. Проверьте подключение.');
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _GameContent(
            game: game,
            scenarioId: widget.scenarioId,
            slideImageBuilder: widget.slideImageBuilder,
            blockViewTracker: widget.blockViewTracker,
          );
        },
      ),
    );
  }

  Widget _errorState(Object error) {
    return _messageScreen(
      'Не удалось загрузить игру',
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

class _GameContent extends StatelessWidget {
  const _GameContent({
    required this.game,
    required this.scenarioId,
    required this.slideImageBuilder,
    this.blockViewTracker,
  });

  final GamePublic game;
  final String scenarioId;
  final GameSlideImageBuilder slideImageBuilder;
  final BlockViewTracker? blockViewTracker;

  @override
  Widget build(BuildContext context) {
    // Краткое описание в контексте открытого сценария (AC-03, A-12).
    // Описание из другого сценария не подставляется (ED-9).
    GameScenarioRef? scenario;
    for (final s in game.scenarios) {
      if (s.scenarioId == scenarioId) {
        scenario = s;
        break;
      }
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        BlockViewReporter(
          blockId: kBlockGameCarousel,
          tracker: blockViewTracker,
          topOffset: 0,
          height: 430,
          child: _HeroCarousel(
            slides: game.carousel,
            imageBuilder: slideImageBuilder,
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.title, style: AppTypography.displayOnLight),
              const SizedBox(height: 12),
              const Divider(color: AppColors.bgCreamAlt, thickness: 2),
            ],
          ),
        ),
        BlockViewReporter(
          blockId: kBlockGameCharacteristics,
          tracker: blockViewTracker,
          topOffset: 500,
          height: 200,
          child: Container(
            color: AppColors.bgCream,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CapsHeader('Кратко'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CharacteristicTile(
                        icon: Icons.group_outlined,
                        label: 'Игроки',
                        value: game.playersHint.uiLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CharacteristicTile(
                        icon: Icons.schedule,
                        label: 'Время',
                        value: durationBucketLabel(game.durationBucket),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CharacteristicTile(
                        icon: Icons.favorite_outline,
                        label: 'Возраст',
                        value: game.ageHint.uiLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CharacteristicTile(
                        icon: Icons.auto_awesome,
                        label: 'Правила',
                        value: rulesComplexityLabel(game.rulesComplexity),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (scenario != null)
          Container(
            color: AppColors.bgCreamAlt,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CapsHeader('Описание'),
                const SizedBox(height: 10),
                Text(scenario.shortDescription, style: AppTypography.bodyOnLight),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Назад'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero-карусель: фото во всю ширину, стрелка «назад», бейдж caption,
/// точки-индикаторы.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({
    required this.slides,
    required this.imageBuilder,
    required this.onBack,
  });

  final List<Slide> slides;
  final GameSlideImageBuilder imageBuilder;
  final VoidCallback onBack;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      return HeroBlock(height: 430, onBack: widget.onBack);
    }
    return SizedBox(
      height: 430,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              final badge = slide.caption ?? slide.alt;
              return Stack(
                fit: StackFit.expand,
                children: [
                  widget.imageBuilder(context, slide),
                  if (badge != null && badge.isNotEmpty)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                        child: PillButton.photoBadge(
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textOnDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Затемнение и нижние слоты — поверх всей карусели.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.6, 1.0],
                colors: AppColors.heroGradient,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DotsIndicator(
                count: widget.slides.length,
                activeIndex: _page,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

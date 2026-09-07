// Экран игры (SP-E2-03): карусель, четыре характеристики, краткое описание
// в контексте сценария (FR-M-2, CR-4.1, CR-5, A-12, ED-9).
//
// Читает `game_public/{gameId}` через `AggregateRepository` (A-11, A-38).
// Экран иммьютабелен: получает gameId и scenarioId (контекст описания) и
// репозиторий; для тестов передаётся фейковый репозиторий.

import 'package:flutter/material.dart';

import '../../cache/cached_network_image_widget.dart';
import '../../data/contract/enums.dart';
import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../supabase_config.dart';

/// Подпись на русском для `DurationBucket` (ED-2; у enum нет uiLabel).
String durationBucketLabel(DurationBucket value) {
  switch (value) {
    case DurationBucket.warmup:
      return 'Разминка';
    case DurationBucket.short:
      return 'Короткая';
    case DurationBucket.evening:
      return 'На вечер';
    case DurationBucket.long:
      return 'Долгая';
    case DurationBucket.mainEvent:
      return 'Главное событие';
  }
}

/// Подпись на русском для `RulesComplexity` (ED-2; у enum нет uiLabel).
String rulesComplexityLabel(RulesComplexity value) {
  switch (value) {
    case RulesComplexity.easy:
      return 'Простые правила';
    case RulesComplexity.normal:
      return 'Средние правила';
    case RulesComplexity.heavy:
      return 'Сложные правила';
  }
}

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
      color: Colors.grey.shade300,
      child: const Center(child: CircularProgressIndicator()),
    ),
    errorWidget: Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image),
    ),
  );
}

/// Экран игры (SP-E2-03).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameId,
    required this.scenarioId,
    required this.repository,
    this.slideImageBuilder = _defaultSlideImage,
  });

  /// ID игры (`game_public/{gameId}`).
  final String gameId;

  /// ID открытого сценария — контекст для краткого описания (AC-03).
  final String scenarioId;

  /// Источник данных `game_public` (A-11, A-38).
  final AggregateRepository repository;

  /// Фабрика виджета изображения слайда (тестируемость).
  final GameSlideImageBuilder slideImageBuilder;

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

  void _reload() {
    setState(() {
      _future = widget.repository.getGame(widget.gameId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Игра')),
      body: FutureBuilder<GamePublic?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error!);
          }
          final game = snapshot.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _GameContent(
            game: game,
            scenarioId: widget.scenarioId,
            slideImageBuilder: widget.slideImageBuilder,
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
          Text('Не удалось загрузить игру: $error'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _reload, child: const Text('Повторить')),
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
  });

  final GamePublic game;
  final String scenarioId;
  final GameSlideImageBuilder slideImageBuilder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
      children: [
        _Carousel(slices: game.carousel, imageBuilder: slideImageBuilder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.title, style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              _Characteristics(game: game),
              if (scenario != null) ...[
                const SizedBox(height: 16),
                Text(scenario.shortDescription, style: textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Карусель по `GamePublic.carousel` (AC-01, CR-5).
class _Carousel extends StatelessWidget {
  const _Carousel({required this.slices, required this.imageBuilder});

  final List<Slide> slices;
  final GameSlideImageBuilder imageBuilder;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: slices.length,
        itemBuilder: (context, index) {
          final slide = slices[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageBuilder(context, slide),
                  if (slide.alt != null && slide.alt!.isNotEmpty)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          slide.alt!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Четыре характеристики игры (AC-02, CR-4.1).
class _Characteristics extends StatelessWidget {
  const _Characteristics({required this.game});

  final GamePublic game;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      '${game.playersHint.uiLabel} игрок',
      durationBucketLabel(game.durationBucket),
      game.ageHint.uiLabel,
      rulesComplexityLabel(game.rulesComplexity),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels) Chip(label: Text(label)),
      ],
    );
  }
}
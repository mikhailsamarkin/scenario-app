// Widget-тесты экрана игры (SP-E2-03).
//
// Покрывают AC-01 (карусель с валидными слайдами и alt), AC-02 (четыре
// характеристики из контракта), AC-03 (краткое описание в контексте
// открытого сценария). Изображение слайдов подставляется заглушкой, чтобы
// не зависеть от плагина дискового кэша (cached_network_image).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scenario/data/contract/enums.dart';
import 'package:scenario/data/contract/models.dart';
import 'package:scenario/data/firestore/aggregate_repository_interface.dart';
import 'package:scenario/features/game/game_screen.dart';

/// Фейковый репозиторий, возвращающий заданную игру (A-38).
class _FakeRepository implements AggregateRepository {
  _FakeRepository(this._game);

  final GamePublic? _game;

  @override
  Future<GamePublic?> getGame(String gameId) async => _game;

  @override
  Future<HomeFeed?> getHomeFeed() async => null;

  @override
  Future<SemanticGroupPublic?> getSemanticGroup(String id) async => null;

  @override
  Future<ScenarioPublic?> getScenario(String scenarioId) async => null;

  @override
  Future<SitemapPublic?> getSitemap() async => null;
}

/// Заглушка изображения слайда — простой видимый дочерний виджет.
Widget _buildSlideImage(BuildContext context, Slide slide) {
  return ColoredBox(
    color: const Color(0xFF00FF00),
    child: Text('img:${slide.imageRef}'),
  );
}

GamePublic _buildGame({
  List<Slide>? carousel,
  List<GameScenarioRef>? scenarios,
}) {
  return GamePublic(
    id: 'g1',
    slug: 'dixit',
    title: 'Dixit',
    seoTitle: 'Dixit',
    seoDescription: 'Dixit описание',
    playersHint: PlayersHint.players24,
    durationBucket: DurationBucket.evening,
    ageHint: AgeHint.family,
    rulesComplexity: RulesComplexity.easy,
    carousel: carousel ??
        const [
          Slide(
            imageRef: 'games/g1/a.jpg',
            frameType: FrameType.teaser,
            alt: 'Альт кадра',
          ),
          Slide(imageRef: 'games/g1/b.jpg', frameType: FrameType.box),
        ],
    scenarios: scenarios ??
        const [
          GameScenarioRef(
            scenarioId: 's1',
            slug: 'vecherinka',
            title: 'Вечеринка',
            shortDescription: 'Описание в контексте вечеринки',
          ),
        ],
    contentVersion: 1,
    updatedAt: DateTime.utc(2026, 9, 7),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AC-01: карусель показывает слайды и alt где задано',
      (tester) async {
    final game = _buildGame();
    await tester.pumpWidget(_wrap(GameScreen(
      gameId: 'g1',
      scenarioId: 's1',
      repository: _FakeRepository(game),
      slideImageBuilder: _buildSlideImage,
    )));
    await tester.pump();

    // Первый слайд виден сразу (заглушка изображения) + alt где задано.
    expect(find.text('img:games/g1/a.jpg'), findsOneWidget);
    expect(find.text('Альт кадра'), findsOneWidget);
    // PageView содержит карусель.
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('AC-02: четыре характеристики из контракта', (tester) async {
    final game = _buildGame();
    await tester.pumpWidget(_wrap(GameScreen(
      gameId: 'g1',
      scenarioId: 's1',
      repository: _FakeRepository(game),
      slideImageBuilder: _buildSlideImage,
    )));
    await tester.pump();

    expect(find.text('2–4 игрок'), findsOneWidget);
    expect(find.text('На вечер'), findsOneWidget);
    expect(find.text('Семейные'), findsOneWidget);
    expect(find.text('Простые правила'), findsOneWidget);
  });

  testWidgets('AC-03: краткое описание в контексте открытого сценария',
      (tester) async {
    final game = _buildGame();
    await tester.pumpWidget(_wrap(GameScreen(
      gameId: 'g1',
      scenarioId: 's1',
      repository: _FakeRepository(game),
      slideImageBuilder: _buildSlideImage,
    )));
    await tester.pump();

    expect(find.text('Описание в контексте вечеринки'), findsOneWidget);
  });

  testWidgets('ED-9: описание из другого сценария не подставляется',
      (tester) async {
    final game = _buildGame();
    await tester.pumpWidget(_wrap(GameScreen(
      gameId: 'g1',
      scenarioId: 'drugoy',
      repository: _FakeRepository(game),
      slideImageBuilder: _buildSlideImage,
    )));
    await tester.pump();

    expect(find.text('Описание в контексте вечеринки'), findsNothing);
  });

  testWidgets('AC-02: офлайн без кэша — состояние «нет сети»', (tester) async {
    await tester.pumpWidget(_wrap(GameScreen(
      gameId: 'g1',
      scenarioId: 's1',
      repository: _FakeRepository(null),
      slideImageBuilder: _buildSlideImage,
      isOffline: true,
    )));
    await tester.pump();

    expect(find.text('Нет сети. Проверьте подключение.'), findsOneWidget);
  });

  testWidgets('AC-01: офлайн с кэшем — данные рендерятся без ошибки',
      (tester) async {
    final game = _buildGame();
    await tester.pumpWidget(_wrap(GameScreen(
      gameId: 'g1',
      scenarioId: 's1',
      repository: _FakeRepository(game),
      slideImageBuilder: _buildSlideImage,
      isOffline: true,
    )));
    await tester.pump();

    // Данные из кэша отображаются, ошибки нет.
    expect(find.text('Dixit'), findsOneWidget);
    expect(find.text('Нет сети. Проверьте подключение.'), findsNothing);
  });
}
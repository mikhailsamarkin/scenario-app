// Главный экран (SP-E2-01, редизайн SP-E9-01): брендированная шапка,
// витрина горизонтальной лентой крупных фото-карточек, группы смысла —
// секциями (US-E7-01/02). Порядок и состав — с сервера (AC-01);
// переходы — через инжектируемые колбэки. Вёрстка — по
// docs/figma/screens/home.md.

import 'package:flutter/material.dart';

import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/widgets.dart';

/// Открывает экран сценария (US-E2-02).
typedef HomeOpenScenario = void Function(BuildContext context, String scenarioId);

/// Открывает экран группы смысла (US-E7-01).
typedef HomeOpenGroup =
    void Function(BuildContext context, String groupId, bool isPastArchive);

/// Открывает экран «О приложении» (US-E6-04).
typedef HomeOpenAbout = void Function(BuildContext context);

/// Главный экран (SP-E2-01, SP-E9-01).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.onOpenScenario,
    this.onOpenGroup,
    this.onOpenAbout,
    this.isOffline = false,
  });

  /// Источник данных `home_feed/main` (A-11, A-38).
  final AggregateRepository repository;

  /// Переход на экран сценария (US-E2-02).
  final HomeOpenScenario onOpenScenario;

  /// Переход на экран группы смысла (US-E7-01).
  final HomeOpenGroup? onOpenGroup;

  /// Переход на экран «О приложении» (US-E6-04).
  final HomeOpenAbout? onOpenAbout;

  /// Офлайн-режим: при отсутствии кэша показать «нет сети» (AC-02).
  final bool isOffline;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<HomeFeed?> _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = widget.repository.getHomeFeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Фоновое обновление при возврате приложения в активное состояние
  /// (AC-02, A-22): при сети подтягиваются свежие данные.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = widget.repository.getHomeFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: FutureBuilder<HomeFeed?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error!);
          }
          final feed = snapshot.data;
          if (feed == null) {
            // Офлайн без кэша — понятное состояние «нет сети» (AC-02).
            if (widget.isOffline) {
              return _messageScreen('Нет сети. Проверьте подключение.');
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _HomeContent(
            feed: feed,
            onOpenScenario: widget.onOpenScenario,
            onOpenGroup: widget.onOpenGroup,
            onOpenAbout: widget.onOpenAbout,
          );
        },
      ),
    );
  }

  Widget _errorState(Object error) {
    return _messageScreen(
      'Не удалось загрузить витрину',
      action: FilledButton(
        onPressed: _reload,
        child: const Text('Повторить'),
      ),
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

/// Шапка-брендблок: тонкая верхняя полоса, фиолетовая подложка, логотип,
/// заголовок и подзаголовок (docs/figma/screens/home.md).
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.onOpenAbout});

  final HomeOpenAbout? onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 6, color: AppColors.headerPlum),
        Container(
          color: AppColors.headerPurple,
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Scenario', style: AppTypography.logo)),
                  if (onOpenAbout != null)
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: AppColors.textMutedOnDark,
                      ),
                      tooltip: 'О приложении',
                      onPressed: () => onOpenAbout!(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Что сегодня?', style: AppTypography.displayOnDark),
              const SizedBox(height: 4),
              const Text(
                'Выберите сценарий — получите игру',
                style: AppTypography.subtitleOnDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.feed,
    required this.onOpenScenario,
    this.onOpenGroup,
    this.onOpenAbout,
  });

  final HomeFeed feed;
  final HomeOpenScenario onOpenScenario;
  final HomeOpenGroup? onOpenGroup;
  final HomeOpenAbout? onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final activeGroups = feed.groups.where((g) => !g.isPastArchive).toList();
    final pastGroups = feed.groups.where((g) => g.isPastArchive).toList();
    if (feed.vitrine.isEmpty && feed.groups.isEmpty) {
      return _scrollable([
        const _BrandHeader(),
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Пока нет сценариев')),
        ),
      ]);
    }
    return _scrollable([
      _BrandHeader(onOpenAbout: onOpenAbout),
      // Витрина (AC-01) — «Редакторский выбор» (константа UI, SP-E9-01).
      if (feed.vitrine.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Витрина',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnLight,
                  ),
                ),
              ),
              const CapsHeader('Редакторский выбор', color: AppColors.terracotta),
            ],
          ),
        ),
        SizedBox(
          height: 356,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: feed.vitrine.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final card = feed.vitrine[index];
              return ScenarioPhotoCard.large(
                title: card.title,
                imageRef: card.imageRef,
                onTap: () => onOpenScenario(context, card.scenarioId),
              );
            },
          ),
        ),
      ],
      // Активные группы смысла (US-E7-01, БТ §7.1) — секциями.
      for (final group in activeGroups) _GroupSection(
        group: group,
        onOpenGroup: onOpenGroup,
      ),
      // «Сценарии прошлого» (US-E7-02, CR-3).
      if (pastGroups.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
          child: const Text(
            'Сценарии прошлого',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnLight,
            ),
          ),
        ),
      for (final group in pastGroups)
        _GroupSection(group: group, onOpenGroup: onOpenGroup),
      const SizedBox(height: 32),
    ]);
  }

  Widget _scrollable(List<Widget> children) {
    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

/// Секция группы смысла: заголовок + компактная карточка группы,
/// открывающая экран группы (состав группы — на экране группы, без N+1).
class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.onOpenGroup});

  final GroupRef group;
  final HomeOpenGroup? onOpenGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            group.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnLight,
            ),
          ),
          const SizedBox(height: 12),
          ScenarioPhotoCard.compact(
            key: ValueKey('home_group_${group.semanticGroupId}'),
            title: group.title,
            onTap: () =>
                onOpenGroup?.call(context, group.semanticGroupId, group.isPastArchive),
          ),
        ],
      ),
    );
  }
}

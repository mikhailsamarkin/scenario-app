// Главный экран (SP-E2-01): витрина сценариев из `home_feed/main`
// (FR-M-1, A-12). Название и опциональный подзаголовок (AC-02), порядок
// и состав с сервера (AC-01). Переход на экран сценария (US-E2-02) —
// через инжектируемый колбэк для тестируемости.

import 'package:flutter/material.dart';

import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../supabase_config.dart';

/// Открывает экран сценария (US-E2-02).
typedef HomeOpenScenario = void Function(BuildContext context, String scenarioId);

/// Открывает экран группы смысла (US-E7-01).
typedef HomeOpenGroup =
    void Function(BuildContext context, String groupId, bool isPastArchive);

/// Открывает экран «О приложении» (US-E6-04).
typedef HomeOpenAbout = void Function(BuildContext context);

/// Главный экран (SP-E2-01).
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
      appBar: AppBar(
        title: const Text('Сценарии'),
        actions: [
          if (widget.onOpenAbout != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'О приложении',
              onPressed: () {
                widget.onOpenAbout!(context);
              },
            ),
        ],
      ),
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
              return const Center(child: Text('Нет сети. Проверьте подключение.'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _HomeContent(
            feed: feed,
            onOpenScenario: widget.onOpenScenario,
            onOpenGroup: widget.onOpenGroup,
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
          Text('Не удалось загрузить витрину: $error'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _reload, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.feed,
    required this.onOpenScenario,
    this.onOpenGroup,
  });

  final HomeFeed feed;
  final HomeOpenScenario onOpenScenario;
  final HomeOpenGroup? onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeGroups = feed.groups.where((g) => !g.isPastArchive).toList();
    final pastGroups = feed.groups.where((g) => g.isPastArchive).toList();
    if (feed.vitrine.isEmpty && feed.groups.isEmpty) {
      return const Center(child: Text('Пока нет сценариев'));
    }
    return ListView(
      children: [
        // Витрина (AC-01).
        if (feed.vitrine.isNotEmpty)
          ListTile(
            title: Text('Витрина', style: textTheme.titleLarge),
            subtitle: Text('Редакторский выбор'),
          ),
        for (final card in feed.vitrine)
          _ScenarioCardTile(
            card: card,
            onOpenScenario: onOpenScenario,
          ),
        // Активные группы смысла (US-E7-01, БТ §7.1).
        if (activeGroups.isNotEmpty)
          ListTile(
            title: Text('Подборки', style: textTheme.titleLarge),
          ),
        for (final group in activeGroups)
          _GroupTile(
            group: group,
            onOpenGroup: onOpenGroup,
          ),
        // «Сценарии прошлого» (US-E7-02, CR-3).
        if (pastGroups.isNotEmpty)
          ListTile(
            title: Text('Сценарии прошлого', style: textTheme.titleLarge),
          ),
        for (final group in pastGroups)
          _GroupTile(
            group: group,
            onOpenGroup: onOpenGroup,
          ),
      ],
    );
  }
}

/// Карточка группы смысла на главном экране (US-E7-01).
class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onOpenGroup});

  final GroupRef group;
  final HomeOpenGroup? onOpenGroup;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(group.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onOpenGroup?.call(context, group.semanticGroupId, group.isPastArchive);
      },
    );
  }
}

/// Карточка сценария на главном экране (AC-02).
class _ScenarioCardTile extends StatelessWidget {
  const _ScenarioCardTile({required this.card, required this.onOpenScenario});

  final ScenarioCard card;
  final HomeOpenScenario onOpenScenario;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(card.title),
      subtitle: card.subtitle == null ? null : Text(card.subtitle!),
      leading: card.imageRef == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image.network(
                  supabasePublicUrl(card.imageRef!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
      onTap: () {
        onOpenScenario(context, card.scenarioId);
      },
    );
  }
}
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

/// Главный экран (SP-E2-01).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.onOpenScenario,
    this.isOffline = false,
  });

  /// Источник данных `home_feed/main` (A-11, A-38).
  final AggregateRepository repository;

  /// Переход на экран сценария (US-E2-02).
  final HomeOpenScenario onOpenScenario;

  /// Офлайн-режим: при отсутствии кэша показать «нет сети» (AC-02).
  final bool isOffline;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeFeed?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getHomeFeed();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.getHomeFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сценарии')),
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
          return _HomeContent(feed: feed, onOpenScenario: widget.onOpenScenario);
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
  const _HomeContent({required this.feed, required this.onOpenScenario});

  final HomeFeed feed;
  final HomeOpenScenario onOpenScenario;

  @override
  Widget build(BuildContext context) {
    if (feed.vitrine.isEmpty) {
      return const Center(child: Text('Пока нет сценариев'));
    }
    return ListView.builder(
      itemCount: feed.vitrine.length,
      itemBuilder: (context, index) {
        final card = feed.vitrine[index];
        return _ScenarioCardTile(
          card: card,
          onOpenScenario: onOpenScenario,
        );
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
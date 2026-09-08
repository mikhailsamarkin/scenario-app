// Экран группы смысла (SP-E7-01, БТ §7.1).
//
// Читает `semantic_groups_public/{id}` через `AggregateRepository` (A-11,
// A-38). Показывает сценарии группы; переход на сценарий — через
// инжектируемый колбэк `onOpenScenario` для тестируемости.

import 'package:flutter/material.dart';

import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../supabase_config.dart';

/// Открывает экран сценария (US-E2-02).
typedef GroupOpenScenario = void Function(BuildContext context, String scenarioId);

/// Экран группы смысла (SP-E7-01).
class GroupScreen extends StatefulWidget {
  const GroupScreen({
    super.key,
    required this.groupId,
    required this.repository,
    required this.onOpenScenario,
    this.isOffline = false,
  });

  /// ID группы (`semantic_groups_public/{id}`).
  final String groupId;

  /// Источник данных `semantic_groups_public` (A-11, A-38).
  final AggregateRepository repository;

  /// Переход на экран сценария (US-E2-02).
  final GroupOpenScenario onOpenScenario;

  /// Офлайн-режим: при отсутствии кэша показать «нет сети» (AC-02).
  final bool isOffline;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Future<SemanticGroupPublic?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getSemanticGroup(widget.groupId);
  }

  void _reload() {
    setState(() {
      _future = widget.repository.getSemanticGroup(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подборка')),
      body: FutureBuilder<SemanticGroupPublic?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error!);
          }
          final group = snapshot.data;
          if (group == null) {
            if (widget.isOffline) {
              return const Center(child: Text('Нет сети. Проверьте подключение.'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _GroupContent(group: group, onOpenScenario: widget.onOpenScenario);
        },
      ),
    );
  }

  Widget _errorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Не удалось загрузить подборку: $error'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _reload, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _GroupContent extends StatelessWidget {
  const _GroupContent({required this.group, required this.onOpenScenario});

  final SemanticGroupPublic group;
  final GroupOpenScenario onOpenScenario;

  @override
  Widget build(BuildContext context) {
    if (group.scenarios.isEmpty) {
      return const Center(child: Text('Пока нет сценариев'));
    }
    return Scaffold(
      appBar: AppBar(title: Text(group.title)),
      body: ListView.builder(
        itemCount: group.scenarios.length,
        itemBuilder: (context, index) {
          final card = group.scenarios[index];
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
        },
      ),
    );
  }
}
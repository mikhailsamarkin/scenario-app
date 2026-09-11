// Экран группы смысла (SP-E7-01, редизайн SP-E9-01): сетка компактных
// фото-карточек сценариев группы на кремовом фоне.
//
// Читает `semantic_groups_public/{id}` через `AggregateRepository` (A-11,
// A-38). Переход на сценарий — через инжектируемый колбэк `onOpenScenario`
// (с hero-фото карточки для экрана сценария).

import 'package:flutter/material.dart';

import '../../data/contract/models.dart';
import '../../data/firestore/aggregate_repository_interface.dart';
import '../../design/app_colors.dart';
import '../../design/widgets.dart';

/// Открывает экран сценария (US-E2-02).
typedef GroupOpenScenario = void Function(BuildContext context, String scenarioId);

/// Экран группы смысла (SP-E7-01, SP-E9-01).
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
      backgroundColor: AppColors.bgCream,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: CapsHeader(group.title),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 176 / 256,
            ),
            itemCount: group.scenarios.length,
            itemBuilder: (context, index) {
              final card = group.scenarios[index];
              return Center(
                child: ScenarioPhotoCard.compact(
                  title: card.title,
                  imageRef: card.imageRef,
                  onTap: () => onOpenScenario(context, card.scenarioId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

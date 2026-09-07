// Онбординг первого запуска (SP-E3-01): объясняет модель «ситуация → игры»
// (UJ-4, A-17). Запрос push опционален; отказ не блокирует переход к
// витрине (AC-02). После завершения вызывается onCompleted.

import 'package:flutter/material.dart';

/// Колбэк завершения онбординга (переход к витрине).
typedef OnboardingCompleted = void Function(BuildContext context);

/// Шаг онбординга: заголовок + текст.
class _OnboardingStep {
  const _OnboardingStep(this.title, this.body);

  final String title;
  final String body;
}

const List<_OnboardingStep> _STEPS = const [
  _OnboardingStep(
    'Выберите ситуацию',
    'Сценарий — это ситуация: «Вечеринка», «Семейный вечер», «В поездку».',
  ),
  _OnboardingStep(
    'Получите подборку игр',
    'Для каждой ситуации мы подобрали игры, которые подходят именно ей.',
  ),
  _OnboardingStep(
    'Выбирайте и играйте',
    'Смотрите карусель, характеристики и описание — и решайте без жаргона.',
  ),
];

/// Экран онбординга (SP-E3-01).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    this.askPush = true,
  });

  /// Переход к витрине после завершения.
  final OnboardingCompleted onCompleted;

  /// Показывать ли шаг запроса push (опционально).
  final bool askPush;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  bool get _isLastValueStep => _step == _STEPS.length - 1;

  bool get _isPushStep => widget.askPush && _step == _STEPS.length;

  bool get _isDone => _step > _STEPS.length;

  void _next() {
    setState(() {
      _step++;
    });
  }

  void _finish(BuildContext context) {
    widget.onCompleted(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final String title;
    final String body;
    if (_isPushStep) {
      title = 'Уведомления о новинках';
      body = 'Разрешите уведомления, чтобы узнавать о новых сценариях. '
          'Это не обязательно.';
    } else {
      title = _STEPS[_step].title;
      body = _STEPS[_step].body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Добро пожаловать')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: textTheme.headlineMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              child: Text(body, style: textTheme.bodyLarge),
            ),
            const SizedBox(height: 24),
            if (_isPushStep) ...[
              FilledButton(
                onPressed: () {
                  _finish(context);
                },
                child: const Text('Разрешить'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _finish(context);
                },
                child: const Text('Позже'),
              ),
            ] else ...[
              FilledButton(
                onPressed: _next,
                child: Text(_isLastValueStep ? 'Далее' : 'Далее'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _finish(context);
                },
                child: const Text('Пропустить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
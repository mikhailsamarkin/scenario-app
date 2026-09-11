// Онбординг первого запуска (SP-E3-01, редизайн SP-E9-01): три шага
// (два ценностных + шаг запроса push с явным выбором). Запрос push
// опционален; отказ не блокирует переход к витрине (AC-02). После
// завершения вызывается onCompleted. Вёрстка — по docs/figma/screens/onboarding.md.

import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/widgets.dart';

/// Колбэк завершения онбординга (переход к витрине).
typedef OnboardingCompleted = void Function(BuildContext context);

/// Колбэк «Разрешить уведомления» (подписка на topic, US-E3-02).
typedef OnboardingAllowPush = Future<void> Function();

/// Шаг онбординга: надзаголовок, заголовок, текст.
class _OnboardingStep {
  const _OnboardingStep(this.overline, this.title, this.body);

  final String overline;
  final String title;
  final String body;
}

const List<_OnboardingStep> _steps = [
  _OnboardingStep(
    'Как это работает',
    'Выбери ситуацию — получи игру',
    'Не знаете, в какую игру сыграть? Просто выберите подходящий момент — '
        'а мы подберём под него настольную игру.',
  ),
  _OnboardingStep(
    'Экспертные подборки',
    'Подборки от людей, а не алгоритмов',
    'Каждый сценарий — это выбор редакторов, которые играют в настолки '
        'каждую неделю. Никаких рейтингов по кликам.',
  ),
];

/// Экран онбординга (SP-E3-01, SP-E9-01).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    this.onAllowPush,
    this.askPush = true,
  });

  /// Переход к витрине после завершения.
  final OnboardingCompleted onCompleted;

  /// Подписка на уведомления при «Разрешить» (US-E3-02).
  final OnboardingAllowPush? onAllowPush;

  /// Показывать ли шаг запроса push (опционально).
  final bool askPush;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  /// Всего шагов: два ценностных + опциональный шаг push.
  int get _totalSteps => _steps.length + (widget.askPush ? 1 : 0);

  bool get _isPushStep => widget.askPush && _step == _steps.length;

  bool get _isLastStep => _step == _totalSteps - 1;

  void _next() {
    setState(() {
      _step++;
    });
  }

  void _finish() {
    widget.onCompleted(context);
  }

  Future<void> _allowPush() async {
    await widget.onAllowPush?.call();
    if (mounted) {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _OnboardingStep step;
    if (_isPushStep) {
      step = const _OnboardingStep(
        'Будьте в курсе',
        'Новые сценарии — в уведомлениях',
        'Каждую неделю — новый сценарий. Разрешите уведомления, чтобы '
            'узнавать первыми.',
      );
    } else {
      step = _steps[_step];
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 24,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Пропустить',
                  style: TextStyle(color: AppColors.textMutedOnDark),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DotsIndicator(
                      count: _totalSteps,
                      activeIndex: _step,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      step.overline.toUpperCase(),
                      style: AppTypography.caps(),
                    ),
                    const SizedBox(height: 12),
                    Text(step.title, style: AppTypography.onboardingTitle),
                    const SizedBox(height: 12),
                    Text(step.body, style: AppTypography.onboardingBody),
                    const SizedBox(height: 28),
                    if (_isPushStep) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _allowPush,
                          child: const Text('Разрешить уведомления'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.buttonDark,
                            foregroundColor: AppColors.textOnDark,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Начать без уведомлений'),
                        ),
                      ),
                    ] else if (_isLastStep) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _finish,
                          child: const Text('Начать'),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          child: const Text('Далее'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

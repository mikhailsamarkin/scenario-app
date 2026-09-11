// Общие виджеты дизайн-системы (SP-E9-01) по docs/figma: hero-блок,
// капс-заголовок секции, точки-индикаторы, фото-карточки сценария,
// карточка игры, плитка характеристики, пилюля-кнопка.

import 'package:flutter/material.dart';

import '../cache/cached_network_image_widget.dart';
import '../supabase_config.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Фото hero-блока во всю ширину: затемнение снизу, слоты капс-надписи,
/// заголовка, кнопки «назад» и произвольного наполнения (точки карусели).
class HeroBlock extends StatelessWidget {
  const HeroBlock({
    super.key,
    this.imageRef,
    required this.height,
    this.category,
    this.title,
    this.titleStyle = AppTypography.displayOnPhoto,
    this.onBack,
    this.overlayChild,
    this.bottomContent,
  });

  /// Ссылка на фото в Supabase Storage; null — тёмный плейсхолдер.
  final String? imageRef;

  /// Высота hero-блока.
  final double height;

  /// Капс-надпись над заголовком (категория сценария).
  final String? category;

  /// Заголовок поверх фото.
  final String? title;

  /// Стиль заголовка.
  final TextStyle titleStyle;

  /// Колбэк кнопки «назад»; null — кнопка не показывается.
  final VoidCallback? onBack;

  /// Дополнительный слой поверх фото (например, точки карусели).
  final Widget? overlayChild;

  /// Контент под заголовком (внутри затемнённой зоны).
  final Widget? bottomContent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _photo(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1.0],
                colors: AppColors.heroGradient,
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              top: 12,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                ),
              ),
            ),
          if (overlayChild != null) ?overlayChild,
          if (category != null || title != null || bottomContent != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category != null) ...[
                    Text(category!, style: AppTypography.cardCategoryOnPhoto),
                    const SizedBox(height: 6),
                  ],
                  if (title != null)
                    Text(title!, style: titleStyle, maxLines: 2),
                  ?bottomContent,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _photo() {
    final ref = imageRef;
    if (ref == null || ref.isEmpty) {
      return Container(color: AppColors.bgDark);
    }
    return CachedNetworkImageWidget(
      url: supabasePublicUrl(ref),
      fit: BoxFit.cover,
      placeholder: Container(color: AppColors.bgDark),
      errorWidget: Container(color: AppColors.bgDark),
    );
  }
}

/// Капс-заголовок секции («В ПОДБОРКЕ · 3 ИГРЫ», «КРАТКО»).
class CapsHeader extends StatelessWidget {
  const CapsHeader(this.text, {super.key, this.color = AppColors.textOnLight});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTypography.caps(color: color));
  }
}

/// Точки-индикаторы (онбординг, карусель): активная — удлинённая
/// терракотовая пилюля, неактивные — серые точки.
class DotsIndicator extends StatelessWidget {
  const DotsIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == activeIndex ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? AppColors.terracotta
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}

/// Фото-карточка сценария (витрина home — large, ленты групп — compact).
class ScenarioPhotoCard extends StatelessWidget {
  const ScenarioPhotoCard({
    super.key,
    required this.title,
    required this.width,
    required this.height,
    this.imageRef,
    this.category,
    this.onTap,
  });

  /// Крупная карточка витрины.
  const ScenarioPhotoCard.large({
    super.key,
    required this.title,
    this.imageRef,
    this.onTap,
  })  : width = 240,
        height = 340,
        category = null;

  /// Компактная карточка ленты группы.
  const ScenarioPhotoCard.compact({
    super.key,
    required this.title,
    this.imageRef,
    this.onTap,
  })  : width = 176,
        height = 256,
        category = null;

  final String title;
  final String? imageRef;
  final String? category;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _photo(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: AppColors.heroGradient,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category != null) ...[
                      Text(category!, style: AppTypography.cardCategoryOnPhoto),
                      const SizedBox(height: 4),
                    ],
                    Text(title, style: AppTypography.cardTitleOnPhoto),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    final ref = imageRef;
    if (ref == null || ref.isEmpty) {
      return Container(color: AppColors.bgDark);
    }
    return CachedNetworkImageWidget(
      url: supabasePublicUrl(ref),
      fit: BoxFit.cover,
      placeholder: Container(color: AppColors.bgDark),
      errorWidget: Container(color: AppColors.bgDark),
    );
  }
}

/// Карточка игры в списке сценария: светло-лавандовая плашка с фото-превью,
/// названием, чипсами характеристик и шевроном.
class GameListCard extends StatelessWidget {
  const GameListCard({
    super.key,
    required this.title,
    required this.chips,
    this.imageRef,
    this.onTap,
  });

  final String title;
  final List<String> chips;
  final String? imageRef;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLavender,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _thumb(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitleOnLight),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final chip in chips)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.chipLavender,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              chip,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textOnLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMutedOnLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() {
    final ref = imageRef;
    if (ref == null || ref.isEmpty) {
      return Container(color: AppColors.chipLavender);
    }
    return CachedNetworkImageWidget(
      url: supabasePublicUrl(ref),
      fit: BoxFit.cover,
      placeholder: Container(color: AppColors.chipLavender),
      errorWidget: Container(color: AppColors.chipLavender),
    );
  }
}

/// Плитка характеристики («КРАТКО», сетка 2×2): иконка + подпись сверху,
/// значение снизу.
class CharacteristicTile extends StatelessWidget {
  const CharacteristicTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLavender,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textMutedOnLight),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMutedOnLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Пилюля-кнопка («Поделиться», бейдж caption на фото карусели).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.background = Colors.white,
    this.borderColor = AppColors.chipLavender,
  });

  /// Бейдж на фото (полупрозрачный тёмный, без рамки).
  const PillButton.photoBadge({super.key, required this.child})
      : onPressed = null,
        background = Colors.black45,
        borderColor = Colors.transparent;

  final VoidCallback? onPressed;
  final Widget child;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

// Обёртка кэшируемого изображения поверх `cached_network_image` (ADR-004–009).
//
// Единая точка отображения сетевых изображений (Supabase Storage, ED-14).
// Управляет кэшем по числу объектов (вариант B, maxNrOfCacheObjects) и
// политикой LRU (A-21a, NFR-SR-6). Контракт данных не затрагивается:
// публичный URL строится из `Slide.imageRef` через `supabasePublicUrl` (A-39).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Предел числа объектов в дисковом кэше изображений (вариант B, ADR-004–009).
const int kImageCacheMaxObjects = 200;

/// Общий менеджер дискового кэша изображений (A-21a, NFR-SR-6).
///
/// Лимит — по числу объектов (вариант B), а не по байтам. Один менеджер на
/// приложение: повторное открытие отдаётся из кэша без сетевого запроса.
final CacheManager scenarioImageCacheManager = CacheManager(
  Config(
    'scenario_images',
    maxNrOfCacheObjects: kImageCacheMaxObjects,
    stalePeriod: const Duration(days: 30),
  ),
);

/// Виджет кэшируемого сетевого изображения.
///
/// Показывает [placeholder] во время загрузки и [errorWidget] при ошибке,
/// затем изображение из дискового кэша (повторное открытие без сетевого
/// запроса — AC-01). Параметры [fit] и [width]/[height] транслируются в
/// `CachedNetworkImage`.
class CachedNetworkImageWidget extends StatelessWidget {
  const CachedNetworkImageWidget({
    super.key,
    required this.url,
    required this.placeholder,
    required this.errorWidget,
    this.fit,
    this.width,
    this.height,
  });

  /// Публичный URL изображения (Supabase Storage, A-39).
  final String url;

  /// Виджет состояния загрузки.
  final Widget placeholder;

  /// Виджет состояния ошибки.
  final Widget errorWidget;

  final BoxFit? fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: scenarioImageCacheManager,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => errorWidget,
    );
  }
}
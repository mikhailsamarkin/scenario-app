// Реестр имён событий аналитики (SP-E6-01, A-35).
//
// Единая точка имён событий GA4 — без произвольных строк в коде (AC-01).
// Имена в snake_case по A-35.

/// Просмотр экрана.
const String kEventScreenView = 'screen_view';

/// Открытие сценария.
const String kEventScenarioOpen = 'scenario_open';

/// Открытие игры.
const String kEventGameOpen = 'game_open';

/// Попытка шаринга (US-E5-04).
const String kEventShareAttempt = 'share_attempt';

/// Успешный шаринг (US-E5-04).
const String kEventShareSuccess = 'share_success';

/// Отмена шаринга (US-E5-04).
const String kEventShareDismissed = 'share_dismissed';

/// Параметр: id сценария.
const String kParamScenarioId = 'scenario_id';

/// Параметр: id игры.
const String kParamGameId = 'game_id';

/// Параметр: источник (home, push, deeplink, share).
const String kParamSource = 'source';

/// Параметр: id блока (block_view, US-E6-03).
const String kParamBlockId = 'block_id';

/// Имя события: достижение блока (A-35(3), US-E6-03).
const String kEventBlockView = 'block_view';

/// Идентификаторы именованных блоков экранов (US-E6-03, A-35).
///
/// Стабильны и согласованы с разметкой экранов E2.

/// Блок «почему эти игры подходят» на экране сценария.
const String kBlockScenarioWhy = 'scenario_why';

/// Список игр на экране сценария.
const String kBlockScenarioGames = 'scenario_games';

/// Карусель на экране игры.
const String kBlockGameCarousel = 'game_carousel';

/// Характеристики на экране игры.
const String kBlockGameCharacteristics = 'game_characteristics';

/// Источник открытия сценария (SP-E6-02, A-35).
///
/// Значения соответствуют use-cases §6.2; без произвольных строк (AC-01).
enum ScenarioOpenSource {
  home('home'),
  group('group'),
  past('past'),
  push('push'),
  deeplink('deeplink'),
  share('share');

  const ScenarioOpenSource(this.storageKey);

  /// Ключ параметра `source` в событии.
  final String storageKey;
}
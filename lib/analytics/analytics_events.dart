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
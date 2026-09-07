// Модуль очереди уведомлений (SP-E1-05, шаг 2).
//
// Определяет «первую публикацию» сценария (A-31/A-33) и собирает/валидирует
// единую запись очереди pending_notifications/daily (A-7a, A-31, ED-11).
//
// Экспортирует:
//   isFirstPublication(previous, next) -> boolean
//   buildDailyQueueRecord(scenarioId, updatedAt) -> {lastScenarioId, updatedAt}
//   validateQueueRecord(record) -> {ok, errors[]}
//
// Не выполняет запись в Firestore.

// Обязательные поля записи очереди (A-31, ED-11; JSON Schema в контракте).
export const QUEUE_REQUIRED_FIELDS = Object.freeze(['lastScenarioId', 'updatedAt']);

// Определяет, является ли запись сценария «первой публикацией» (A-31/A-33):
// событие создаётся, когда сценарий переходит в published: true из состояния
// «не опубликован» — документ отсутствует (первичная публикация) или
// previous.published !== true (переход из черновика). Если сценарий уже был
// опубликован (републикация, в т.ч. правка только состава игр) — false (A-33).
export function isFirstPublication(previous, next) {
  if (typeof next !== 'object' || next === null) return false;
  if (next.published !== true) return false;
  if (typeof previous !== 'object' || previous === null) return true;
  return previous.published !== true;
}

// Собирает единую запись очереди pending_notifications/daily (A-31, A-7a):
// перезапись последней публикации за сутки.
export function buildDailyQueueRecord(scenarioId, updatedAt) {
  return { lastScenarioId: scenarioId, updatedAt };
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

// Валидирует запись очереди по схеме контракта (ED-11, TC-03).
export function validateQueueRecord(record) {
  const errors = [];
  if (typeof record !== 'object' || record === null || Array.isArray(record)) {
    return { ok: false, errors: ['запись очереди: ожидается JSON-объект'] };
  }
  for (const field of QUEUE_REQUIRED_FIELDS) {
    if (!isNonEmptyString(record[field])) {
      errors.push(`${field}: обязательное непустое значение`);
    }
  }
  return { ok: errors.length === 0, errors };
}

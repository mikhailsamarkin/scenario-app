// Валидатор группы смысла (SP-E7-01, БТ §7.1).
//
// Проверяет фикстуру группы: обязательные поля (id, title, slug), список
// сценариев (ScenarioCard), ссылочную целостность. Экспортирует
// validateGroup(json, knownScenarioIds) -> {ok, errors[]} и run() для CLI.

import { readFileSync, existsSync } from 'node:fs';

export const REQUIRED_GROUP_FIELDS = Object.freeze(['id', 'title', 'slug']);

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isPlainText(value) {
  return typeof value === 'string' && !/(\*\*|__|`|\[[^\]]*\]\([^)]*\)|^#{1,6}\s)/m.test(value);
}

function validateScenarioCard(card, index, knownScenarioIds, errors) {
  const prefix = `scenarios[${index}]`;
  if (typeof card !== 'object' || card === null || Array.isArray(card)) {
    errors.push(`${prefix}: ожидается объект карточки сценария`);
    return;
  }
  if (!isNonEmptyString(card.scenarioId)) {
    errors.push(`${prefix}.scenarioId: обязательное непустое значение`);
  } else if (knownScenarioIds && !knownScenarioIds.includes(card.scenarioId)) {
    errors.push(`${prefix}.scenarioId: сценарий "${card.scenarioId}" не найден`);
  }
  if (!isNonEmptyString(card.slug)) {
    errors.push(`${prefix}.slug: обязательное непустое значение`);
  }
  if (!isNonEmptyString(card.title)) {
    errors.push(`${prefix}.title: обязательное непустое значение`);
  }
  if (card.subtitle !== undefined && !isPlainText(card.subtitle)) {
    errors.push(`${prefix}.subtitle: plain text, без Markdown/HTML (A-4a)`);
  }
}

export function validateGroup(json, knownScenarioIds = null) {
  const errors = [];

  if (typeof json !== 'object' || json === null || Array.isArray(json)) {
    return { ok: false, errors: ['группа: ожидается JSON-объект'] };
  }

  for (const field of REQUIRED_GROUP_FIELDS) {
    if (!isNonEmptyString(json[field])) {
      errors.push(`${field}: обязательное поле`);
    }
  }
  if (json.title !== undefined && !isPlainText(json.title)) {
    errors.push('title: plain text, без Markdown/HTML (A-4a)');
  }
  if (json.listOrder !== undefined && (!Number.isInteger(json.listOrder) || json.listOrder < 1)) {
    errors.push('listOrder: целое число ≥ 1');
  }
  if (json.isPastArchive !== undefined && typeof json.isPastArchive !== 'boolean') {
    errors.push('isPastArchive: ожидается boolean');
  }

  if (!Array.isArray(json.scenarios)) {
    errors.push('scenarios: обязательный массив карточек сценариев');
  } else {
    const seen = new Set();
    json.scenarios.forEach((card, i) => {
      validateScenarioCard(card, i, knownScenarioIds, errors);
      if (card && isNonEmptyString(card.scenarioId)) {
        if (seen.has(card.scenarioId)) {
          errors.push(`scenarios: сценарий "${card.scenarioId}" дублируется`);
        }
        seen.add(card.scenarioId);
      }
    });
  }

  return { ok: errors.length === 0, errors };
}

// CLI: node validate-group.mjs <file.json> [--json]
export function run(argv = process.argv.slice(2)) {
  const file = argv.find((a) => !a.startsWith('--'));
  const asJson = argv.includes('--json');
  if (!file) {
    console.error('Использование: node validate-group.mjs <group.json> [--json]');
    process.exit(2);
  }
  if (!existsSync(file)) {
    console.error(`Файл не найден: ${file}`);
    process.exit(2);
  }
  let json;
  try {
    json = JSON.parse(readFileSync(file, 'utf8'));
  } catch (err) {
    console.error(`Ошибка чтения/парсинга ${file}: ${err.message}`);
    process.exit(2);
  }
  const result = validateGroup(json);
  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    for (const e of result.errors) console.error(`  - ${e}`);
    console.log(result.ok ? 'OK' : `FAIL (${result.errors.length} ошибок)`);
  }
  process.exit(result.ok ? 0 : 1);
}

// Позволяет запускать как CLI, так и импортировать как модуль.
if (import.meta.main) {
  run();
}
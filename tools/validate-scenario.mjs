// Валидатор сценария и связок сценарий–игра (SP-E1-03, шаг 3).
//
// Проверяет документ сценария перед записью:
//   - обязательные поля сценария (id, slug, title, whyTheseGames);
//   - тексты — plain text, без Markdown/HTML (A-4a);
//   - связки games[]: обязательные gameId/order/shortDescription;
//   - order — целое ≥ 1, уникально в пределах сценария (CR-4, AC-01);
//   - отсутствие дублей пар {gameId};
//   - shortDescription — plain text (A-4a);
//   - ссылочная целостность: gameId входит в knownGameIds (если передан).
//
// Экспортирует validateScenario(json, knownGameIds) -> {ok, errors[]} и run() для CLI.
// Не выполняет запись в Firestore.

export const REQUIRED_SCENARIO_FIELDS = Object.freeze([
  'id',
  'slug',
  'title',
  'whyTheseGames',
  'seoTitle',
]);

// SEO-поля: лимиты длин по content-intake (SP-E1-04).
export const SEO_LIMITS = Object.freeze({
  seoTitle: 60,
  seoDescription: 160,
});

// shareImageUrl: путь Storage (bucket) или абсолютный URL (SP-E1-04).
const URL_RE = /^https?:\/\//i;
const STORAGE_PATH_RE = /^[a-z0-9][a-z0-9._/-]*$/i;

const MARKDOWN_RE = /(\*\*|__|`|\[[^\]]*\]\([^)]*\)|^#{1,6}\s)/m;

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isPlainText(value) {
  return typeof value === 'string' && !MARKDOWN_RE.test(value);
}

function validateBinding(binding, index, knownGameIds, errors) {
  const prefix = `games[${index}]`;
  if (typeof binding !== 'object' || binding === null || Array.isArray(binding)) {
    errors.push(`${prefix}: ожидается объект связки`);
    return;
  }
  if (!isNonEmptyString(binding.gameId)) {
    errors.push(`${prefix}.gameId: обязательное непустое значение`);
  } else if (knownGameIds && !knownGameIds.includes(binding.gameId)) {
    errors.push(`${prefix}.gameId: игра "${binding.gameId}" не найдена в games`);
  }
  if (!Number.isInteger(binding.order) || binding.order < 1) {
    errors.push(`${prefix}.order: целое число ≥ 1 (CR-4)`);
  }
  if (!isNonEmptyString(binding.shortDescription)) {
    errors.push(`${prefix}.shortDescription: обязательное непустое значение`);
  } else if (!isPlainText(binding.shortDescription)) {
    errors.push(`${prefix}.shortDescription: plain text, без Markdown/HTML (A-4a)`);
  }
}

export function validateScenario(json, knownGameIds = null) {
  const errors = [];

  if (typeof json !== 'object' || json === null || Array.isArray(json)) {
    return { ok: false, errors: ['сценарий: ожидается JSON-объект'] };
  }

  for (const field of REQUIRED_SCENARIO_FIELDS) {
    if (!isNonEmptyString(json[field])) {
      errors.push(`${field}: обязательное поле`);
    }
  }

  for (const field of ['title', 'subtitle', 'whyTheseGames']) {
    if (json[field] !== undefined && !isPlainText(json[field])) {
      errors.push(`${field}: plain text, без Markdown/HTML (A-4a)`);
    }
  }

  // SEO-поля (SP-E1-04): plain text (A-4a) и лимиты длин.
  for (const field of ['seoTitle', 'seoDescription']) {
    if (json[field] !== undefined && !isPlainText(json[field])) {
      errors.push(`${field}: plain text, без Markdown/HTML (A-4a)`);
    }
    if (json[field] !== undefined && json[field].length > SEO_LIMITS[field]) {
      errors.push(`${field}: длина не более ${SEO_LIMITS[field]} символов (SP-E1-04)`);
    }
  }

  // Поля шаринга (SP-E1-04): plain text; shareImageUrl — путь/URL.
  for (const field of ['shareTitle', 'shareText']) {
    if (json[field] !== undefined && !isPlainText(json[field])) {
      errors.push(`${field}: plain text, без Markdown/HTML (A-4a)`);
    }
  }
  if (json.shareImageUrl !== undefined) {
    if (typeof json.shareImageUrl !== 'string' || json.shareImageUrl.trim().length === 0) {
      errors.push('shareImageUrl: ожидается непустой путь Storage или URL');
    } else if (!URL_RE.test(json.shareImageUrl) && !STORAGE_PATH_RE.test(json.shareImageUrl)) {
      errors.push('shareImageUrl: ожидается путь Storage (bucket) или абсолютный URL (SP-E1-04)');
    }
  }

  // Витрина (AC-02, FR-B-1, CR-4): onHomeVitrine/vitrineOrder.
  if (json.onHomeVitrine !== undefined && typeof json.onHomeVitrine !== 'boolean') {
    errors.push('onHomeVitrine: ожидается boolean');
  }
  const onHomeVitrine = json.onHomeVitrine ?? false;
  if (
    json.vitrineOrder !== undefined &&
    (!Number.isInteger(json.vitrineOrder) || json.vitrineOrder < 1)
  ) {
    errors.push('vitrineOrder: целое число ≥ 1 (CR-4)');
  }
  if (onHomeVitrine === true && !Number.isInteger(json.vitrineOrder)) {
    errors.push('vitrineOrder: обязателен при onHomeVitrine: true (CR-4)');
  }

  // Группы смысла (US-E7-01, БТ §7.1): массив id групп.
  if (json.semanticGroupIds !== undefined) {
    if (!Array.isArray(json.semanticGroupIds)) {
      errors.push('semanticGroupIds: ожидается массив id групп смысла');
    } else {
      const seen = new Set();
      for (const gid of json.semanticGroupIds) {
        if (!isNonEmptyString(gid)) {
          errors.push('semanticGroupIds: каждый id — непустая строка');
        } else if (seen.has(gid)) {
          errors.push(`semanticGroupIds: группа "${gid}" дублируется`);
        }
        seen.add(gid);
      }
    }
  }

  if (!Array.isArray(json.games)) {
    errors.push('games: обязательный массив связок сценарий–игра');
  } else {
    const seenOrders = new Set();
    const seenGameIds = new Set();
    json.games.forEach((binding, i) => {
      validateBinding(binding, i, knownGameIds, errors);
      if (binding && Number.isInteger(binding.order)) {
        if (seenOrders.has(binding.order)) {
          errors.push(
            `games: order=${binding.order} дублируется в пределах сценария (CR-4)`,
          );
        }
        seenOrders.add(binding.order);
      }
      if (binding && isNonEmptyString(binding.gameId)) {
        if (seenGameIds.has(binding.gameId)) {
          errors.push(`games: игра "${binding.gameId}" привязана более одного раза`);
        }
        seenGameIds.add(binding.gameId);
      }
    });
  }

  return { ok: errors.length === 0, errors };
}

// CLI: node validate-scenario.mjs <file.json> [--json]
export function run(argv = process.argv.slice(2)) {
  const file = argv.find((a) => !a.startsWith('--'));
  const asJson = argv.includes('--json');
  if (!file) {
    console.error('Использование: node validate-scenario.mjs <scenario.json> [--json]');
    process.exit(2);
  }

  let json;
  try {
    json = JSON.parse(require('node:fs').readFileSync(file, 'utf8'));
  } catch (err) {
    console.error(`Ошибка чтения/парсинга ${file}: ${err.message}`);
    process.exit(2);
  }

  const result = validateScenario(json);
  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
  } else if (result.ok) {
    console.log(`OK: ${file} — сценарий валиден`);
  } else {
    console.error(`FAIL: ${file}`);
    for (const e of result.errors) console.error(`  - ${e}`);
  }
  process.exit(result.ok ? 0 : 1);
}

// ESM-совместимый require для чтения файла в CLI.
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

// Запуск CLI при прямом выполнении (node validate-scenario.mjs <file>).
import { pathToFileURL } from 'node:url';
if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  run();
}
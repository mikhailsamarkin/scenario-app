// Валидатор игры (SP-E1-01, шаг 3).
//
// Проверяет документ игры перед записью:
//   - обязательные поля (A-30);
//   - закрытые enum по CR-4.1 (AC-02);
//   - карусель по CR-5: непустой массив, валидные frameType, обязательный
//     imageRef, минимум один слайд с frameType == teaser (AC-01);
//   - тексты — plain text, без Markdown/HTML (A-4a).
//
// Экспортирует validateGame(json) -> {ok, errors[]} и run() для CLI.
// Не выполняет запись в Firestore/Storage.

export const ENUM_ALLOWLISTS = Object.freeze({
  playersHint: Object.freeze([
    'players_1',
    'players_2',
    'players_2_4',
    'players_2_5',
    'players_2_6',
    'players_5_plus',
  ]),
  durationBucket: Object.freeze(['warmup', 'short', 'evening', 'long', 'main_event']),
  ageHint: Object.freeze(['age_kids', 'age_family', 'age_adults']),
  rulesComplexity: Object.freeze(['easy', 'normal', 'heavy']),
  frameType: Object.freeze(['teaser', 'box', 'in_play', 'mechanic_closeup']),
});

export const REQUIRED_FIELDS = Object.freeze([
  'id',
  'slug',
  'title',
  'playersHint',
  'durationBucket',
  'ageHint',
  'rulesComplexity',
  'carousel',
]);

// Разрешённые MIME-типы изображений (лимит бакета games, SP-E0-02).
export const ALLOWED_IMAGE_MIME = Object.freeze([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const MARKDOWN_RE = /(\*\*|__|`|\[[^\]]*\]\([^)]*\)|^#{1,6}\s)/m;

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isPlainText(value) {
  return typeof value === 'string' && !MARKDOWN_RE.test(value);
}

function validateSlide(slide, index, errors) {
  const prefix = `carousel[${index}]`;
  if (typeof slide !== 'object' || slide === null || Array.isArray(slide)) {
    errors.push(`${prefix}: ожидается объект слайда`);
    return;
  }
  if (!isNonEmptyString(slide.imageRef)) {
    errors.push(`${prefix}.imageRef: обязательное непустое значение`);
  }
  if (!ENUM_ALLOWLISTS.frameType.includes(slide.frameType)) {
    errors.push(
      `${prefix}.frameType: допустимые значения: ${ENUM_ALLOWLISTS.frameType.join(', ')}`,
    );
  }
  if (slide.caption !== undefined && !isPlainText(slide.caption)) {
    errors.push(`${prefix}.caption: plain text, без Markdown/HTML (A-4a)`);
  }
  if (slide.alt !== undefined && !isPlainText(slide.alt)) {
    errors.push(`${prefix}.alt: plain text, без Markdown/HTML (A-4a)`);
  }
}

export function validateGame(json) {
  const errors = [];

  if (typeof json !== 'object' || json === null || Array.isArray(json)) {
    return { ok: false, errors: ['игра: ожидается JSON-объект'] };
  }

  for (const field of REQUIRED_FIELDS) {
    if (!isNonEmptyString(json[field]) && field !== 'carousel') {
      errors.push(`${field}: обязательное поле (A-30)`);
    }
  }

  for (const field of ['playersHint', 'durationBucket', 'ageHint', 'rulesComplexity']) {
    if (json[field] !== undefined && !ENUM_ALLOWLISTS[field].includes(json[field])) {
      errors.push(
        `${field}: допустимые значения: ${ENUM_ALLOWLISTS[field].join(', ')} (CR-4.1)`,
      );
    }
  }

  if (json.title !== undefined && !isPlainText(json.title)) {
    errors.push('title: plain text, без Markdown/HTML (A-4a)');
  }

  if (!Array.isArray(json.carousel)) {
    errors.push('carousel: обязательный массив слайдов (CR-5)');
  } else if (json.carousel.length === 0) {
    errors.push('carousel: массив не может быть пустым (CR-5)');
  } else {
    json.carousel.forEach((slide, i) => validateSlide(slide, i, errors));
    if (!json.carousel.some((s) => s && s.frameType === 'teaser')) {
      errors.push('carousel: требуется минимум один слайд с frameType=teaser (CR-5)');
    }
  }

  return { ok: errors.length === 0, errors };
}

// CLI: node validate-game.mjs <file.json> [--json]
export function run(argv = process.argv.slice(2)) {
  const file = argv.find((a) => !a.startsWith('--'));
  const asJson = argv.includes('--json');
  if (!file) {
    console.error('Использование: node validate-game.mjs <game.json> [--json]');
    process.exit(2);
  }

  let json;
  try {
    json = JSON.parse(require('node:fs').readFileSync(file, 'utf8'));
  } catch (err) {
    console.error(`Ошибка чтения/парсинга ${file}: ${err.message}`);
    process.exit(2);
  }

  const result = validateGame(json);
  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
  } else if (result.ok) {
    console.log(`OK: ${file} — игра валидна`);
  } else {
    console.error(`FAIL: ${file}`);
    for (const e of result.errors) console.error(`  - ${e}`);
  }
  process.exit(result.ok ? 0 : 1);
}

// ESM-совместимый require для чтения файла в CLI.
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
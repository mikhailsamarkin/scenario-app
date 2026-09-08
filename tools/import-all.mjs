// Оркестратор импорта всех фикстур (SP-E1-01 шаг 4, SP-E1-03 шаг 4).
//
// Заменяет CI-прогон import-content.yml: один локальный вызов валидирует все
// фикстуры игр (data/content/games/*.json) и сценариев
// (data/content/scenarios/*.json), кроме invalid/, и импортирует каждую на
// выбранный проект. Логика импорта не дублируется — делегируется
// import-games.mjs и import-scenario.mjs (валидация, slug, агрегаты — без изменений).
//
// Использование:
//   node import-all.mjs --project dev [--dry-run]
//
// Шаг 1 (валидация) не требует секретов (R3); шаг 2 (импорт) — как в
// import-games.mjs / import-scenario.mjs, с env-переменными A-40
// (FIREBASE_SERVICE_ACCOUNT_PATH, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY).

import { readdirSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { validateGame } from './validate-game.mjs';
import { validateScenario } from './validate-scenario.mjs';
import { validateGroup } from './validate-group.mjs';

const PROJECTS = Object.freeze({
  dev: Object.freeze({ firebaseProjectId: 'scenario-ba26a' }),
  prod: Object.freeze({ firebaseProjectId: 'scenario-prod-491c' }),
});

const TOOLS_DIR = dirname(fileURLToPath(import.meta.url));
const CONTENT_DIR = resolve(TOOLS_DIR, '..', 'data', 'content');

// Типы контента: директория фикстур, скрипт импорта, валидатор, подпись в логе.
const CONTENT_TYPES = Object.freeze([
  Object.freeze({
    kind: 'игра',
    dir: resolve(CONTENT_DIR, 'games'),
    importScript: 'import-games.mjs',
    validate: validateGame,
  }),
  Object.freeze({
    kind: 'сценарий',
    dir: resolve(CONTENT_DIR, 'scenarios'),
    importScript: 'import-scenario.mjs',
    validate: validateScenario,
  }),
  Object.freeze({
    kind: 'группа смысла',
    dir: resolve(CONTENT_DIR, 'groups'),
    importScript: 'import-groups.mjs',
    validate: validateGroup,
    isBulk: true,
  }),
]);

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const project = argv[argv.indexOf('--project') + 1];
  const dryRun = argv.includes('--dry-run');
  if (!project || !PROJECTS[project]) {
    fail('Укажите --project dev|prod');
  }
  return { project, dryRun };
}

function listFixtures(dir) {
  const files = readdirSync(dir)
    .filter((name) => name.endsWith('.json'))
    .map((name) => resolve(dir, name))
    .sort();
  if (files.length === 0) {
    fail(`Не найдено фикстур *.json в ${dir}`);
  }
  return files;
}

// Шаг 1: быстрая валидация всех фикстур без секретов (R3).
function validateAll(files, validate, kind) {
  let failed = 0;
  for (const file of files) {
    let json;
    try {
      json = JSON.parse(readFileSync(file, 'utf8'));
    } catch (err) {
      console.error(`FAIL: ${file}`);
      console.error(`  - ошибка чтения/парсинга: ${err.message}`);
      failed++;
      continue;
    }
    const result = validate(json);
    if (!result.ok) {
      console.error(`FAIL: ${file}`);
      for (const e of result.errors) console.error(`  - ${e}`);
      failed++;
    } else {
      console.log(`OK: ${file} — ${kind} валиден`);
    }
  }
  if (failed > 0) {
    fail(`Валидация не пройдена: ${failed} фикстур(ы) с ошибками`);
  }
}

// Шаг 2: импорт каждой фикстуры через скрипт импорта (логика не дублируется).
// Группы смысла импортируются одним вызовом (import-groups.mjs обрабатывает
// все файлы в data/content/groups/), поэтому файл не передаётся.
function importAll(files, importScript, project, dryRun, isBulk = false) {
  const targets = isBulk ? [null] : files;
  for (const file of targets) {
    const args = [importScript, '--project', project];
    if (file) args.push(file);
    if (dryRun) args.push('--dry-run');
    const result = spawnSync(process.execPath, args, { cwd: TOOLS_DIR });
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    if (result.status !== 0) {
      fail(`Импорт ${file ?? importScript} завершился с кодом ${result.status}`);
    }
  }
}

const { project, dryRun } = parseArgs(process.argv.slice(2));
let total = 0;
for (const type of CONTENT_TYPES) {
  const fixtures = listFixtures(type.dir);
  validateAll(fixtures, type.validate, type.kind);
  importAll(fixtures, type.importScript, project, dryRun, type.isBulk);
  total += fixtures.length;
}
console.log(`OK: импортировано ${total} фикстур (${project})${dryRun ? ' [dry-run]' : ''}`);
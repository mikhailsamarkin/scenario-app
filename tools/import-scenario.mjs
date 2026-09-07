// Оркестратор импорта/публикации сценария со связками игр (SP-E1-03, шаг 4).
//
// Поток: валидация (validate-scenario.mjs) → проверка уникальности slug →
// запись scenarios/{id} (источник правды) → синхронизация scenario_games →
// сборка scenario_public/{scenarioId} (A-10) → обновление обратных ссылок
// game_public/{gameId}.scenarios (A-12) → обновление home_feed/main.vitrine
// и sitemap_public/main.scenarioSlugs (A-12, A-10b, A-44).
//
// Использование:
//   node import-scenario.mjs --project dev data/content/scenarios/<id>.json [--dry-run]
//
// Переменные окружения (вне git, A-40):
//   FIREBASE_SERVICE_ACCOUNT_PATH — путь к service account key Firebase
//
// Идемпотентен: повторный запуск с теми же данными обновляет документы
// по паре {scenarioId, gameId}, не создавая дубликатов.

import { readFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';

import { validateScenario } from './validate-scenario.mjs';

const require = createRequire(import.meta.url);

const PROJECTS = Object.freeze({
  dev: Object.freeze({ firebaseProjectId: 'scenario-ba26a' }),
  prod: Object.freeze({ firebaseProjectId: 'scenario-prod-491c' }),
});

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const projectFlag = argv[argv.indexOf('--project') + 1];
  const file = argv.find((a) => !a.startsWith('--') && a !== projectFlag);
  const dryRun = argv.includes('--dry-run');
  if (!projectFlag || !PROJECTS[projectFlag]) {
    fail('Укажите --project dev|prod');
  }
  if (!file) {
    fail('Укажите путь к JSON сценария: node import-scenario.mjs --project dev <scenario.json>');
  }
  return { project: projectFlag, file, dryRun };
}

function loadScenario(file) {
  if (!existsSync(file)) fail(`Файл не найден: ${file}`);
  let json;
  try {
    json = JSON.parse(readFileSync(file, 'utf8'));
  } catch (err) {
    fail(`Ошибка чтения/парсинга ${file}: ${err.message}`);
  }
  return json;
}

function nowIso() {
  return new Date().toISOString();
}

// Читает документы игр из источника правды (ссылочная целостность).
async function loadGames(db, gameIds) {
  const games = {};
  for (const id of gameIds) {
    const snap = await db.doc(`games/${id}`).get();
    if (!snap.exists) {
      fail(`Игра games/${id} не найдена в источнике правды (ссылочная целостность)`);
    }
    games[id] = snap.data();
  }
  return games;
}

// Собирает ScenarioGameRef для scenario_public.games (A-10, §4.4 SP-E0-01).
// Порядок — по `order` связки (CR-4, AC-01).
function buildScenarioGameRefs(bindings, games) {
  const sorted = [...bindings].sort((a, b) => a.order - b.order);
  return sorted.map((b) => {
    const g = games[b.gameId];
    const teaser = (g.carousel ?? []).find((s) => s.frameType === 'teaser');
    return {
      gameId: b.gameId,
      slug: g.slug,
      title: g.title,
      shortDescription: b.shortDescription,
      ...(teaser?.imageRef ? { imageRef: teaser.imageRef } : {}),
      ...(teaser?.alt ? { alt: teaser.alt } : {}),
      playersHint: g.playersHint,
      durationBucket: g.durationBucket,
      ageHint: g.ageHint,
      rulesComplexity: g.rulesComplexity,
    };
  });
}

// Собирает ScenarioCard для home_feed.vitrine (A-12, §4.2 SP-E0-01).
// Только опубликованные сценарии с onHomeVitrine: true, сортировка по vitrineOrder
// (стабильность — вторичная сортировка по id). imageRef/alt — из первого
// teaser-слайда первой игры сценария (по order связки), если есть.
async function buildVitrine(db) {
  const scenariosSnap = await db
    .collection('scenarios')
    .where('published', '==', true)
    .get();
  const entries = [];
  for (const doc of scenariosSnap.docs) {
    const sc = doc.data();
    if (sc.onHomeVitrine !== true) continue;
    const card = {
      scenarioId: sc.id,
      slug: sc.slug,
      title: sc.title,
      ...(sc.subtitle ? { subtitle: sc.subtitle } : {}),
    };
    // Первый teaser-слайд первой игры сценария (по order связки).
    const bindings = await db
      .collection('scenario_games')
      .where('scenarioId', '==', sc.id)
      .get();
    const sorted = bindings.docs
      .map((d) => d.data())
      .sort((a, b) => a.order - b.order);
    if (sorted.length > 0) {
      const gameSnap = await db.doc(`games/${sorted[0].gameId}`).get();
      if (gameSnap.exists) {
        const teaser = (gameSnap.data().carousel ?? []).find(
          (s) => s.frameType === 'teaser',
        );
        if (teaser?.imageRef) card.imageRef = teaser.imageRef;
        if (teaser?.alt) card.alt = teaser.alt;
      }
    }
    entries.push({ card, order: sc.vitrineOrder ?? Number.MAX_SAFE_INTEGER, id: sc.id });
  }
  entries.sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));
  return entries.map((e) => e.card);
}

// Собирает scenarioSlugs для sitemap_public/main (A-10b, A-10d).
async function buildScenarioSlugs(db) {
  const scenariosSnap = await db
    .collection('scenarios')
    .where('published', '==', true)
    .get();
  return scenariosSnap.docs.map((d) => d.data().slug).sort();
}

// Собирает GameScenarioRef для game_public.scenarios (A-12, §4.5 SP-E0-01).
function buildGameScenarioRefs(bindings, scenarios) {
  return bindings
    .map((b) => {
      const sc = scenarios[b.scenarioId];
      return {
        scenarioId: b.scenarioId,
        slug: sc.slug,
        title: sc.title,
        shortDescription: b.shortDescription,
      };
    })
    .sort((a, b) => a.scenarioId.localeCompare(b.scenarioId));
}

async function publishScenario({ project, file, dryRun }) {
  const scenario = loadScenario(file);

  // Firebase Admin SDK (запись — service account, A-38).
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!serviceAccountPath) fail('FIREBASE_SERVICE_ACCOUNT_PATH не задан (A-40)');
  const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
  const { initializeApp, cert } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  const app = initializeApp(
    {
      credential: cert(serviceAccount),
      projectId: PROJECTS[project].firebaseProjectId,
    },
    `import-scenario-${project}-${scenario.id}`,
  );
  const db = getFirestore(app);

  // 1. Ссылочная целостность: собрать известные игры из источника правды.
  const gameIds = (scenario.games ?? []).map((b) => b.gameId);
  const games = await loadGames(db, gameIds);

  // 2. Валидация (структура + ссылочная целостность).
  const result = validateScenario(scenario, Object.keys(games));
  if (!result.ok) {
    console.error(`Валидация не пройдена (${file}):`);
    for (const e of result.errors) console.error(`  - ${e}`);
    process.exit(1);
  }

  // 3. Уникальность slug (ED-8): другой документ с тем же slug — ошибка.
  const slugQuery = await db
    .collection('scenarios')
    .where('slug', '==', scenario.slug)
    .get();
  for (const doc of slugQuery.docs) {
    if (doc.id !== scenario.id) {
      fail(`slug "${scenario.slug}" уже занят документом scenarios/${doc.id} (ED-8)`);
    }
  }

  const now = nowIso();

  // 4. Запись источника правды scenarios/{id}.
  const scenarioDoc = {
    id: scenario.id,
    slug: scenario.slug,
    title: scenario.title,
    ...(scenario.subtitle ? { subtitle: scenario.subtitle } : {}),
    whyTheseGames: scenario.whyTheseGames,
    published: scenario.published ?? false,
    ...(scenario.publishedAt ? { publishedAt: scenario.publishedAt } : {}),
    ...(scenario.onHomeVitrine ? { onHomeVitrine: scenario.onHomeVitrine } : {}),
    ...(scenario.vitrineOrder !== undefined ? { vitrineOrder: scenario.vitrineOrder } : {}),
    ...(scenario.shareTitle ? { shareTitle: scenario.shareTitle } : {}),
    ...(scenario.shareText ? { shareText: scenario.shareText } : {}),
    ...(scenario.shareImageUrl ? { shareImageUrl: scenario.shareImageUrl } : {}),
    ...(scenario.seoTitle ? { seoTitle: scenario.seoTitle } : {}),
    ...(scenario.seoDescription ? { seoDescription: scenario.seoDescription } : {}),
    createdAt: scenario.createdAt ?? now,
    updatedAt: now,
  };
  if (dryRun) {
    console.log(`[dry-run] set scenarios/${scenario.id}`);
  } else {
    await db.doc(`scenarios/${scenario.id}`).set(scenarioDoc, { merge: true });
    console.log(`written scenarios/${scenario.id}`);
  }

  // 5. Синхронизация scenario_games (источник правды связок).
  const bindingDocs = {};
  for (const b of scenario.games) {
    const docId = `${scenario.id}_${b.gameId}`;
    bindingDocs[docId] = {
      scenarioId: scenario.id,
      gameId: b.gameId,
      order: b.order,
      shortDescription: b.shortDescription,
    };
  }
  const existingBindings = await db
    .collection('scenario_games')
    .where('scenarioId', '==', scenario.id)
    .get();
  // Игры, чьи обратные ссылки game_public.scenarios могут измениться:
  // и те, что в новом составе, и те, что были в старом (удалённые).
  const affectedGameIds = new Set(gameIds);
  for (const doc of existingBindings.docs) {
    affectedGameIds.add(doc.data().gameId);
    if (!bindingDocs[doc.id]) {
      if (!dryRun) await db.doc(`scenario_games/${doc.id}`).delete();
      console.log(`deleted scenario_games/${doc.id}`);
    }
  }
  for (const [docId, data] of Object.entries(bindingDocs)) {
    if (dryRun) {
      console.log(`[dry-run] set scenario_games/${docId}`);
    } else {
      await db.doc(`scenario_games/${docId}`).set(data);
      console.log(`written scenario_games/${docId}`);
    }
  }

  // Публичные агрегаты строятся только для опубликованных сценариев (A-10).
  if (scenario.published === false) {
    console.log(`SKIP: сценарий ${scenario.id} не опубликован — публичные агрегаты не строятся`);
    console.log(`OK: сценарий ${scenario.id} сохранён (${project})`);
    return;
  }

  // 6. Публичный агрегат scenario_public/{scenarioId} (A-10, §4.4 SP-E0-01).
  const scenarioPublicRef = db.doc(`scenario_public/${scenario.id}`);
  const existingPublic = (await scenarioPublicRef.get()).exists
    ? (await scenarioPublicRef.get()).data()
    : { contentVersion: 0 };
  const nextVersion = (existingPublic.contentVersion ?? 0) + 1;
  const scenarioPublic = {
    id: scenario.id,
    slug: scenario.slug,
    title: scenario.title,
    ...(scenario.subtitle ? { subtitle: scenario.subtitle } : {}),
    whyTheseGames: scenario.whyTheseGames,
    ...(scenario.seoTitle ? { seoTitle: scenario.seoTitle } : {}),
    ...(scenario.seoDescription ? { seoDescription: scenario.seoDescription } : {}),
    ...(scenario.shareTitle ? { shareTitle: scenario.shareTitle } : {}),
    ...(scenario.shareText ? { shareText: scenario.shareText } : {}),
    ...(scenario.shareImageUrl ? { shareImageUrl: scenario.shareImageUrl } : {}),
    ...(scenario.publishedAt ? { publishedAt: scenario.publishedAt } : {}),
    games: buildScenarioGameRefs(scenario.games, games),
    semanticGroupIds: [],
    contentVersion: nextVersion,
    updatedAt: now,
  };
  if (dryRun) {
    console.log(`[dry-run] set scenario_public/${scenario.id} (games=${scenarioPublic.games.length})`);
  } else {
    await scenarioPublicRef.set(scenarioPublic);
    console.log(`written scenario_public/${scenario.id} (games=${scenarioPublic.games.length})`);
  }

  // 7. Обновить обратные ссылки game_public/{gameId}.scenarios для каждой затронутой игры.
  for (const gameId of affectedGameIds) {
    const gamePublicRef = db.doc(`game_public/${gameId}`);
    const existingGamePublic = (await gamePublicRef.get()).exists
      ? (await gamePublicRef.get()).data()
      : null;
    if (!existingGamePublic) {
      // Игра ещё не опубликована — не создаём game_public из сценария.
      continue;
    }
    // Пересобрать scenarios из ВСЕХ связок этой игры (игра может быть в нескольких сценариях).
    const bindingsForGame = await db
      .collection('scenario_games')
      .where('gameId', '==', gameId)
      .get();
    const scenariosById = {};
    const refs = [];
    for (const doc of bindingsForGame.docs) {
      const b = doc.data();
      if (!scenariosById[b.scenarioId]) {
        const scenarioSnap = await db.doc(`scenarios/${b.scenarioId}`).get();
        if (!scenarioSnap.exists || scenarioSnap.data().published === false) continue;
        scenariosById[b.scenarioId] = scenarioSnap.data();
      }
      refs.push({ binding: b, scenario: scenariosById[b.scenarioId] });
    }
    const gameScenarioRefs = refs.map(({ binding, scenario }) => ({
      scenarioId: binding.scenarioId,
      slug: scenario.slug,
      title: scenario.title,
      shortDescription: binding.shortDescription,
    }));
    gameScenarioRefs.sort((a, b) => a.scenarioId.localeCompare(b.scenarioId));

    const gameNextVersion = (existingGamePublic.contentVersion ?? 0) + 1;
    const updated = {
      ...existingGamePublic,
      scenarios: gameScenarioRefs,
      contentVersion: gameNextVersion,
      updatedAt: now,
    };
    if (dryRun) {
      console.log(`[dry-run] set game_public/${gameId} (scenarios=${gameScenarioRefs.length})`);
    } else {
      await gamePublicRef.set(updated);
      console.log(`written game_public/${gameId} (scenarios=${gameScenarioRefs.length})`);
    }
  }

  // 8. Зависимые агрегаты: home_feed/main.vitrine и sitemap_public/main.scenarioSlugs
  //    (A-12, A-10b, A-44). Запись по полям сохраняет carousel (игры) и gameSlugs.
  const homeRef = db.doc('home_feed/main');
  const sitemapRef = db.doc('sitemap_public/main');
  const homeSnap = await homeRef.get();
  const sitemapSnap = await sitemapRef.get();
  const home = homeSnap.exists ? homeSnap.data() : { carousel: [], vitrine: [], groups: [] };
  const sitemap = sitemapSnap.exists
    ? sitemapSnap.data()
    : { scenarioSlugs: [], gameSlugs: [] };
  const homeNextVersion = (home.contentVersion ?? 0) + 1;

  const vitrine = await buildVitrine(db);
  const scenarioSlugs = await buildScenarioSlugs(db);

  if (dryRun) {
    console.log(`[dry-run] set home_feed/main (vitrine=${vitrine.length})`);
    console.log(`[dry-run] set sitemap_public/main (scenarioSlugs=${scenarioSlugs.length})`);
  } else {
    await homeRef.set({
      ...home,
      vitrine,
      contentVersion: homeNextVersion,
      updatedAt: now,
    });
    console.log(`written home_feed/main (vitrine=${vitrine.length})`);

    await sitemapRef.set({
      ...sitemap,
      scenarioSlugs,
      contentVersion: homeNextVersion,
      updatedAt: now,
    });
    console.log(`written sitemap_public/main (scenarioSlugs=${scenarioSlugs.length})`);
  }

  console.log(`OK: сценарий ${scenario.id} опубликован (${project})`);
}

const args = parseArgs(process.argv.slice(2));
publishScenario(args).catch((err) => {
  console.error(`ERROR: ${err.message}`);
  process.exit(1);
});
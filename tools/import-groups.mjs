// Импорт групп смысла (SP-E7-01, БТ §7.1).
//
// Читает фикстуры групп из data/content/groups/*.json, валидирует, пишет
// semantic_groups_public/{id} (список ScenarioCard) и обновляет
// home_feed/main.groups (GroupRef) и sitemap_public/main (если нужно).
//
// Использование:
//   node import-groups.mjs --project dev [--dry-run]
//
// Переменные окружения (вне git, A-40):
//   FIREBASE_SERVICE_ACCOUNT_PATH — путь к service account key Firebase

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { createRequire } from 'node:module';

import { validateGroup } from './validate-group.mjs';

const require = createRequire(import.meta.url);

const PROJECTS = Object.freeze({
  dev: Object.freeze({ firebaseProjectId: 'scenario-ba26a' }),
  prod: Object.freeze({ firebaseProjectId: 'scenario-prod-491c' }),
});

const GROUPS_DIR = new URL('../data/content/groups/', import.meta.url).pathname;

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function nowIso() {
  return new Date().toISOString();
}

function parseArgs(argv) {
  const projectFlag = argv[argv.indexOf('--project') + 1];
  const dryRun = argv.includes('--dry-run');
  if (!projectFlag || !PROJECTS[projectFlag]) {
    fail('Укажите --project dev|prod');
  }
  return { project: projectFlag, dryRun };
}

// Собирает ScenarioCard для группы из scenario_public/{id}.
// imageRef/alt — из первого teaser-слайда первой игры сценария.
async function buildScenarioCard(db, scenarioId) {
  const snap = await db.doc(`scenario_public/${scenarioId}`).get();
  if (!snap.exists) return null;
  const sc = snap.data();
  const card = {
    scenarioId: sc.id,
    slug: sc.slug,
    title: sc.title,
    ...(sc.subtitle ? { subtitle: sc.subtitle } : {}),
  };
  // Первый teaser-слайд первой игры (по order связки).
  const bindings = await db
    .collection('scenario_games')
    .where('scenarioId', '==', scenarioId)
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
  return card;
}

async function importGroups({ project, dryRun }) {
  if (!existsSync(GROUPS_DIR)) {
    console.log(`Нет папки ${GROUPS_DIR} — групп нет, пропуск`);
    return;
  }
  const files = readdirSync(GROUPS_DIR).filter((f) => f.endsWith('.json'));

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
    `import-groups-${project}`,
  );
  const db = getFirestore(app);

  // Собрать известные scenarioId из источника правды (ссылочная целостность).
  const scenariosSnap = await db.collection('scenarios').get();
  const knownScenarioIds = scenariosSnap.docs.map((d) => d.id);

  const now = nowIso();
  const groupRefs = [];

  for (const file of files) {
    const path = `${GROUPS_DIR}/${file}`;
    const group = JSON.parse(readFileSync(path, 'utf8'));
    const result = validateGroup(group, knownScenarioIds);
    if (!result.ok) {
      console.error(`Валидация не пройдена (${path}):`);
      for (const e of result.errors) console.error(`  - ${e}`);
      process.exit(1);
    }

    // Собрать ScenarioCard для каждого сценария группы.
    const cards = [];
    for (const ref of group.scenarios) {
      const card = await buildScenarioCard(db, ref.scenarioId);
      if (card) cards.push(card);
    }

    const publicDoc = {
      id: group.id,
      title: group.title,
      slug: group.slug,
      ...(group.listOrder ? { listOrder: group.listOrder } : {}),
      isPastArchive: group.isPastArchive ?? false,
      scenarios: cards,
      contentVersion: 1,
      updatedAt: now,
    };

    if (dryRun) {
      console.log(`[dry-run] set semantic_groups_public/${group.id} (scenarios=${cards.length})`);
    } else {
      await db.doc(`semantic_groups_public/${group.id}`).set(publicDoc);
      console.log(`written semantic_groups_public/${group.id} (scenarios=${cards.length})`);
    }
    groupRefs.push({ semanticGroupId: group.id, slug: group.slug, title: group.title });
  }

  // Обновить home_feed/main.groups (GroupRef).
  groupRefs.sort((a, b) => a.semanticGroupId.localeCompare(b.semanticGroupId));
  const homeRef = db.doc('home_feed/main');
  const homeSnap = await homeRef.get();
  const home = homeSnap.exists ? homeSnap.data() : { carousel: [], vitrine: [], groups: [] };
  const homeNextVersion = (home.contentVersion ?? 0) + 1;
  if (dryRun) {
    console.log(`[dry-run] set home_feed/main.groups (groups=${groupRefs.length})`);
  } else {
    await homeRef.set({
      ...home,
      groups: groupRefs,
      contentVersion: homeNextVersion,
      updatedAt: now,
    });
    console.log(`written home_feed/main.groups (groups=${groupRefs.length})`);
  }

  console.log(`OK: импорт групп завершён (${project})`);
}

const { project, dryRun } = parseArgs(process.argv.slice(2));
await importGroups({ project, dryRun });
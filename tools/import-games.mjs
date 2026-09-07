// Оркестратор импорта/публикации игры (SP-E1-01, шаг 4).
//
// Поток: валидация (validate-game.mjs) → проверка уникальности slug →
// upload изображений в Supabase Storage (ED-7, A-39) → запись games/{id}
// (источник правды) → сборка game_public/{gameId} (A-10) → обновление
// home_feed/main и sitemap_public/main (A-10e, A-44).
//
// Использование:
//   node import-games.mjs --project dev data/content/games/<id>.json [--dry-run]
//
// Переменные окружения (вне git, A-40):
//   FIREBASE_SERVICE_ACCOUNT_PATH — путь к service account key Firebase
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY — по окружению dev/prod
//
// Идемпотентен: повторный запуск с теми же данными обновляет документы
// по id, не создавая дубликатов.

import { readFileSync, existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';
import { createRequire } from 'node:module';

import { validateGame } from './validate-game.mjs';

const require = createRequire(import.meta.url);

const PROJECTS = Object.freeze({
  dev: Object.freeze({ firebaseProjectId: 'scenario-ba26a' }),
  prod: Object.freeze({ firebaseProjectId: 'scenario-prod-491c' }),
});

const BUCKET = 'games';
const MAX_IMAGE_BYTES = 10 * 1024 * 1024; // лимит бакета games (SP-E0-02)

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
    fail('Укажите путь к JSON игры: node import-games.mjs --project dev <game.json>');
  }
  return { project: projectFlag, file, dryRun };
}

function loadGame(file) {
  if (!existsSync(file)) fail(`Файл не найден: ${file}`);
  let json;
  try {
    json = JSON.parse(readFileSync(file, 'utf8'));
  } catch (err) {
    fail(`Ошибка чтения/парсинга ${file}: ${err.message}`);
  }
  const result = validateGame(json);
  if (!result.ok) {
    console.error(`Валидация не пройдена (${file}):`);
    for (const e of result.errors) console.error(`  - ${e}`);
    process.exit(1);
  }
  return json;
}

function detectMime(path) {
  const lower = path.toLowerCase();
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}

// Собирает локальные файлы изображений, на которые ссылаются слайды.
// imageRef в JSON может быть локальным путём (например images/teaser.jpg)
// или уже загруженным путём в Storage (games/{id}/...).
function collectImages(game, baseDir) {
  const images = [];
  for (const slide of game.carousel) {
    const ref = slide.imageRef;
    if (ref.startsWith(`${game.id}/`) || ref.startsWith(`games/${game.id}/`)) {
      continue; // уже путь в Storage
    }
    const localPath = resolve(baseDir, ref);
    if (!existsSync(localPath)) {
      fail(`Изображение не найдено: ${localPath} (imageRef=${ref})`);
    }
    const mime = detectMime(localPath);
    if (!mime) {
      fail(`Неподдерживаемый формат изображения: ${localPath} (jpeg/png/webp)`);
    }
    const size = statSync(localPath).size;
    if (size > MAX_IMAGE_BYTES) {
      fail(`Изображение превышает 10MB: ${localPath} (${size} bytes)`);
    }
    images.push({ slide, localPath, mime, size });
  }
  return images;
}

async function uploadImages(supabase, game, images, dryRun) {
  const uploaded = [];
  for (const { slide, localPath, mime, size } of images) {
    const fileName = localPath.split(/[\\/]/).pop();
    const storagePath = `${game.id}/${fileName}`;
    if (dryRun) {
      console.log(`[dry-run] upload ${localPath} -> ${BUCKET}/${storagePath} (${mime}, ${size} bytes)`);
      slide.imageRef = storagePath;
      uploaded.push(storagePath);
      continue;
    }
    const data = readFileSync(localPath);
    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(storagePath, data, { contentType: mime, upsert: true });
    if (error) fail(`Upload ${storagePath}: ${error.message}`);
    console.log(`uploaded ${BUCKET}/${storagePath} (${mime}, ${size} bytes)`);
    slide.imageRef = storagePath;
    uploaded.push(storagePath);
  }
  return uploaded;
}

function nowIso() {
  return new Date().toISOString();
}

async function ensureAggregates(db) {
  const homeRef = db.doc('home_feed/main');
  const sitemapRef = db.doc('sitemap_public/main');
  const homeSnap = await homeRef.get();
  const sitemapSnap = await sitemapRef.get();
  const home = homeSnap.exists ? homeSnap.data() : { carousel: [], vitrine: [], groups: [] };
  const sitemap = sitemapSnap.exists
    ? sitemapSnap.data()
    : { scenarioEntries: [], gameEntries: [] };
  return { homeRef, sitemapRef, home, sitemap };
}

async function publishGame({ project, file, dryRun }) {
  const game = loadGame(file);
  const baseDir = resolve(file, '..');

  // 1. Firebase Admin SDK (запись — service account, A-38).
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
    `import-${project}-${game.id}`,
  );
  const db = getFirestore(app);

  // 2. Supabase (upload изображений, ED-7).
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !supabaseKey) {
    fail('SUPABASE_URL и SUPABASE_SERVICE_ROLE_KEY обязательны (A-40)');
  }
  const { createClient } = require('@supabase/supabase-js');
  const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 3. Уникальность slug (ED-8): другой документ с тем же slug — ошибка.
  const slugQuery = await db
    .collection('games')
    .where('slug', '==', game.slug)
    .get();
  for (const doc of slugQuery.docs) {
    if (doc.id !== game.id) {
      fail(`slug "${game.slug}" уже занят документом games/${doc.id} (ED-8)`);
    }
  }

  // 4. Upload изображений.
  const images = collectImages(game, baseDir);
  await uploadImages(supabase, game, images, dryRun);

  // 5. Запись источника правды games/{id}.
  const now = nowIso();
  const gameDoc = {
    id: game.id,
    slug: game.slug,
    title: game.title,
    ...(game.seoTitle ? { seoTitle: game.seoTitle } : {}),
    ...(game.seoDescription ? { seoDescription: game.seoDescription } : {}),
    playersHint: game.playersHint,
    durationBucket: game.durationBucket,
    ageHint: game.ageHint,
    rulesComplexity: game.rulesComplexity,
    carousel: game.carousel,
    createdAt: game.createdAt ?? now,
    updatedAt: now,
  };
  if (dryRun) {
    console.log(`[dry-run] set games/${game.id}`);
  } else {
    await db.doc(`games/${game.id}`).set(gameDoc, { merge: true });
    console.log(`written games/${game.id}`);
  }

  // 6. Публичный агрегат game_public/{gameId} (A-10, §4.5 SP-E0-01).
  const { homeRef, sitemapRef, home, sitemap } = await ensureAggregates(db);
  const nextVersion = (home.contentVersion ?? 0) + 1;
  const gamePublic = {
    id: game.id,
    slug: game.slug,
    title: game.title,
    ...(game.seoTitle ? { seoTitle: game.seoTitle } : {}),
    ...(game.seoDescription ? { seoDescription: game.seoDescription } : {}),
    playersHint: game.playersHint,
    durationBucket: game.durationBucket,
    ageHint: game.ageHint,
    rulesComplexity: game.rulesComplexity,
    carousel: game.carousel,
    scenarios: [], // связки scenario_games — US-E1-03
    contentVersion: nextVersion,
    updatedAt: now,
  };
  if (dryRun) {
    console.log(`[dry-run] set game_public/${game.id}`);
  } else {
    await db.doc(`game_public/${game.id}`).set(gamePublic);
    console.log(`written game_public/${game.id}`);
  }

  // 7. Зависимые агрегаты: home_feed.carousel и sitemap_public.gameEntries.
  const teaserSlides = game.carousel.filter((s) => s.frameType === 'teaser');
  const homeCarousel = [...(home.carousel ?? [])];
  for (const slide of teaserSlides) {
    if (!homeCarousel.some((s) => s.imageRef === slide.imageRef)) {
      homeCarousel.push(slide);
    }
  }
  const gameEntries = [...(sitemap.gameEntries ?? [])];
  if (!gameEntries.some((e) => e.slug === game.slug)) {
    gameEntries.push({ slug: game.slug, id: game.id });
  }

  if (dryRun) {
    console.log(`[dry-run] set home_feed/main (carousel=${homeCarousel.length})`);
    console.log(`[dry-run] set sitemap_public/main (gameEntries=${gameEntries.length})`);
    console.log('DRY-RUN OK: запись не выполнялась');
    process.exit(0);
  }

  await homeRef.set({
    ...home,
    carousel: homeCarousel,
    contentVersion: nextVersion,
    updatedAt: now,
  });
  console.log(`written home_feed/main (carousel=${homeCarousel.length})`);

  // Удаляем устаревшие поля scenarioSlugs/gameSlugs (контракт v2: entries).
  const { scenarioSlugs, gameSlugs, ...sitemapClean } = sitemap;
  await sitemapRef.set({
    ...sitemapClean,
    gameEntries,
    contentVersion: nextVersion,
    updatedAt: now,
  });
  console.log(`written sitemap_public/main (gameEntries=${gameEntries.length})`);

  console.log(`OK: игра ${game.id} опубликована (${project})`);
}

const args = parseArgs(process.argv.slice(2));
publishGame(args).catch((err) => {
  console.error(`ERROR: ${err.message}`);
  process.exit(1);
});
// Чтение состояния Firestore dev/prod через Admin SDK (SP-E1-01 проверка).
// Использование:
//   node inspect-firestore.mjs <dev|prod>
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

const env = process.argv[2] ?? 'dev';
const PROJECTS = {
  dev: {
    firebaseProjectId: 'scenario-ba26a',
    sa: 'key/scenario-ba26a-firebase-adminsdk-fbsvc-5d7fd734c5.json',
  },
  prod: {
    firebaseProjectId: 'scenario-prod-491c',
    sa: 'key/scenario-prod-491c-firebase-adminsdk-fbsvc-1054a91598.json',
  },
};
const cfg = PROJECTS[env];
if (!cfg) {
  console.error('Укажите dev|prod');
  process.exit(2);
}

const serviceAccount = JSON.parse(readFileSync(cfg.sa, 'utf8'));
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const app = initializeApp(
  { credential: cert(serviceAccount), projectId: cfg.firebaseProjectId },
  `inspect-${env}`,
);
const db = getFirestore(app);

async function dumpCollection(name) {
  const snap = await db.collection(name).get();
  const docs = [];
  snap.forEach((d) => docs.push({ id: d.id, data: d.data() }));
  return docs;
}

async function main() {
  console.log(`=== ${env} (${cfg.firebaseProjectId}) ===`);
  for (const coll of ['games', 'game_public', 'home_feed', 'sitemap_public']) {
    const docs = await dumpCollection(coll);
    console.log(`\n--- ${coll} (${docs.length}) ---`);
    for (const d of docs) {
      console.log(JSON.stringify({ id: d.id, data: d.data }, null, 2));
    }
  }
}

main().catch((err) => {
  console.error(`ERROR: ${err.message}`);
  process.exit(1);
});
// Unit-тесты валидатора игры (SP-E1-01, TC-02/TC-03).
//
// Запуск: node --test test/validate-game.test.mjs
// Покрывает:
//   - TC-01: валидная карусель (≥1 teaser) проходит;
//   - TC-02: карусель без teaser отклоняется с явной ошибкой;
//   - TC-03: неизвестный enum отклоняется (параметризованно по всем enum).

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { validateGame, ENUM_ALLOWLISTS } from '../validate-game.mjs';

function validGame(overrides = {}) {
  return {
    id: 'g1',
    slug: 'game-1',
    title: 'Игра 1',
    seoTitle: 'Игра 1 — настольная игра для компании',
    seoDescription: 'Краткое описание игры для страницы и поисковой выдачи.',
    playersHint: 'players_2_4',
    durationBucket: 'short',
    ageHint: 'age_family',
    rulesComplexity: 'easy',
    carousel: [
      { imageRef: 'games/g1/teaser.jpg', frameType: 'teaser', alt: 'Тизер' },
      { imageRef: 'games/g1/box.jpg', frameType: 'box' },
    ],
    ...overrides,
  };
}

test('TC-01: валидная игра с каруселью (≥1 teaser) проходит', () => {
  const result = validateGame(validGame());
  assert.equal(result.ok, true, result.errors.join('; '));
  assert.deepEqual(result.errors, []);
});

test('TC-02: карусель без teaser отклоняется с явной ошибкой', () => {
  const result = validateGame(
    validGame({
      carousel: [
        { imageRef: 'games/g1/box.jpg', frameType: 'box' },
        { imageRef: 'games/g1/in_play.jpg', frameType: 'in_play' },
      ],
    }),
  );
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((e) => e.includes('frameType=teaser')),
    `ожидалась ошибка про teaser, получено: ${result.errors.join('; ')}`,
  );
});

test('TC-02: пустая карусель отклоняется', () => {
  const result = validateGame(validGame({ carousel: [] }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('не может быть пустым')));
});

test('TC-03: неизвестный enum отклоняется (параметризованно)', () => {
  for (const field of ['playersHint', 'durationBucket', 'ageHint', 'rulesComplexity']) {
    const result = validateGame(validGame({ [field]: 'unknown_value' }));
    assert.equal(result.ok, false, `${field}: ожидалась ошибка`);
    assert.ok(
      result.errors.some((e) => e.startsWith(`${field}:`)),
      `${field}: ожидалась ошибка по полю, получено: ${result.errors.join('; ')}`,
    );
  }
});

test('TC-03: неизвестный frameType отклоняется', () => {
  const result = validateGame(
    validGame({
      carousel: [
        { imageRef: 'games/g1/teaser.jpg', frameType: 'teaser' },
        { imageRef: 'games/g1/x.jpg', frameType: 'unknown' },
      ],
    }),
  );
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('frameType')));
});

test('TC-03: все допустимые enum-ключи проходят', () => {
  for (const field of ['playersHint', 'durationBucket', 'ageHint', 'rulesComplexity']) {
    for (const key of ENUM_ALLOWLISTS[field]) {
      const result = validateGame(validGame({ [field]: key }));
      assert.equal(result.ok, true, `${field}=${key}: ${result.errors.join('; ')}`);
    }
  }
  for (const key of ENUM_ALLOWLISTS.frameType) {
    const result = validateGame(
      validGame({
        carousel: [
          { imageRef: 'games/g1/teaser.jpg', frameType: 'teaser' },
          { imageRef: 'games/g1/x.jpg', frameType: key },
        ],
      }),
    );
    assert.equal(result.ok, true, `frameType=${key}: ${result.errors.join('; ')}`);
  }
});

test('A-30: отсутствие обязательных полей отклоняется', () => {
  for (const field of ['id', 'slug', 'title', 'seoTitle', 'seoDescription', 'playersHint', 'durationBucket', 'ageHint', 'rulesComplexity']) {
    const game = validGame();
    delete game[field];
    const result = validateGame(game);
    assert.equal(result.ok, false, `${field}: ожидалась ошибка`);
    assert.ok(
      result.errors.some((e) => e.startsWith(`${field}:`)),
      `${field}: ожидалась ошибка по полю, получено: ${result.errors.join('; ')}`,
    );
  }
});

test('SP-E1-04: seoTitle/seoDescription с Markdown отклоняются (A-4a)', () => {
  const result = validateGame(validGame({ seoTitle: 'Заголовок **жирным**' }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('seoTitle') && e.includes('plain text')));
});

test('SP-E1-04: превышение лимита длины seoTitle/seoDescription отклоняется', () => {
  const result = validateGame(validGame({ seoDescription: 'x'.repeat(161) }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('seoDescription') && e.includes('160')));
});

test('A-4a: markdown в текстовых полях отклоняется', () => {
  const result = validateGame(validGame({ title: 'Игра **жирным**' }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('plain text')));
});
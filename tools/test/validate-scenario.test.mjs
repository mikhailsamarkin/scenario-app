// Unit-тесты валидатора сценария и связок (SP-E1-03, TC-01/TC-02/TC-03).
//
// Запуск: node --test test/validate-scenario.test.mjs
// Покрывает:
//   - TC-01: валидный сценарий со связками (порядок, shortDescription) проходит;
//   - TC-02: дубль order отклоняется; shortDescription с Markdown отклоняется;
//   - TC-03: неизвестный gameId отклоняется (ссылочная целостность).

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { validateScenario } from '../validate-scenario.mjs';

function validScenario(overrides = {}) {
  return {
    id: 's1',
    slug: 'vecherinka',
    title: 'Вечеринка',
    whyTheseGames: 'Почему эти игры подходят.',
    seoTitle: 'Вечеринка — подборка настольных игр',
    games: [
      {
        gameId: 'g1',
        order: 1,
        shortDescription: 'Описание игры в контексте сценария.',
      },
      {
        gameId: 'g2',
        order: 2,
        shortDescription: 'Вторая игра в контексте сценария.',
      },
    ],
    ...overrides,
  };
}

test('TC-01: валидный сценарий со связками (порядок, shortDescription) проходит', () => {
  const result = validateScenario(validScenario(), ['g1', 'g2']);
  assert.equal(result.ok, true, result.errors.join('; '));
  assert.deepEqual(result.errors, []);
});

test('TC-01: валидный сценарий проходит и без knownGameIds (структурная проверка)', () => {
  const result = validateScenario(validScenario());
  assert.equal(result.ok, true, result.errors.join('; '));
});

test('TC-02: дубль order в пределах сценария отклоняется (CR-4)', () => {
  const result = validateScenario(
    validScenario({
      games: [
        { gameId: 'g1', order: 1, shortDescription: 'Первая.' },
        { gameId: 'g2', order: 1, shortDescription: 'Дубль order.' },
      ],
    }),
  );
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((e) => e.includes('order=1') && e.includes('дублируется')),
    `ожидалась ошибка про дубль order, получено: ${result.errors.join('; ')}`,
  );
});

test('TC-02: дубль gameId в пределах сценария отклоняется', () => {
  const result = validateScenario(
    validScenario({
      games: [
        { gameId: 'g1', order: 1, shortDescription: 'Первая.' },
        { gameId: 'g1', order: 2, shortDescription: 'Дубль gameId.' },
      ],
    }),
  );
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((e) => e.includes('привязана более одного раза')),
    `ожидалась ошибка про дубль gameId, получено: ${result.errors.join('; ')}`,
  );
});

test('TC-02: order не целое или < 1 отклоняется', () => {
  for (const bad of [0, -1, 1.5, '1']) {
    const result = validateScenario(
      validScenario({
        games: [{ gameId: 'g1', order: bad, shortDescription: 'Ок.' }],
      }),
    );
    assert.equal(result.ok, false, `order=${bad}: ожидалась ошибка`);
    assert.ok(
      result.errors.some((e) => e.includes('order')),
      `order=${bad}: ожидалась ошибка по полю, получено: ${result.errors.join('; ')}`,
    );
  }
});

test('TC-02: shortDescription с Markdown отклоняется (A-4a)', () => {
  const result = validateScenario(
    validScenario({
      games: [
        { gameId: 'g1', order: 1, shortDescription: 'Описание **жирным**.' },
      ],
    }),
  );
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((e) => e.includes('plain text')),
    `ожидалась ошибка про plain text, получено: ${result.errors.join('; ')}`,
  );
});

test('TC-03: неизвестный gameId отклоняется (ссылочная целостность)', () => {
  const result = validateScenario(validScenario(), ['g1']);
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((e) => e.includes('не найдена в games')),
    `ожидалась ошибка про неизвестную игру, получено: ${result.errors.join('; ')}`,
  );
});

test('TC-03: отсутствие обязательных полей сценария отклоняется', () => {
  for (const field of ['id', 'slug', 'title', 'whyTheseGames', 'seoTitle']) {
    const scenario = validScenario();
    delete scenario[field];
    const result = validateScenario(scenario);
    assert.equal(result.ok, false, `${field}: ожидалась ошибка`);
    assert.ok(
      result.errors.some((e) => e.startsWith(`${field}:`)),
      `${field}: ожидалась ошибка по полю, получено: ${result.errors.join('; ')}`,
    );
  }
});

test('SP-E1-04: seoTitle с Markdown отклоняется (A-4a)', () => {
  const result = validateScenario(validScenario({ seoTitle: 'Заголовок **жирным**' }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('seoTitle') && e.includes('plain text')));
});

test('SP-E1-04: превышение лимита длины seoTitle отклоняется', () => {
  const result = validateScenario(validScenario({ seoTitle: 'x'.repeat(61) }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('seoTitle') && e.includes('60')));
});

test('SP-E1-04: shareImageUrl не путь и не URL отклоняется', () => {
  const result = validateScenario(validScenario({ shareImageUrl: '**markdown**' }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('shareImageUrl')));
});

test('SP-E1-04: shareImageUrl путь Storage или URL проходит', () => {
  for (const url of ['images/share.jpg', 'https://cdn.example.com/share.jpg']) {
    const result = validateScenario(validScenario({ shareImageUrl: url }));
    assert.equal(result.ok, true, `shareImageUrl=${url}: ${result.errors.join('; ')}`);
  }
});

test('TC-03: отсутствие массива games отклоняется', () => {
  const scenario = validScenario();
  delete scenario.games;
  const result = validateScenario(scenario);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('games')));
});

test('A-4a: Markdown в whyTheseGames отклоняется', () => {
  const result = validateScenario(validScenario({ whyTheseGames: 'Текст **жирным**' }));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('plain text')));
});
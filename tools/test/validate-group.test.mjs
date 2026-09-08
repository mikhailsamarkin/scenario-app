// Unit-тесты валидатора группы смысла (SP-E7-01, TC-01/02/03).
//
// Запуск: node --test test/validate-group.test.mjs
// Покрывает:
//   - TC-01: валидная группа проходит;
//   - TC-02: неизвестный scenarioId отклоняется (ссылочная целостность);
//   - TC-03: дубль сценария и обязательные поля.

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { validateGroup } from '../validate-group.mjs';

function validGroup(overrides = {}) {
  return {
    id: 'vdvoem',
    slug: 'vdvoem',
    title: 'Вдвоём',
    listOrder: 1,
    isPastArchive: false,
    scenarios: [
      { scenarioId: 's1', slug: 'semya', title: 'Семейный вечер' },
      { scenarioId: 's2', slug: 'vecherinka', title: 'Вечеринка' },
    ],
    ...overrides,
  };
}

test('TC-01: валидная группа проходит', () => {
  const result = validateGroup(validGroup(), ['s1', 's2']);
  assert.equal(result.ok, true, result.errors.join('; '));
  assert.deepEqual(result.errors, []);
});

test('TC-02: неизвестный scenarioId отклоняется (ссылочная целостность)', () => {
  const result = validateGroup(validGroup(), ['s1']);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.includes('не найден')));
});

test('TC-03: обязательные поля и дубль сценария', () => {
  const missing = validateGroup({ scenarios: [] });
  assert.equal(missing.ok, false);
  assert.ok(missing.errors.some((e) => e.includes('title')));

  const dup = validateGroup(
    validGroup({
      scenarios: [
        { scenarioId: 's1', slug: 'semya', title: 'Семейный вечер' },
        { scenarioId: 's1', slug: 'semya', title: 'Семейный вечер' },
      ],
    }),
    ['s1'],
  );
  assert.equal(dup.ok, false);
  assert.ok(dup.errors.some((e) => e.includes('дублируется')));
});
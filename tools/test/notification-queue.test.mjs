// Unit-тесты очереди уведомлений (SP-E1-05, TC-01/TC-02/TC-03).
//
// Запуск: node --test test/notification-queue.test.mjs
// Покрывает:
//   - TC-01: первая публикация создаёт запись очереди (A-31);
//   - TC-02: смена только состава игр у опубликованного не создаёт событие (A-33);
//   - TC-03: запись валидируется по схеме (ED-11).

import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  isFirstPublication,
  buildDailyQueueRecord,
  validateQueueRecord,
} from '../notification-queue.mjs';

test('TC-01: первичная публикация (документа нет) — первая публикация', () => {
  const next = { id: 's1', published: true };
  assert.equal(isFirstPublication(null, next), true);
});

test('TC-01: переход из черновика (published false -> true) — первая публикация', () => {
  const previous = { id: 's1', published: false };
  const next = { id: 's1', published: true };
  assert.equal(isFirstPublication(previous, next), true);
});

test('TC-02: републикация уже опубликованного — не первая публикация (A-33)', () => {
  const previous = { id: 's1', published: true };
  const next = { id: 's1', published: true };
  assert.equal(isFirstPublication(previous, next), false);
});

test('TC-02: сценарий не публикуется — не первая публикация', () => {
  const next = { id: 's1', published: false };
  assert.equal(isFirstPublication(null, next), false);
});

test('TC-01: buildDailyQueueRecord заполняет lastScenarioId и updatedAt', () => {
  const record = buildDailyQueueRecord('s1', '2026-09-07T08:00:00.000Z');
  assert.deepEqual(record, {
    lastScenarioId: 's1',
    updatedAt: '2026-09-07T08:00:00.000Z',
  });
});

test('TC-03: валидная запись проходит валидацию', () => {
  const record = buildDailyQueueRecord('s1', '2026-09-07T08:00:00.000Z');
  const result = validateQueueRecord(record);
  assert.equal(result.ok, true, result.errors.join('; '));
  assert.deepEqual(result.errors, []);
});

test('TC-03: отсутствие lastScenarioId отклоняется', () => {
  const result = validateQueueRecord({ updatedAt: '2026-09-07T08:00:00.000Z' });
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.startsWith('lastScenarioId:')));
});

test('TC-03: отсутствие updatedAt отклоняется', () => {
  const result = validateQueueRecord({ lastScenarioId: 's1' });
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => e.startsWith('updatedAt:')));
});

test('TC-03: не-объект отклоняется', () => {
  const result = validateQueueRecord(null);
  assert.equal(result.ok, false);
});
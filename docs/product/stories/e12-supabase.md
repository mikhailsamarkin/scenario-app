---
story_id: US-E12-05
title: "Применение supabase (supabase/agent-skills): Storage-политики, RLS и миграции"
epic: "E12"
status: drafted
bt_refs: []
st_refs: [A-5, A-39]
ed_refs: [ED-7, ED-14, ADR-011]
source_story: |
  Как команда, я хочу применить официальный skill supabase/agent-skills (supabase) к использованию Supabase в Scenario (медиа в Storage, БД, миграции), чтобы политики доступа, миграции и security-чеклист были проверены и приведены к рекомендованным практикам без изменения поведения приложения и сайта.
updated: "2026-09-16"
---

# Применение supabase (supabase/agent-skills): Storage-политики, RLS и миграции

## Ценность

Scenario хранит медиа (изображения карусели, OG-картинки) в **Supabase Storage**, бакет `games` (**A-5**, **ED-14**): МП читает их через `supabase_flutter`, сайт — по публичным URL. Также в репозитории есть `scenario/supabase/migrations` (таблица `keepalive` с RLS) и описан bucket env в `docs/environments.md`. Официальный skill **`supabase`** (repo `supabase/agent-skills`) покрывает Database/RLS/миграции, Auth, Edge Functions, Realtime, Storage, Vectors, Cron, Queues, включает security-чеклист и CLI/MCP для схемы, миграций и security-аудита.

Эта стори применяет skill, чтобы проверить Storage-политики (**A-39**), воспроизводимость миграций и отсутствие привилегированных ключей в клиентах, не меняя поведение.

> ℹ️ Примеры клиентского кода в скилле ориентированы на `supabase-js` / `@supabase/ssr` (JS) — напрямую применимы к `scenario-site`; для Flutter (`supabase_flutter`) берём части про БД, Storage, миграции и чеклист, а не JS-сниппеты.

## Контекст и трассировка

| ID | Документ / ссылка | Как используется в этой стори |
|----|-------------------|-------------------------------|
| Skill | `supabase` (github.com/supabase/agent-skills) | Источник требований к Storage/DB/миграциям и security-чеклисту |
| US-E1-01 | Стори | Загрузка изображений в Storage (**ED-7**) |
| US-E10-01…03 | Стори | Сайт читает публичные URL Supabase Storage |
| A-5 | СТ | Медиа — Supabase Storage, Storage policies (RLS) |
| A-39 | СТ | Storage Rules: публичный read только одобренных путей; загрузка — сервисный аккаунт / signed URL |
| ED-7 | ED | Прямой upload в Supabase Storage |
| ED-14 | ED | Отказ от Firebase Storage |
| ADR-011 | ED | Security Rules + Storage Rules |

## Детали поведения

- Запустить skill и следовать его инструкциям:
  ```bash
  npx skills use "https://github.com/supabase/agent-skills" --skill "supabase"
  ```
- **Прочитать полный вывод скилла** (при необходимости сначала перенаправить его в временный файл).
- **Относительные пути резолвить от каталога supporting-files**, который вернёт скилл (а не от корня проекта).
- Учесть Core Principles скилла: сверяться с changelog и актуальной документацией Supabase; после правок выполнять проверочный запрос; не зацикливаться на ошибках.
- Провести ревизию Supabase в проекте:
  - **Storage**: бакет `games` (**A-5**) — публичный read только для одобренных путей (`games/{id}/**`), запись только сервисным аккаунтом/через signed URL (**A-39**); никаких service-role ключей в клиентах МП и сайта.
  - **Миграции**: `scenario/supabase/migrations` воспроизводимы и применены на dev/prod; таблица `keepalive` с RLS + SELECT для `anon` соответствует `docs/environments.md`.
  - **RLS/БД**: доступ к таблицам не шире, чем требует контракт; при необходимости прогнать security-advisor/аудит через Supabase CLI/MCP.
- Зафиксировать выявленные расхождения и привести к рекомендациям скилла.
- **Поведение не меняется:** медиа в МП и на сайте отдаётся как раньше.

## Вне scope

- Firebase/Firestore и его правила — вне этой стори (см. **ADR-010/ADR-011**).
- Смена провайдера медиа (S3/CDN, **A-5a**).
- Новый медиаконтент и изменение схемы Firestore.

## Критерии приёмки (AC)

- **AC-01**
  - Given репозиторий `scenario`
  - When выполнен запуск `npx skills use "https://github.com/supabase/agent-skills" --skill "supabase"` и прочитан его полный вывод
  - Then инструкции скилла применены, относительные пути резолвятся от supporting-files.

- **AC-02**
  - Given бакет `games`, миграции и клиентский код МП/сайта
  - When завершена ревизия
  - Then Storage-политики соответствуют **A-39**, миграции воспроизводимы, RLS не шире контракта, привилегированных ключей в клиентах нет, замечания security-чеклиста скилла закрыты или зафиксированы.

- **AC-03**
  - Given внесённые изменения
  - When запущены `flutter analyze` / `flutter test` и сборка `scenario-site`
  - Then ошибок нет, тесты/сборка зелёные, изображения отдаются как раньше.

## Зависимости и блокеры

- Доступ в сеть для `npx skills use`; Supabase CLI и доступ к проектам Supabase dev/prod (ревизия read-only, деплой политик/миграций отдельно).
- Node.js/npx в окружении разработчика.
- Skill написан под JS-клиенты; Dart-часть (`supabase_flutter`) в скилле не покрыта — применять концептуально.

## Открытые вопросы

- Ограничиться Storage + миграциями или включить в scope Auth/Realtime/Cron/Queues (сейчас в продукте не используются)?
- Деплоить миграции и Storage-политики из CI?
- Нужен ли регулярный security-аудит Supabase (advisor) в регламенте?

## Примечания для downstream

- При изменениях обновить `docs/environments.md` и, при необходимости, `supabase/README`.
- После правок политик проверить загрузку изображений в МП и на сайте (`scenario-e2e`).

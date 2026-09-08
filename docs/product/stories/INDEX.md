# Индекс user stories (product)

Навигация по артефактам в этой папке. Источник нумерации и эпиков: [use-cases-and-user-stories.md](../../use-cases-and-user-stories.md) §4.

| Колонка | Смысл |
|--------|--------|
| **ID** | `story_id` в frontmatter файла |
| **Сторя** | краткое название; полный заголовок — внутри файла |

## E0. Фундамент и контракт данных

| ID | Сторя | Файл |
|----|--------|------|
| US-E0-01 | Схема коллекций и публичных агрегатов для единого контракта МП и Next.js | [e0-schema-public-aggregates-contract.md](e0-schema-public-aggregates-contract.md) |
| US-E0-02 | Окружения Firebase dev/staging и production | [e0-firebase-dev-prod-environments.md](e0-firebase-dev-prod-environments.md) |

## E1. Публикация контента экспертом

| ID | Сторя | Файл |
|----|--------|------|
| US-E1-01 | Создание игры с каруселью и валидацией полей | [e1-expert-create-game-carousel.md](e1-expert-create-game-carousel.md) |
| US-E1-02 | Сценарий с «почему эти игры подходят» и витриной | [e1-expert-scenario-why-these-games.md](e1-expert-scenario-why-these-games.md) |
| US-E1-03 | Привязка игр к сценарию: порядок и shortDescription | [e1-expert-scenario-games-order-short-description.md](e1-expert-scenario-games-order-short-description.md) |
| US-E1-04 | Поля шаринга и SEO для сценария и игры | [e1-expert-sharing-seo-fields.md](e1-expert-sharing-seo-fields.md) |
| US-E1-05 | Очередь уведомлений при первой публикации сценария | [e1-publish-queue-notification-event.md](e1-publish-queue-notification-event.md) |

## E2. МП: ядро навигации и контента

| ID | Сторя | Файл |
|----|--------|------|
| US-E2-01 | Главный экран: витрина сценариев | [e2-home-scenario-showcase.md](e2-home-scenario-showcase.md) |
| US-E2-02 | Экран сценария: порядок блоков (обоснование → список игр) | [e2-scenario-screen-block-order.md](e2-scenario-screen-block-order.md) |
| US-E2-03 | Экран игры: карусель, характеристики, краткое описание в контексте сценария | [e2-game-screen-carousel-characteristics.md](e2-game-screen-carousel-characteristics.md) |
| US-E2-04 | Обновление контента при наличии сети | [e2-online-content-refresh.md](e2-online-content-refresh.md) |
| US-E2-05 | Офлайн: открытие ранее загруженного контента | [e2-offline-cached-content.md](e2-offline-cached-content.md) |
| US-E2-06 | Производительность карусели и кэш изображений | [e2-carousel-image-cache-performance.md](e2-carousel-image-cache-performance.md) |
| US-E2-07 | Склейка МП: точка входа и навигация Home → Scenario → Game | [e2-mp-entry-navigation.md](e2-mp-entry-navigation.md) |

## E3. Онбординг и push

| ID | Сторя | Файл |
|----|--------|------|
| US-E3-01 | Онбординг: ценность «ситуация → игры» | [e3-onboarding-value-proposition.md](e3-onboarding-value-proposition.md) |
| US-E3-02 | Подписка на уведомления о новых сценариях | [e3-push-subscribe-new-scenarios.md](e3-push-subscribe-new-scenarios.md) |
| US-E3-03 | Не больше одного push в сутки в 11:00 МСК | [e3-daily-push-11msk.md](e3-daily-push-11msk.md) |
| US-E3-04 | Deep link из push на экран сценария | [e3-push-deeplink-scenario.md](e3-push-deeplink-scenario.md) |

## E4. Сайт SSG: SEO и CTA в МП

| ID | Сторя | Файл |
|----|--------|------|
| US-E4-01 | ЧПУ и метаданные страниц сценария и игры | [e4-seo-urls-scenario-game.md](e4-seo-urls-scenario-game.md) |
| US-E4-02 | Перелинковка сценариев и игр на сайте | [e4-site-internal-linking.md](e4-site-internal-linking.md) |
| US-E4-03 | CTA установки мобильного приложения | [e4-cta-install-app.md](e4-cta-install-app.md) |
| US-E4-04 | Предсказуемый билд SSG: бюджет запросов к Firestore | [e4-ssg-build-query-budget.md](e4-ssg-build-query-budget.md) |
| US-E4-05 | Core Web Vitals и производительность сайта | [e4-core-web-vitals.md](e4-core-web-vitals.md) |

## E5. Шаринг и универсальные ссылки

| ID | Сторя | Файл |
|----|--------|------|
| US-E5-01 | Поделиться сценарием через системный share | [e5-share-scenario-system-share.md](e5-share-scenario-system-share.md) |
| US-E5-02 | Universal Links / App Links: открытие сценария в приложении | [e5-universal-links-app.md](e5-universal-links-app.md) |
| US-E5-03 | Веб-fallback: OG и сохранение UTM | [e5-web-fallback-og-utm.md](e5-web-fallback-og-utm.md) |
| US-E5-04 | Аналитика воронки шаринга | [e5-share-funnel-analytics.md](e5-share-funnel-analytics.md) |

## E6. Аналитика, приватность, стабильность

| ID | Сторя | Файл |
|----|--------|------|
| US-E6-01 | Именованная схема событий аналитики в МП | [e6-analytics-events-schema.md](e6-analytics-events-schema.md) |
| US-E6-02 | Открытия сценария с разбивкой по source и scenario_id | [e6-scenario-opens-by-source.md](e6-scenario-opens-by-source.md) |
| US-E6-03 | События block_view с порогом viewport | [e6-block-view-events.md](e6-block-view-events.md) |
| US-E6-04 | Ссылка на политику конфиденциальности в МП | [e6-privacy-policy-link.md](e6-privacy-policy-link.md) |
| US-E6-05 | Crashlytics: отчёты о сбоях | [e6-crashlytics.md](e6-crashlytics.md) |
| US-E6-06 | Принудительное обновление через Remote Config | [e6-force-update-remote-config.md](e6-force-update-remote-config.md) |

## E7. Масштаб каталога (после MVP)

| ID | Сторя | Файл |
|----|--------|------|
| US-E7-01 | Группы смысла на главном экране | [e7-meaning-groups-home.md](e7-meaning-groups-home.md) |
| US-E7-02 | «Сценарии прошлого» для снятых с витрины подборок | [e7-past-scenarios-archive.md](e7-past-scenarios-archive.md) |

## E8. Инфраструктура и релиз (после MVP)

| ID | Сторя | Файл |
|----|--------|------|
| US-E8-01 | Конфигурация Universal Links на домене (AASA / assetlinks) | [e8-universal-links-domain-config.md](e8-universal-links-domain-config.md) |
| US-E8-02 | Страница политики конфиденциальности на сайте | [e8-privacy-policy-page.md](e8-privacy-policy-page.md) |
| US-E8-03 | Валидация текста политики конфиденциальности тех. лидом | [e8-privacy-policy-text-validation.md](e8-privacy-policy-text-validation.md) |
| US-E8-04 | Реализация экрана принудительного обновления (политика и CTA) | [e8-force-update-screen.md](e8-force-update-screen.md) |

## Спецификации реализации

| ID | Спека | Сторя |
|----|-------|-------|
| SP-E0-01 | [e0-schema-public-aggregates-contract.md](../specs/e0-schema-public-aggregates-contract.md) | US-E0-01 |
| SP-E0-02 | [e0-firebase-dev-prod-environments.md](../specs/e0-firebase-dev-prod-environments.md) | US-E0-02 |
| SP-E1-01 | [e1-expert-create-game-carousel.md](../specs/e1-expert-create-game-carousel.md) | US-E1-01 |
| SP-E1-02 | [e1-expert-scenario-why-these-games.md](../specs/e1-expert-scenario-why-these-games.md) | US-E1-02 |
| SP-E1-03 | [e1-expert-scenario-games-order-short-description.md](../specs/e1-expert-scenario-games-order-short-description.md) | US-E1-03 |
| SP-E1-04 | [e1-expert-sharing-seo-fields.md](../specs/e1-expert-sharing-seo-fields.md) | US-E1-04 |
| SP-E1-05 | [e1-publish-queue-notification-event.md](../specs/e1-publish-queue-notification-event.md) | US-E1-05 |
| SP-E2-01 | [e2-home-scenario-showcase.md](../specs/e2-home-scenario-showcase.md) | US-E2-01 |
| SP-E2-02 | [e2-scenario-screen-block-order.md](../specs/e2-scenario-screen-block-order.md) | US-E2-02 |
| SP-E2-03 | [e2-game-screen-carousel-characteristics.md](../specs/e2-game-screen-carousel-characteristics.md) | US-E2-03 |
| SP-E2-04 | [e2-online-content-refresh.md](../specs/e2-online-content-refresh.md) | US-E2-04 |
| SP-E2-05 | [e2-offline-cached-content.md](../specs/e2-offline-cached-content.md) | US-E2-05 |
| SP-E2-06 | [e2-carousel-image-cache-performance.md](../specs/e2-carousel-image-cache-performance.md) | US-E2-06 |
| SP-E2-07 | [e2-mp-entry-navigation.md](../specs/e2-mp-entry-navigation.md) | US-E2-07 |
| SP-E3-01 | [e3-onboarding-value-proposition.md](../specs/e3-onboarding-value-proposition.md) | US-E3-01 |
| SP-E3-02 | [e3-push-subscribe-new-scenarios.md](../specs/e3-push-subscribe-new-scenarios.md) | US-E3-02 |
| SP-E3-03 | [e3-daily-push-11msk.md](../specs/e3-daily-push-11msk.md) | US-E3-03 |
| SP-E3-04 | [e3-push-deeplink-scenario.md](../specs/e3-push-deeplink-scenario.md) | US-E3-04 |
| SP-E4-01 | [e4-seo-urls-scenario-game.md](../specs/e4-seo-urls-scenario-game.md) | US-E4-01 |
| SP-E4-02 | [e4-site-internal-linking.md](../specs/e4-site-internal-linking.md) | US-E4-02 |
| SP-E4-03 | [e4-cta-install-app.md](../specs/e4-cta-install-app.md) | US-E4-03 |
| SP-E4-04 | [e4-ssg-build-query-budget.md](../specs/e4-ssg-build-query-budget.md) | US-E4-04 |
| SP-E4-05 | [e4-core-web-vitals.md](../specs/e4-core-web-vitals.md) | US-E4-05 |
| SP-E5-01 | [e5-share-scenario-system-share.md](../specs/e5-share-scenario-system-share.md) | US-E5-01 |
| SP-E5-02 | [e5-universal-links-app.md](../specs/e5-universal-links-app.md) | US-E5-02 |
| SP-E5-03 | [e5-web-fallback-og-utm.md](../specs/e5-web-fallback-og-utm.md) | US-E5-03 |
| SP-E5-04 | [e5-share-funnel-analytics.md](../specs/e5-share-funnel-analytics.md) | US-E5-04 |
| SP-E6-01 | [e6-analytics-events-schema.md](../specs/e6-analytics-events-schema.md) | US-E6-01 |
| SP-E6-02 | [e6-scenario-opens-by-source.md](../specs/e6-scenario-opens-by-source.md) | US-E6-02 |
| SP-E6-03 | [e6-block-view-events.md](../specs/e6-block-view-events.md) | US-E6-03 |
| SP-E6-04 | [e6-privacy-policy-link.md](../specs/e6-privacy-policy-link.md) | US-E6-04 |
| SP-E6-05 | [e6-crashlytics.md](../specs/e6-crashlytics.md) | US-E6-05 |
| SP-E6-06 | [e6-force-update-remote-config.md](../specs/e6-force-update-remote-config.md) | US-E6-06 |

---

**Всего:** 35 стори. Шаблон артефакта: [.cursor/skills/product-owner-lead/SKILL.md](../../../.cursor/skills/product-owner-lead/SKILL.md).

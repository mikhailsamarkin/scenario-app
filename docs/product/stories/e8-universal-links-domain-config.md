---
story_id: US-E8-01
title: "Конфигурация Universal Links на домене (AASA / assetlinks)"
epic: "E8"
status: drafted
bt_refs: [FR-M-7]
st_refs: [A-23, A-24]
ed_refs: []
source_story: |
  Как владелец продукта, я хочу настроить AASA (iOS) и assetlinks (Android) для домена scenario-games.ru, чтобы HTTPS-ссылки открывали сценарий в установленном МП.
updated: "2026-09-07"
---

# Конфигурация Universal Links на домене (AASA / assetlinks)

## Ценность

Клиентская обработка Universal Links реализована (US-E5-02), но без конфигурации на домене ссылки не будут перехватываться установленным приложением. Эта стори выкладывает AASA (iOS) и assetlinks (Android) на домен `scenario-games.ru`, чтобы HTTPS-ссылки на сценарий открывали приложение (**A-24**, **FR-M-7**).

## Контекст и трассировка

| ID | Документ | Как используется в этой стори |
|----|----------|-------------------------------|
| A-23 | СТ | Домен `scenario-games.ru`, URL сценария |
| A-24 | СТ | AASA / assetlinks, universal links |
| FR-M-7 | БТ | Шаринг и открытие |

## Детали поведения

- **iOS**: файл `apple-app-site-association` (AASA) на домене `scenario-games.ru` с указанием bundle id приложения.
- **Android**: файл `assetlinks.json` + intent-filter на HTTPS, связывающий домен с package name приложения.
- Ссылка `https://scenario-games.ru/scenario/{slug}` открывает приложение на экране сценария.

## Вне scope

- Клиентская обработка ссылок в МП — **US-E5-02** (реализована).
- Веб-fallback — **US-E5-03** (реализован).

## Критерии приёмки (AC)

- **AC-01** *(СТ A-24)*  
  - Given МП установлен  
  - When пользователь открывает HTTPS-ссылку на сценарий  
  - Then запускается приложение с нужным `scenarioId`.

- **AC-02** *(СТ A-23)*  
  - Given конфигурация домена  
  - When проверка ассоциации  
  - Then AASA/assetlinks валидны для стора/устройства.

## Зависимости и блокеры

- Доступ к DNS домена `scenario-games.ru`.
- Доступ к Apple App Store (AASA) и Google Play (assetlinks).
- SSL на домене.
- Билд с корректными bundle id / package name.

## Открытые вопросы

- Точные bundle id / package name для AASA/assetlinks (согласовать с релизом).

## Примечания для downstream

- Координация с веб-редиректами **A-25** в **US-E5-03**.
- Требует реального домена и доступа к сторам — вне автоматизации.
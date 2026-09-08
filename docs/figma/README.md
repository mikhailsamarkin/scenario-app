# Figma-макеты Scenario — обзор

Источник: [Figma-файл «Scenario»](https://www.figma.com/design/VBLmTqD6teTm3g8AJlU6mw/Scenario?node-id=0-1&p=f)
(файл открыт публично, просмотр без авторизации).

Изучено 2026-09-08 (по скриншотам фреймов; точные значения inspect'ом в Figma
не снимались — см. «Открытые вопросы»).

## Состав файла

6 фреймов мобильных экранов, один горизонтальный ряд:

| # | Фрейм (подпись в Figma) | Разбор | Скриншот |
|---|---|---|---|
| 1 | `onboarding 1.1` | [screens/onboarding.md#экран-1](screens/onboarding.md) | [images/onboarding-1.png](images/onboarding-1.png) |
| 2 | `onboarding 2.1` | [screens/onboarding.md#экран-2](screens/onboarding.md) | [images/onboarding-2.png](images/onboarding-2.png) |
| 3 | `onboarding 3.1` | [screens/onboarding.md#экран-3-push](screens/onboarding.md) | [images/onboarding-3.png](images/onboarding-3.png) |
| 4 | `home` | [screens/home.md](screens/home.md) | [images/home.png](images/home.png) |
| 5 | `экран сценария` | [screens/scenario.md](screens/scenario.md) | [images/scenario.png](images/scenario.png) |
| 6 | `экран игры` | [screens/game.md](screens/game.md) | [images/game.png](images/game.png) |

Дополнительно: [visual-descriptions.md](visual-descriptions.md) — сырые
визуальные описания каждого фрейма (фотоконтент, композиция, все наблюдения).

Это **визуальный редизайн существующих экранов** (E2/E3), а не новая
функциональность. Единственное изменение данных — категории сценариев
(см. [data-changes.md](data-changes.md)).

## Дизайн-система

Общие токены, наблюдаемые по всем экранам — [design-tokens.md](design-tokens.md).

## Что делать с этим дальше

1. Оформить спеку редизайна по workflow (`scenario-spec-workflow`) —
   вероятно, новая стори «UI-редизайн» или ревизия существующих US-E2-*/US-E3-*.
2. Реализация по критическому пути из [implementation-notes.md](implementation-notes.md):
   контракт (категории) → дизайн-система → онбординг → home → сценарий → игра.

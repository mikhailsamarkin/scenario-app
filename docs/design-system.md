# Дизайн-система Scenario

Документация дизайн-системы для переиспользования: Flutter-приложение,
сайт (Next.js), новые агентские сессии. Код — `lib/design/` (SP-E9-01);
первоисточник макетов — Figma «Scenario» и разбор в
[figma/](figma/README.md) (screens/, design-tokens.md, visual-descriptions.md).

> **Статус токенов.** Значения — приближения по скриншотам макетов
> (Dev Mode был недоступен). Все они собраны в одном месте и меняются
> одной правкой после ревизии из Figma. Для сайта значения можно брать
> из блока «Портируемые токены» ниже.

---

## 1. Состав модуля (`lib/design/`)

| Файл | Назначение |
|---|---|
| `app_colors.dart` | `AppColors` — все цвета приложения |
| `app_typography.dart` | `AppTypography` — текстовые стили (serif-заголовки + sans-текст) |
| `app_theme.dart` | `AppTheme.light()` — тема MaterialApp для контентных экранов |
| `labels.dart` | Подписи на русском для полей контракта + склонения |
| `widgets.dart` | Общие виджеты (см. §5) |

Подключение шрифта — `pubspec.yaml` (секция `flutter: fonts:`),
файл `assets/fonts/PlayfairDisplay-VariableFont_wght.ttf` (OFL,
`assets/fonts/OFL.txt`). Семейство в коде: `'PlayfairDisplay'`.

Правило: **никаких цветов/размеров inline в экранах**, только константы
`AppColors`/`AppTypography` (допустимы `Colors.white` на акцентных кнопках).
Экраны онбординга и контента не используют `ThemeData.dark` — тёмные экраны
красятся явными цветами.

---

## 2. Цвета

| Токен | HEX | Использование |
|---|---|---|
| `bgDark` | `#2B2433` | фон онбординга, плейсхолдеры фото, затемнение hero |
| `headerPurple` | `#5F2B4E` | основная полоса шапки home; seed-цвет темы |
| `headerPlum` | `#46203C` | тонкая верхняя полоса шапки home |
| `bgCream` | `#F6F0E6` | фон контентных экранов (home/сценарий/игра/группа) |
| `bgCreamAlt` | `#EFE7D9` | чередование секций («почему подходят», «описание»), разделители |
| `terracotta` | `#C4785B` | акцент: капс-надзаголовки, основные кнопки, активные точки, «Редакторский выбор» |
| `cardLavender` | `#ECE4F2` | карточки игр, плитки характеристик 2×2 |
| `chipLavender` | `#DFD4EC` | чипсы на карточках, рамки пилюль, плейсхолдеры превью |
| `buttonDark` | `#4A4153` | вторичная тёмная кнопка («Начать без уведомлений») |
| `textOnDark` | `#F4EFEA` | текст на тёмном |
| `textMutedOnDark` | `#B5AABA` | приглушённый текст на тёмном (подтексты онбординга) |
| `textOnLight` | `#2B2433` | основной текст на светлом |
| `textMutedOnLight` | `#7C6E85` | подписи характеристик, шевроны |
| `heroGradient` | `#2B2433` прозрачный → `CC` (80%) | градиент затемнения низа фото |

### Портируемые токены (CSS-переменные для сайта)

```css
:root {
  --bg-dark: #2B2433;
  --header-purple: #5F2B4E;
  --header-plum: #46203C;
  --bg-cream: #F6F0E6;
  --bg-cream-alt: #EFE7D9;
  --accent-terracotta: #C4785B;
  --card-lavender: #ECE4F2;
  --chip-lavender: #DFD4EC;
  --button-dark: #4A4153;
  --text-on-dark: #F4EFEA;
  --text-muted-on-dark: #B5AABA;
  --text-on-light: #2B2433;
  --text-muted-on-light: #7C6E85;
  --font-display: 'Playfair Display', Georgia, serif;
}
```

---

## 3. Типографика

Заголовки — Playfair Display (переменный, weight 400–900); текст — системный
sans платформы. Стили задаются константами (не через `Theme.of(context)`).

| Стиль | Параметры | Где |
|---|---|---|
| `logo` | serif 30/w700, onDark | логотип «Scenario» в шапке home |
| `displayOnDark` | serif 34/w600 | «Что сегодня?» |
| `subtitleOnDark` | sans 16, mutedOnDark | подзаголовок шапки |
| `displayOnLight` | serif 32/w600, onLight | название игры на светлом |
| `displayOnPhoto` | serif 32/w600, onDark, maxLines 2 | заголовок hero поверх фото |
| `onboardingTitle` | serif 30/w600, onDark, height 1.25 | шаги онбординга |
| `onboardingBody` | sans 16/h1.45, mutedOnDark | подтексты онбординга |
| `caps(color)` | sans 13/w700, letterSpacing 2.2 | капс-надзаголовки (по умолчанию терракота) |
| `bodyOnLight` | sans 16/h1.45, onLight | основной текст на светлом |
| `scenarioIntro` | serif italic 20/h1.4 | интро сценария (subtitle) |
| `cardTitleOnPhoto` | sans 18/w700, onDark | названия на фото-карточках |
| `cardCategoryOnPhoto` | caps 12/w700, ls 1.8, терракота | категория на фото-карточках |
| `cardTitleOnLight` | sans 18/w700, onLight | названия на лавандовых карточках |

Капс-текст пишется в обычном регистре и приводится к верхнему
(`CapsHeader` делает `toUpperCase()` сам) — тесты ищут ЗАГЛАВНЫЕ варианты.

---

## 4. Формы, размеры, конвенции

| Элемент | Значение |
|---|---|
| Скругление фото-карточек | 16 |
| Скругление кнопок | 14 |
| Скругление плиток характеристик | 14 |
| Скругление превью в карточке игры | 12 |
| Чипсы/пилюли | Stadium (полное скругление) |
| Горизонтальный паддинг контента | 24 |
| Hero: сценарий | высота 420 |
| Hero: игра (карусель) | высота 430 |
| Карточка витрины (large) | 240×340 |
| Карточка группы (compact) | 176×256 |
| Превью в карточке игры | 84×84, radius 12 |
| Кнопки на всю ширину | `SizedBox(width: double.infinity)` + вертикальный паддинг 16 |
| Точки-индикаторы | активная 28×8 терракота, неактивная 8×8 белый 40% |

Пока размеры зашиты в виджетах `widgets.dart` — при появлении второго
потребителя (сайт) ориентироваться на эту таблицу; централизация
в spacing-токены — по мере необходимости.

---

## 5. Общие виджеты (`lib/design/widgets.dart`)

### `HeroBlock` — фото во всю ширину с затемнением

```dart
HeroBlock(
  imageRef: scenario.imageRef,     // ref из Supabase; null → тёмный плейсхолдер
  height: 420,
  category: category?.toUpperCase(), // капс над заголовком
  title: scenario.title,
  onBack: () => Navigator.of(context).maybePop(),
  overlayChild: ...,               // слой поверх (точки карусели)
  bottomContent: ...,              // контент в затемнённой зоне
)
```

Затемнение — градиент с 45% высоты. Кнопка «назад» — белая стрелка
в SafeArea сверху слева.

### `CapsHeader` — капс-заголовок секции

```dart
const CapsHeader('Почему эти игры подходят');              // тёмный
const CapsHeader('Редакторский выбор', color: AppColors.terracotta);
```

### `DotsIndicator` — точки (онбординг, карусель)

```dart
DotsIndicator(count: slides.length, activeIndex: page)
```

### `ScenarioPhotoCard` — фото-карточка сценария

```dart
const ScenarioPhotoCard.large(key: ..., title: card.title, imageRef: card.imageRef, onTap: ...)
const ScenarioPhotoCard.compact(...)
```

Фото + градиент + опциональная капс-категория + заголовок. `onTap` —
через внешний `GestureDetector`. Для тапов в тестах задавать `key`.

### `GameListCard` — карточка игры в списке сценария

```dart
GameListCard(
  title: game.title,
  imageRef: game.imageRef,
  chips: ['2–4 игр.', 'Короткая партия', 'Быстро объяснить'],
  onTap: ...,
)
```

Лавандовая плашка: превью 84×84, заголовок, чипсы-пилюли, шеврон.

### `CharacteristicTile` — плитка «КРАТКО»

```dart
CharacteristicTile(icon: Icons.group_outlined, label: 'Игроки', value: '2–4')
```

Сетка 2×2: два `Row` с `Expanded` + промежуток 12.

### `PillButton` — пилюля

```dart
PillButton(onPressed: share, child: ...);            // белая с рамкой chipLavender
const PillButton.photoBadge(child: Text(caption));   // тёмная полупрозрачная, без тапа
```

---

## 6. Подписи данных (`lib/design/labels.dart`)

Контракт хранит ключи; русский UI — здесь (ED-2):

- `durationBucketLabel(DurationBucket)` → «Разминка / Короткая партия /
  Партия на вечер / Долгая партия / На весь вечер»;
- `rulesComplexityLabel(RulesComplexity)` → «Быстро объяснить /
  Средняя сложность / Нужно вникнуть»;
- `playersChipLabel(PlayersHint)` → «2–4 игр.» (формулировка чипса из макета);
- `gamesPlural(n)` → «игра / игры / игр» (счётчик «В ПОДБОРКЕ · N …»).

`PlayersHint.uiLabel` («2–4») и `AgeHint.uiLabel` («Семейные») живут в
`lib/data/contract/enums.dart` — не дублировать.

---

## 7. Тема MaterialApp (`lib/design/app_theme.dart`)

`AppTheme.light()` — для контентных экранов: `colorScheme` от
`headerPurple`, `scaffoldBackgroundColor = bgCream`, стиль AppBar
(кремовый, без тени) и `FilledButton` (терракота, белый жирный текст,
radius 14, вертикальный паддинг 16). Подключена в `app.dart`
(`MaterialApp(theme: AppTheme.light())`).

Тёмный онбординг в тему **не** входит — `Scaffold(backgroundColor: AppColors.bgDark)`
+ явные стили. Сетевые изображения — только через `CachedNetworkImageWidget`
(`lib/cache/`, ADR-004–009), URL — `supabasePublicUrl(ref)`.

---

## 8. Композиция экранов (паттерны)

- **Онбординг** (тёмный): `SafeArea` + `Stack` — «Пропустить» в правом
  верхнем углу, контент прижат к низу: точки → капс → serif-заголовок →
  текст → кнопки во всю ширину. Верхняя половина — резерв под иллюстрацию
  (ассеты не экспортированы).
- **Контентные экраны** (кремовые): `ListView(padding: zero)` сверху вниз:
  hero → секции с чередованием `bgCream`/`bgCreamAlt` во всю ширину →
  нижний отступ 32. Заголовки секций — `CapsHeader`, контент — паддинг 24.
- **Ошибки/офлайн/загрузка**: центрированная колонка «сообщение → детали →
  кнопка»; офлайн-текст «Нет сети. Проверьте подключение.» (AC E2).

## 9. Тесты

- Виджет-тесты ищут **тексты**: капс-заголовки — в ЗАГЛАВНОМ регистре;
  элементы ниже вьюпорта (800×600) — через `tester.view.physicalSize`
  (высокая поверхность) или `dragUntilVisible`.
- Кнопки «назад»/карусели в тестах не блокируют: `slideImageBuilder`-
  заглушки для `CachedNetworkImageWidget`, `imageRef: null` → плейсхолдер.

## 10. Открытые пункты

1. Ревизия hex/размеров из Figma Dev Mode → правка только `app_colors.dart`
   / `app_typography.dart` и таблиц §2/§4 этого документа.
2. Экспорт иллюстраций онбординга → ассет-слот в шагах уже зарезервирован.
3. Централизация spacing/radius в токены — при первом переносе на сайт.
4. Гарнитура текста (сейчас системная) — уточнить у дизайнера.

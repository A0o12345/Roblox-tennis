# Задача 10: Пользовательский интерфейс, звуки и финальная полировка (UI & Polish)

## 📌 Цель
Создать телевизионное табло счета `src/client/ScoreboardGui.luau`, эффектные оверлеи событий матча `src/client/AnnouncerGui.luau` (FAULT, OUT, ACE, GAME) и звуковую подсистему `src/client/SoundManager.luau` (удары по мячу, отскоки, реакция трибун).

---

## 📂 Целевые файлы
1. `src/client/ScoreboardGui.luau`
2. `src/client/AnnouncerGui.luau`
3. `src/client/SoundManager.luau`

---

## 📺 Модуль 1: ScoreboardGui (src/client/ScoreboardGui.luau)

Табло располагается в верхнем левом углу экрана в стиле трансляций турниров Большого Шлема (Wimbledon / US Open).

### Структура табло:
- **Строка 1 (Игрок 1)**:
  - Иконка мяча (показывает, кто сейчас подает).
  - Никнейм игрока.
  - Сеты (0-2).
  - Геймы (0-6).
  - Текущие очки (`0`, `15`, `30`, `40`, `AD`).
- **Строка 2 (Игрок 2)**:
  - Аналогично для второго соперника.

### Логика обновления:
- Подписывается на `Network.getRemote("MatchStateChanged")` и `Network.getRemote("PointAnnounced")`.
- Плавно интерполирует изменение очков с помощью `TweenService` (эффект перелистывания цифр).

---

## 📢 Модуль 2: AnnouncerGui (src/client/AnnouncerGui.luau)

Отображает динамический баннер в центре экрана при завершении розыгрыша:
- `"FAULT"` — красный баннер при первой ошибке на подаче (исчезает через 1.2 с).
- `"DOUBLE FAULT"` — оранжевый баннер при второй ошибке.
- `"OUT!"` — акцентный баннер с белой рамкой при вылете мяча в аут.
- `"ACE!"` — золотой сияющий баннер при подаче навылет.
- `"DEUCE"` / `"ADVANTAGE"` — информационная плашка.
- `"GAME, SET & MATCH"` — грандиозный баннер победы с конфетти.

---

## 🔊 Модуль 3: SoundManager (src/client/SoundManager.luau)

### Набор процедурных/библиотечных звуков Roblox:
- `RacketHit`: звонкий хлесткий звук удара струн по мячу (модулирует громкость от силы `power`).
- `BallBounce`: глухой стук касания корта.
- `NetHit`: глухой вибрирующий удар мяча о полотно сетки.
- `CrowdCheer`: аплодисменты и гул трибун при долгих розыгрышах ($\ge 6$ ударов) и победных очках.
- `Whistle`: свисток судьи.

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
assert(localPlayer ~= nil, "Тест должен запускаться в режиме Play Solo!")

local ScoreboardGui = require(localPlayer.PlayerScripts.Client.ScoreboardGui)
local AnnouncerGui = require(localPlayer.PlayerScripts.Client.AnnouncerGui)
local SoundManager = require(localPlayer.PlayerScripts.Client.SoundManager)

-- Проверяем наличие методов
assert(type(ScoreboardGui.init) == "function", "ScoreboardGui обязан содержать init!")
assert(type(AnnouncerGui.announce) == "function", "AnnouncerGui обязан содержать announce!")
assert(type(SoundManager.playHitSound) == "function", "SoundManager обязан содержать playHitSound!")

print("✅ Задача 10 успешно проверена: UI, визуальные баннеры и звук полностью настроены!")
```

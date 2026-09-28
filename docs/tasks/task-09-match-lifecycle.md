# Задача 09: Жизненный цикл матча и менеджер кортов (MatchService & CourtManager)

## 📌 Цель
Создать серверную систему управления кортами `src/server/CourtManager.luau` и стейт-машину матча `src/server/MatchService.luau`. Система распределяет игроков по кортам, запускает матчи 1v1, ведет учет геймов и сетов, управляет сменой сторон и завершением игры.

---

## 📂 Целевые файлы
1. `src/server/CourtManager.luau`
2. `src/server/MatchService.luau`

---

## 🏟️ Модуль 1: CourtManager (src/server/CourtManager.luau)

### Задачи:
1. Хранит список доступных кортов в игре.
2. При старте сервера генерирует базовый корт через `CourtBuilder.buildCourt(Vector3.new(0, 0, 0), "Court_1")`.
3. Поддерживает регистрацию новых кортов со смещением по координатам (для мульти-кортов на одном сервере).
4. Методы:
   - `CourtManager.assignPlayersToCourt(p1: Player, p2: Player): string` — телепортирует игроков на спавны корта.
   - `CourtManager.releaseCourt(courtId: string)` — освобождает корт по завершении матча.

---

## 🏆 Модуль 2: MatchService (src/server/MatchService.luau)

### Фазы матча (Match State Machine):

1. **`Waiting` (Ожидание)**:
   - В лобби игроки встают в очередь или подходят к корту.
   - При наличии 2 игроков создается сессия матча.

2. **`Warmup` (Разминка / Подготовка)**:
   - Игроки телепортируются на свои спавны.
   - Инициализируется счет через `RulesEngine.createInitialScore(p1.UserId, p2.UserId)`.
   - Игрокам рассылается `MatchStateChanged` со статусом `"Warmup"`.
   - Таймер 3 секунды до начала первой подачи.

3. **`Serving` (Фаза подачи)**:
   - Подающий игрок фиксируется у задней линии на нужной стороне:
     - Если `servingSide == "Deuce"` -> правая сторона ($X \in [3, 10]$).
     - Если `servingSide == "Ad"` -> левая сторона ($X \in [-10, -3]$).
   - Мяч спавнится в руке подающего.
   - При нажатии пробела мяч подбрасывается, подающий совершает удар по мячу.

4. **`Rally` (Розыгрыш)**:
   - Мяч находится в игре. Контроль передается `RallyManager`.

5. **`PointEnded` (Завершение очка)**:
   - `RallyManager` определяет победителя.
   - Вызывается `RulesEngine.awardPoint`: обновляется счет.
   - Клиентам рассылается `PointAnnounced` с причиной победы и новым счетом.
   - Задержка 2.5 секунды для показа оверлея счета.
   - Если `isMatchOver == true` -> переход в `MatchEnded`.
   - Иначе -> смена стороны подачи (`Deuce` <-> `Ad`) и возврат в `Serving`.

6. **`MatchEnded` (Конец матча)**:
   - Объявление победителя матча.
   - Салют / конфетти над кортом.
   - Возврат игроков в зону лобби через 5 секунд.

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local CourtManager = require(ServerScriptService.Server.CourtManager)
local MatchService = require(ServerScriptService.Server.MatchService)

-- Проверяем инициализацию менеджеров
assert(type(CourtManager.init) == "function", "CourtManager обязан содержать init!")
assert(type(MatchService.startMatch) == "function", "MatchService обязан содержать startMatch!")

print("✅ Задача 09 успешно проверена: Стейт-машина матча и менеджер кортов функционируют!")
```

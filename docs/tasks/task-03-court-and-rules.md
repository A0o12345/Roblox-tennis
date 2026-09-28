# Задача 03: Геометрия корта и движок правил тенниса (CourtData & RulesEngine)

## 📌 Цель
Создать модули `src/shared/CourtData.luau` (геометрические константы, зоны корта, границы линий, определение аутов) и `src/shared/RulesEngine.luau` (система очков ITF: 0/15/30/40/Deuce/Advantage, тай-брейк, смена сторон подачи).

---

## 📂 Целевые файлы
1. `src/shared/CourtData.luau`
2. `src/shared/RulesEngine.luau`

---

## 📐 Модуль 1: CourtData (src/shared/CourtData.luau)

### Константы:
```lua
CourtData.LENGTH = 80.0
CourtData.HALF_LENGTH = 40.0
CourtData.SINGLES_WIDTH = 30.0
CourtData.HALF_SINGLES_WIDTH = 15.0
CourtData.DOUBLES_WIDTH = 38.0
CourtData.HALF_DOUBLES_WIDTH = 19.0
CourtData.SERVICE_LINE_DIST = 22.0
CourtData.NET_HEIGHT_CENTER = 3.2
CourtData.NET_HEIGHT_POST = 3.8
CourtData.LINE_TOLERANCE = 0.35 -- толщина линии: касание линии считается "В поле" (IN)
```

### Функции к реализации:
1. `CourtData.isInsideCourt(point: Vector3, isDoubles: boolean?): boolean`
   - Проверяет попадание точки на корт:
     - $|X| \le (\text{HALF\_SINGLES\_WIDTH} + \text{LINE\_TOLERANCE})$ (или DOUBLES).
     - $|Z| \le (\text{HALF\_LENGTH} + \text{LINE\_TOLERANCE})$.
2. `CourtData.getCourtSide(point: Vector3): "Player1" | "Player2"`
   - Если $Z < 0$ -> `"Player1"`.
   - Если $Z \ge 0$ -> `"Player2"`.
3. `CourtData.isInServiceBox(point: Vector3, serverSide: "Player1" | "Player2", box: "Deuce" | "Ad"): boolean`
   - При подаче с половины Player1 ($Z < 0$):
     - Мяч должен приземлиться на половине Player2 ($0 \le Z \le 22 + \text{LINE\_TOLERANCE}$).
     - Если `box == "Deuce"` (подача из правого угла): диагональ — правый квадрат принимающего ($X \in [-\text{TOL}, 15 + \text{TOL}]$).
     - Если `box == "Ad"` (подача из левого угла): диагональ — левый квадрат принимающего ($X \in [-15 - \text{TOL}, \text{TOL}]$).
   - Аналогично симметрично для Player2 ($Z > 0$).

---

## 🎾 Модуль 2: RulesEngine (src/shared/RulesEngine.luau)

### Функции к реализации:
1. `RulesEngine.createInitialScore(p1Id: number, p2Id: number): Types.ScoreState`
   - Инициализирует нулевой счет: 0 очков, 0 геймов, 0 сетов, подающий — `p1Id`, сторона подачи — `"Deuce"`.
2. `RulesEngine.formatGameScore(p1Points: number, p2Points: number): (string, string)`
   - Преобразует очки в стандартную теннисную терминологию:
     - 0 -> `"0"`
     - 1 -> `"15"`
     - 2 -> `"30"`
     - 3 -> `"40"`
     - При 3:3 (40:40) -> `"40"`, `"40"` (Deuce)
     - При преимуществе: `"AD"`, `"40"` или `"40"`, `"AD"`
3. `RulesEngine.awardPoint(score: Types.ScoreState, winningPlayerId: number): (Types.ScoreState, boolean, boolean)`
   - Принимает текущий счет и ID победителя розыгрыша.
   - Возвращает `(newScore, isGameOver, isMatchOver)`.
   - **Логика гейма**:
     - Если игрок ведет 40:0 (3:0) и берет очко -> выигрывает гейм.
     - Если счет 40:40 (Deuce):
       - Игрок, берущий очко, получает преимущество (`points = 4`).
       - Если преимущество уже у соперника, счет возвращается к ровно (`points = 3:3`).
       - Если игрок с преимуществом берет очко -> гейм выигран.
   - **Смена подачи**:
     - После каждого очка сторона подачи переключается: `"Deuce"` <-> `"Ad"`.
     - После каждого гейма подающий игрок меняется: `servingPlayerId` меняется между `p1` и `p2`, сторона подачи сбрасывается на `"Deuce"`.
   - **Логика сета**:
     - Первый до 6 геймов с разрывом $\ge 2$ выигрывает сет.
     - При счете 6:6 включается тай-брейк (`isTiebreak = true`): счет идет по 1 очку (1, 2, 3...) до 7 очков с разницей $\ge 2$.
   - **Матч**:
     - Победа в 2 сетах (Best of 3) завершает матч (`isMatchOver = true`).

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CourtData = require(ReplicatedStorage.Shared.CourtData)
local RulesEngine = require(ReplicatedStorage.Shared.RulesEngine)

-- 1. Тест геометрии корта
assert(CourtData.isInsideCourt(Vector3.new(0, 0.5, 0)) == true, "Центр корта должен быть IN")
assert(CourtData.isInsideCourt(Vector3.new(16, 0.5, 0)) == false, "Точка X=16 в одиночке должна быть OUT")
assert(CourtData.isInsideCourt(Vector3.new(0, 0.5, 45)) == false, "Точка Z=45 должна быть OUT")

-- 2. Тест счета тенниса
local score = RulesEngine.createInitialScore(1001, 1002)
assert(score.player1Points == 0 and score.player2Points == 0, "Счет должен начинаться с 0-0")

-- Игрок 1 берет 3 очка (15, 30, 40)
score = RulesEngine.awardPoint(score, 1001)
assert(score.player1Points == 1, "Должно быть 15 (1)")
score = RulesEngine.awardPoint(score, 1001)
score = RulesEngine.awardPoint(score, 1001)
assert(score.player1Points == 3, "Должно быть 40 (3)")

-- Игрок 1 берет 4-е очко -> выигрывает гейм
local isGameOver, isMatchOver
score, isGameOver, isMatchOver = RulesEngine.awardPoint(score, 1001)
assert(isGameOver == true, "Гейм должен быть завершен!")
assert(score.player1Games == 1, "Игрок 1 должен иметь 1 гейм")
assert(score.servingPlayerId == 1002, "Подача должна перейти к Игроку 2")

print("✅ Задача 03 успешно проверена: Геометрия корта и правила ITF функционируют безупречно!")
```

# Задача 04: Процедурный строитель 3D корта (CourtBuilder)

## 📌 Цель
Создать серверный модуль `src/server/CourtBuilder.luau`, который процедурно генерирует полноценную 3D модель корта со всеми линиями разметки, сеткой, столбами и точками спавна игроков строго по координатам `CourtData`.

---

## 📂 Целевой файл
`src/server/CourtBuilder.luau`

---

## 📐 Архитектура корта

Корт собирается в единую модель `Model` с атрибутом `CourtId`. Все физические части закреплены (`Anchored = true`).

### 1. Покрытие корта (Ground & Surround):
- **Основной игровой прямоугольник**: размер $38 \times 80\text{ studs}$ ($X \in [-19, 19]$, $Z \in [-40, 40]$), цвет `Color3.fromRGB(56, 118, 191)` (синий хард-корт), материал `SmoothPlastic`.
- **Зона забегов (Surround)**: размер $55 \times 110\text{ studs}$, цвет `Color3.fromRGB(45, 120, 75)` (зеленый фон).

### 2. Белые линии разметки (White Lines):
Толщина линий: $0.3\text{ studs}$ по высоте (Y), ширина $0.3\text{ studs}$ (X/Z). Цвет белый `Color3.new(1, 1, 1)`, материал `SmoothPlastic`, `CanCollide = false`.
- **Задние линии (Baselines)**: при $Z = -40$ и $Z = +40$.
- **Линии подачи (Service Lines)**: при $Z = -22$ и $Z = +22$ (между $X \in [-15, 15]$).
- **Центральная линия подачи (Center Service Line)**: вдоль оси $Z$ от $-22$ до $+22$ при $X = 0$.
- **Одиночные боковые линии (Singles Sidelines)**: при $X = -15$ и $X = +15$ (от $Z = -40$ до $+40$).
- **Парные боковые линии (Doubles Sidelines)**: при $X = -19$ и $X = +19$ (от $Z = -40$ до $+40$).
- **Центральная засечка (Center Mark)**: при $X = 0, Z = \pm 40$ длиной $1.5\text{ studs}$.

### 3. Сетка (Net & Posts):
- **Столбы сетки (Posts)**: 2 цилиндра или бруска на $X = -16.5$ и $X = +16.5$, $Z = 0$, высота $3.8\text{ studs}$, цвет темно-серый/металлик.
- **Полотно сетки (Net Mesh/Part)**: брусок от $X = -16$ до $+16$, $Z = 0$, толщина $0.2\text{ studs}$, высота $3.4\text{ studs}$, полупрозрачный (`Transparency = 0.4`), цвет черный или белый.
- **Верхний белый трос (Net Cord)**: тонкая белая полоса на вершине сетки толщиной $0.15\text{ studs}$.

### 4. Спавны игроков (SpawnPoints):
- `Spawn_Player1`: `CFrame.new(0, 3, -38) * CFrame.Angles(0, 0, 0)` (лицом к сетке, в сторону $+Z$).
- `Spawn_Player2`: `CFrame.new(0, 3, +38) * CFrame.Angles(0, math.rad(180), 0)` (лицом к сетке, в сторону $-Z$).

---

## ⚙️ Функции к реализации

```lua
--!strict

local CourtBuilder = {}

-- Создает полный корт в заданной точке мира
function CourtBuilder.buildCourt(centerPosition: Vector3, courtId: string): Model
    -- Создает Model "TennisCourt_" .. courtId
    -- Генерирует Base, Lines, Net, Spawns
    -- Возвращает созданный Model
end

-- Очищает корт при необходимости
function CourtBuilder.clearCourt(courtModel: Model)
    courtModel:Destroy()
end

return CourtBuilder
```

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local CourtBuilder = require(ServerScriptService.Server.CourtBuilder)

-- Создаем тестовый корт в начале координат
local testCourt = CourtBuilder.buildCourt(Vector3.new(0, 0, 0), "TestCourt_01")
assert(testCourt ~= nil and testCourt:IsA("Model"), "CourtBuilder обязан возвращать Model!")

-- Проверяем наличие ключевых компонентов
assert(testCourt:FindFirstChild("Net") ~= nil, "Сетка (Net) должна присутствовать в модели корта!")
assert(testCourt:FindFirstChild("Spawn_Player1") ~= nil, "Спавн игрока 1 не найден!")
assert(testCourt:FindFirstChild("Spawn_Player2") ~= nil, "Спавн игрока 2 не найден!")
assert(testCourt:FindFirstChild("Lines") ~= nil, "Папка с линиями разметки (Lines) отсутствует!")

print("✅ Задача 04 успешно проверена: 3D Корт процедурно сгенерирован и размещен в Workspace!")
```

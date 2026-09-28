# Задача 05: Система мяча (BallService & BallController)

## 📌 Цель
Создать авторитетную серверную службу мяча `src/server/BallService.luau` и клиентский контроллер плавного визуала `src/client/BallController.luau`. Мяч на клиенте рассчитывается на каждом кадре `RenderStepped`, обеспечивая ультра-плавный полет со следом (Trail) и динамической тенью на корте.

---

## 📂 Целевые файлы
1. `src/server/BallService.luau`
2. `src/client/BallController.luau`

---

## ⚙️ Серверный модуль: BallService (src/server/BallService.luau)

### Задачи сервиса:
1. Создание физического представления мяча в `Workspace` (для визуализации и проверок): желтая сфера `Size = Vector3.new(0.8, 0.8, 0.8)`, `CanCollide = false`, `Anchored = true`.
2. Управление состоянием траектории:
   ```lua
   type ActiveBall = {
       ballId: string,
       instance: Part,
       origin: Vector3,
       velocity: Vector3,
       shotType: Types.ShotType,
       startTime: number,
       hitterUserId: number,
       bounceCount: number,
       active: boolean,
   }
   ```
3. Методы:
   - `BallService.createBall(startPosition: Vector3): string` — создает мяч и возвращает `ballId`.
   - `BallService.launch(ballId: string, velocity: Vector3, shotType: Types.ShotType, hitterUserId: number)`:
     - Фиксирует `startTime = workspace:GetServerTimeNow()`.
     - Сбрасывает `bounceCount = 0`.
     - Рассылает всем клиентам событие `BallStateBroadcast` через `Network`.
   - `BallService.onHeartbeat(dt: number)`:
     - На каждом шаге сервера вычисляет $t = \text{GetServerTimeNow()} - \text{startTime}$.
     - Проверяет момент касания земли через `TrajectoryMath.calculateTimeToGround`.
     - Если $t \ge t_{\text{ground}}$:
       - Фиксирует отскок `bounceCount += 1`.
       - Вызывает сигнал `BallService.OnBounce:Fire(ballId, bouncePos, bounceCount)`.
       - Пересчитывает новый вектор отскока через `TrajectoryMath.calculateBounce` и продолжает полет.

---

## 👁️ Клиентский модуль: BallController (src/client/BallController.luau)

### Задачи контроллера:
1. Подписывается на сетевое событие `Network.getRemote("BallStateBroadcast")`.
2. При получении новых данных траектории обновляет локальное состояние:
   - `origin`, `velocity`, `shotType`, `startTime`.
3. Создает визуальные эффекты:
   - **Trail** (след за мячом): желто-белый шлейф, время жизни $0.25\text{ с}$.
   - **Тень мяча (Drop Shadow)**: плоский полупрозрачный темный диск на полу корта ($Y = 0.52$), позиция X/Z которого повторяет мяч, а размер и прозрачность зависят от высоты мяча.
4. В цикле `RunService.RenderStepped`:
   - Вычисляет точное локальное время полета:
     $$t = \text{workspace:GetServerTimeNow()} - \text{state.startTime}$$
   - Получает точку $\mathbf{P}(t) = \text{TrajectoryMath.calculatePosition}(\text{origin}, \text{velocity}, t)$.
   - Плавно устанавливает `ballPart.CFrame = CFrame.new(pos)`.
   - Обновляет тень: `shadowPart.Position = Vector3.new(pos.X, 0.52, pos.Z)`.

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local BallService = require(ServerScriptService.Server.BallService)

-- 1. Спавним тестовый мяч
local ballId = BallService.createBall(Vector3.new(0, 3, -38))
assert(ballId ~= nil, "BallService обязан вернуть идентификатор мяча!")

-- 2. Запускаем подачу
BallService.launch(ballId, Vector3.new(0, 5, 45), "Flat", 1)

local ballData = BallService.getBall(ballId)
assert(ballData ~= nil, "Мяч должен быть зарегистрирован в системе!")
assert(ballData.active == true, "Мяч должен быть активен!")
assert(ballData.velocity.Z == 45, "Скорость полета должна быть установлена!")

print("✅ Задача 05 успешно проверена: Серверный жизненный цикл мяча запущен и синхронизирован!")
```

# Задача 08: Валидация ударов и менеджер розыгрыша (RallyManager)

## 📌 Цель
Создать серверного судью розыгрыша `src/server/RallyManager.luau`. Модуль валидирует запросы на удар от клиентов, пресекает читерство и десинхронизацию, отслеживает касания корта и сетки, определяет ауты и начисляет очки победителю розыгрыша.

---

## 📂 Целевой файл
`src/server/RallyManager.luau`

---

## ⚖️ Правила валидации удара (Hit Validation)

Когда клиент присылает `HitBallRequest`, сервер проверяет:
1. **Дистанция**: Расстояние от `HumanoidRootPart` бьющего игрока до текущей позиции мяча $\le 8.5\text{ studs}$.
2. **Сторона корта**: Игрок бьет по мячу, только когда мяч летит в его сторону или уже находится на его половине.
3. **Число отскоков**:
   - `bounceCount == 0`: Удар с лета (Volley). Разрешен во время розыгрыша, но **ЗАПРЕЩЕН** при приеме подачи (прием подачи обязан быть после 1 отскока).
   - `bounceCount == 1`: Стандартный удар после отскока.
   - `bounceCount >= 2`: Опоздание! Удар отклоняется, очко присуждается сопернику (`"DoubleBounce"`).

---

## 🎯 Расчет новой траектории

После успешной валидации:
1. Вычисляется базовая целевая точка на стороне соперника:
   - Если бьет Игрок 1 (с половины $Z < 0$): целевая точка лежит в $Z \in [15, 36]$.
   - Смещение по оси X: $X_{\text{target}} = \text{payload.aimDirection.X} \cdot 12\text{ studs}$.
   - Смещение по глубине Z: глубина регулируется силой `payload.power` и `payload.aimDirection.Y`.
2. Влияние тайминга (`timing`):
   - `"Perfect"`: целевая точка ложится точно по краю корта, скорость $+10\%$.
   - `"Good"`: нормальная траектория.
   - `"Early"` / `"Late"`: добавляется случайный разброс $X \pm 3\text{ studs}$, повышающий риск аута.
3. Расчет начальной скорости:
   $$\mathbf{V}_0 = \text{TrajectoryMath.calculateLaunchVelocity}(\text{ballPos}, \mathbf{P}_{\text{target}}, T_{\text{flight}})$$
4. Запуск мяча через `BallService.launch(ballId, V0, shotType, player.UserId)`.

---

## 🔍 Отслеживание исхода розыгрыша

Модуль слушает события от `BallService`:
1. **Касание сетки (`BallHitNet`)**:
   - Если мяч не смог перелететь сетку и отскочил назад -> игрок, совершивший удар, проигрывает очко (`reason = "Net"`).
2. **Первый отскок (`BallBounced`, bounceCount == 1)**:
   - **При подаче**: проверяется `CourtData.isInServiceBox(bouncePos)`. Если мяч вне квадрата -> `Fault` (первая ошибка) или `DoubleFault` (очко принимающему).
   - **В розыгрыше**: проверяется `CourtData.isInsideCourt(bouncePos)`. Если мяч за пределами корта -> `Out` (очко сопернику бьющего).
3. **Второй отскок (`BallBounced`, bounceCount == 2)**:
   - Если первый отскок был в поле, а принимающий не успел нанести удар до второго отскока -> очко присуждается бьющему (`reason = "DoubleBounce"` или `"Winner"`).

После фиксации конца розыгрыша `RallyManager` вызывает сигнал:
```lua
RallyManager.OnPointCompleted:Fire(winningPlayerId: number, reason: Types.PointEndReason)
```

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local RallyManager = require(ServerScriptService.Server.RallyManager)

-- Проверяем наличие сигналов и методов
assert(type(RallyManager.init) == "function", "RallyManager обязан содержать метод init!")
assert(type(RallyManager.validateHit) == "function", "RallyManager обязан содержать validateHit!")
assert(RallyManager.OnPointCompleted ~= nil, "RallyManager обязан иметь сигнал OnPointCompleted!")

print("✅ Задача 08 успешно проверена: Серверный арбитр розыгрышей готов!")
```

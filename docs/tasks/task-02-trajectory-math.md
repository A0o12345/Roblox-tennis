# Задача 02: Математический движок траектории (TrajectoryMath)

## 📌 Цель
Создать чистый, детерминированный модуль математики полета теннисного мяча `src/shared/TrajectoryMath.luau`. Этот модуль будет использоваться и на сервере (для валидации и стейта), и на клиенте (для рендера с 60+ FPS без дерганий).

---

## 📂 Целевой файл
`src/shared/TrajectoryMath.luau`

---

## 📐 Спецификация API и константы

```lua
--!strict

local Types = require(script.Parent.Types)

local TrajectoryMath = {}

-- Константы физической модели
TrajectoryMath.GRAVITY = 55.0         -- studs/s^2 (ускорение свободного падения)
TrajectoryMath.BALL_RADIUS = 0.4      -- studs
TrajectoryMath.COURT_Y = 0.5          -- Y-координата пола корта
TrajectoryMath.RESTITUTION_DEFAULT = 0.72  -- Коэффициент упругости отскока
TrajectoryMath.FRICTION_DEFAULT = 0.82     -- Трение о покрытие корта
```

---

## ⚙️ Требуемые функции к реализации

### 1. `calculatePosition(origin: Vector3, velocity: Vector3, t: number): Vector3`
Вычисляет положение мяча в момент времени $t$ (где $t \ge 0$ — секунды с момента удара):
$$\mathbf{P}(t) = \mathbf{origin} + \mathbf{velocity} \cdot t + \frac{1}{2} (0, -g, 0) \cdot t^2$$

### 2. `calculateVelocity(initialVelocity: Vector3, t: number): Vector3`
Вычисляет мгновенную скорость мяча:
$$\mathbf{V}(t) = (v_x, v_y - g \cdot t, v_z)$$

### 3. `calculateTimeToGround(origin: Vector3, velocity: Vector3, groundY: number?): number?`
Решает квадратное уравнение для нахождения момента касания земли:
$$\frac{1}{2} g t^2 - v_y t + ((Y_{\text{ground}} + R) - y_0) = 0$$
- Если $D < 0$ или корней $\le 0$ нет, возвращает `nil`.
- Иначе возвращает наименьший положительный корень $\Delta t > 0.001$.

### 4. `calculateBounce(velocityAtImpact: Vector3, shotType: Types.ShotType): Vector3`
Рассчитывает вектор скорости мяча после отскока:
- Для `Topspin`: $e_y = 0.85$, $v_{xz}$ сохраняет $0.88$ скорости (быстрый высокий отскок).
- Для `Slice`: $e_y = 0.48$, $v_{xz}$ тормозит до $0.75$ (низкий стелющийся отскок).
- Для `DropShot`: $e_y = 0.35$, $v_{xz}$ тормозит до $0.50$ (мягкий отскок у сетки).
- По умолчанию: $e_y = 0.72$, $v_{xz} = 0.82$.
- $v_{y\text{\_new}} = -v_y \cdot e_y$, $v_{x\text{\_new}} = v_x \cdot \mu$, $v_{z\text{\_new}} = v_z \cdot \mu$.

### 5. `calculateLaunchVelocity(origin: Vector3, target: Vector3, flightTime: number): Vector3`
Вычисляет требуемую начальную скорость $\mathbf{V}_0$, чтобы мяч из точки `origin` приземлился точно в точку `target` за время `flightTime`:
$$v_x = \frac{\text{target}.X - \text{origin}.X}{\text{flightTime}}$$
$$v_z = \frac{\text{target}.Z - \text{origin}.Z}{\text{flightTime}}$$
$$v_y = \frac{\text{target}.Y - \text{origin}.Y + \frac{1}{2} g \cdot \text{flightTime}^2}{\text{flightTime}}$$

### 6. `checkNetCollision(origin: Vector3, velocity: Vector3, netZ: number?, centerHeight: number?, postHeight: number?): (boolean, number?, Vector3?)`
Проверяет, врежется ли мяч в сетку:
- Сетка расположена на $Z = 0$ (по умолчанию).
- Время долета до плоскости сетки: $t_{\text{net}} = \frac{\text{netZ} - \text{origin}.Z}{v_z}$.
- Если $t_{\text{net}} \le 0$ или мяч коснется пола раньше, чем долетит до сетки, коллизии нет: `return false, nil, nil`.
- Вычисляется высота мяча в точке сетки $Y_{\text{net}} = \text{origin}.Y + v_y t_{\text{net}} - \frac{1}{2} g t_{\text{net}}^2$.
- Вычисляется высота сетки с учетом наклона от центра к столбам:
  $$\text{currentNetHeight} = 3.2 + (3.8 - 3.2) \cdot \min(1, |X_{\text{net}}| / 16.0)$$
- Если $Y_{\text{net}} \le \text{currentNetHeight}$, мяч задел сетку!
  Возвращает: `true, t_net, Vector3.new(X_net, Y_net, netZ)`.
- Иначе: `false, t_net, nil`.

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrajectoryMath = require(ReplicatedStorage.Shared.TrajectoryMath)

local origin = Vector3.new(0, 3, -38)
local target = Vector3.new(10, 0.5, 25)
local flightTime = 1.0

-- 1. Тест расчета скорости запуска
local v0 = TrajectoryMath.calculateLaunchVelocity(origin, target, flightTime)
local landPos = TrajectoryMath.calculatePosition(origin, v0, flightTime)

assert((landPos - target).Magnitude < 0.01, "Ошибка точности приземления в цель!")

-- 2. Тест времени касания пола
local tGround = TrajectoryMath.calculateTimeToGround(origin, v0, 0.5)
assert(tGround ~= nil and math.abs(tGround - flightTime) < 0.01, "Ошибка времени касания пола!")

-- 3. Тест прохождения над сеткой
local hitNet, tNet, netPoint = TrajectoryMath.checkNetCollision(origin, v0, 0, 3.2, 3.8)
assert(hitNet == false, "Мяч должен был чисто перелететь сетку!")

-- 4. Тест удара в сетку при низкой траектории
local lowV0 = Vector3.new(0, 0, 40)
local hitNetLow, _, lowPoint = TrajectoryMath.checkNetCollision(origin, lowV0, 0, 3.2, 3.8)
assert(hitNetLow == true, "Низкий мяч обязан врезаться в сетку!")

print("✅ Задача 02 успешно проверена: Все математические расчеты TrajectoryMath точны!")
```

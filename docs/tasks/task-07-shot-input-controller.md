# Задача 07: Контроллер ударов и шкала тайминга (ShotController & TimingMeter)

## 📌 Цель
Создать клиентскую систему ударов `src/client/ShotController.luau` и визуальную шкалу зарядки/тайминга `src/client/TimingMeter.luau`. Система считывает нажатия клавиш, рассчитывает вектор прицеливания (куда отправить мяч на сторону соперника), определяет качество тайминга (`Perfect`, `Good`, `Early`, `Late`) и отправляет запрос на сервер через `HitBallRequest`.

---

## 📂 Целевые файлы
1. `src/client/ShotController.luau`
2. `src/client/TimingMeter.luau`

---

## 🎮 Раскладка управления (Input Controls)

| Клавиша (PC) | Геймпад | Тип удара | Описание |
|---|---|---|---|
| **ЛКМ / E** | Кнопка A | `Flat` | Скоростной прямой прострел |
| **Q** | Кнопка X | `Topspin` | Крученый удар с высоким отскоком |
| **R** | Кнопка B | `Slice` | Подрезка, замедляющая темп розыгрыша |
| **F** | Кнопка Y | `Lob` | Свеча (переброс через соперника) |
| **C** | Правый триггер | `DropShot` | Укороченный удар под сетку |
| **Пробел** | Кнопка A (при подаче) | `Serve` | Подброс и подача |

---

## ⚙️ Логика модуля ShotController (src/client/ShotController.luau)

### 1. Зарядка удара (Charge Meter):
- При зажатии клавиши начинается зарядка от $0.5$ до $1.0$ за время $0.5\text{ с}$.
- Модуль передает текущий процент зарядки в `TimingMeter.updateCharge(ratio)`.

### 2. Прицеливание (Aim Direction):
- Во время удержания кнопки считываются клавиши движения:
  - Нажата `A` (Влево) -> смещение прицела влево на $X_{\text{target}} \approx -10\text{ studs}$.
  - Нажата `D` (Вправо) -> смещение прицела вправо на $X_{\text{target}} \approx +10\text{ studs}$.
  - Нажата `W` (Вперед) -> удар под заднюю линию ($Z_{\text{target}}$ глубже).
  - Нажата `S` (Назад) -> более короткий удар в центр корта.
  - Если клавиши не нажаты -> удар направляется в центр половины соперника.

### 3. Расчет тайминга (Timing Quality):
- При отпускании клавиши проверяется расстояние до мяча:
  - Идеальная дистанция для удара: $3.0 - 5.5\text{ studs}$ от персонажа.
  - Если мяч в идеальном диапазоне: `"Perfect"` (+15% к скорости, идеальная точность).
  - Если мяч еще не долетел: `"Early"` (отклонение угла удара влево/вправо).
  - Если мяч уже пролетел мимо: `"Late"` (потеря скорости, риск аута).
  - Если расстояние $> 8.5\text{ studs}$: удар не регистрируется (промах по воздуху).

### 4. Отправка пакета на сервер:
```lua
Network.fireServer("HitBallRequest", {
    shotType = selectedShotType,
    aimDirection = aimVector,
    power = currentPower,
    timing = timingQuality,
    clientTimestamp = workspace:GetServerTimeNow(),
})
```

---

## 🎨 Модуль UI: TimingMeter (src/client/TimingMeter.luau)

- Создает полукруглую шкалу (BillboardGui) над головой персонажа:
  - Заполняющаяся полоса (зеленый/желтый цвет).
  - Текстовый лейбл с мгновенной всплывающей анимацией:
    - `"PERFECT!"` (Золотой цвет, размер шрифта увеличивается и затухает).
    - `"GOOD"` (Зеленый).
    - `"EARLY"` / `"LATE"` (Оранжевый / Красный).

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
assert(localPlayer ~= nil, "Тест должен запускаться в режиме Play Solo!")

local ShotController = require(localPlayer.PlayerScripts.Client.ShotController)
local TimingMeter = require(localPlayer.PlayerScripts.Client.TimingMeter)

-- Проверяем наличие методов
assert(type(ShotController.onInputBegan) == "function", "ShotController обязан иметь onInputBegan!")
assert(type(ShotController.calculateAim) == "function", "ShotController обязан иметь calculateAim!")
assert(type(TimingMeter.showFeedback) == "function", "TimingMeter обязан иметь showFeedback!")

print("✅ Задача 07 успешно проверена: Контроллер ударов и тайминга готов к игре!")
```

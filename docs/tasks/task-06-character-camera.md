# Задача 06: Камера теннисиста и управление персонажем (Camera & Character)

## 📌 Цель
Создать специализированную камеру `src/client/TennisCameraController.luau` от третьего лица (вид из-за спины в сторону сетки и корта соперника) и контроллер персонажа `src/client/TennisCharacter.luau` (ограничение перемещения своей половиной корта, удержание ракетки в руке и разворот к мячу).

---

## 📂 Целевые файлы
1. `src/client/TennisCameraController.luau`
2. `src/client/TennisCharacter.luau`

---

## 🎥 Модуль 1: TennisCameraController (src/client/TennisCameraController.luau)

### Особенности камеры:
- Камера находится в режиме `Scriptable`.
- Позиционируется на высоте $10\text{ studs}$ и на $14\text{ studs}$ позади игрока:
  - Для Игрока 1 (сторона $Z < 0$): камера смещена в сторону $-Z$, смотрит вперед ($+Z$).
  - Для Игрока 2 (сторона $Z > 0$): камера смещена в сторону $+Z$, смотрит вперед ($-Z$).
- Плавное слежение (Lerp со сглаживанием $0.15$), чтобы избежать резкой тряски.
- Поле зрения `FieldOfView = 70`.

### Методы:
- `TennisCameraController.enable(side: "Player1" | "Player2")` — активирует слежение.
- `TennisCameraController.disable()` — возвращает камеру в стандартный `Custom`.
- `TennisCameraController.onRenderStep(dt: number)` — обновляет `Camera.CFrame`.

---

## 🏃 Модуль 2: TennisCharacter (src/client/TennisCharacter.luau)

### Задачи:
1. **Экипировка ракетки**:
   - При спавне персонажа создает простую 3D модель ракетки (рукоятка и обод со струнами).
   - Создает `Motor6D` или `WeldConstraint` к `RightHand` персонажа R15.
2. **Ограничение перемещения (Court Boundaries)**:
   - В каждом кадре проверяет `HumanoidRootPart.Position`.
   - Не позволяет игроку забегать на половину корта соперника (для Player 1 координата $Z$ не может превышать $-1.5\text{ studs}$, для Player 2 не может быть меньше $+1.5\text{ studs}$).
   - Ограничивает боковой забег за пределы корта ($|X| \le 24\text{ studs}$).
3. **Ориентация игрока**:
   - Автоматически разворачивает корпус игрока лицом к сетке или приближающемуся мячу, чтобы удар выглядел естественно.

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в Roblox Studio Command Bar:

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
assert(localPlayer ~= nil, "Тест должен запускаться в режиме Play Solo!")

local TennisCameraController = require(localPlayer.PlayerScripts.Client.TennisCameraController)
local TennisCharacter = require(localPlayer.PlayerScripts.Client.TennisCharacter)

-- 1. Проверяем активацию камеры
TennisCameraController.enable("Player1")
assert(workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable, "Камера должна переключиться в Scriptable!")

-- 2. Отключаем камеру
TennisCameraController.disable()
assert(workspace.CurrentCamera.CameraType == Enum.CameraType.Custom, "Камера должна вернуться в Custom!")

print("✅ Задача 06 успешно проверена: Камера и поведение персонажа настроены!")
```

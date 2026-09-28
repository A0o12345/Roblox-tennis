# Задача 01: Базовая настройка, типы данных Luau и шина сетевых событий

## 📌 Цель
Создать базовую структуру папок `src/`, зафиксировать строгие типы данных проекта в `src/shared/Types.luau` и настроить модуль сетевых событий `src/shared/Network.luau`, который автоматически создает и регистрирует все необходимые RemoteEvent и RemoteFunction.

---

## 📂 Целевые файлы
1. `src/shared/Types.luau`
2. `src/shared/Network.luau`

---

## 📐 Контракты типов (src/shared/Types.luau)

Создай файл `src/shared/Types.luau` со следующим содержанием:

```lua
--!strict

export type ShotType = "Flat" | "Topspin" | "Slice" | "Lob" | "DropShot" | "Serve"

export type TimingQuality = "Perfect" | "Good" | "Early" | "Late"

export type ServingSide = "Deuce" | "Ad"

export type CourtSide = "Player1" | "Player2"

export type MatchState = "Waiting" | "Warmup" | "Serving" | "Rally" | "PointEnded" | "MatchEnded"

export type PointEndReason = 
    | "Out" 
    | "Net" 
    | "DoubleBounce" 
    | "Ace" 
    | "Winner" 
    | "Fault" 
    | "DoubleFault"

export type ScoreState = {
    player1Points: number,  -- 0, 1 (15), 2 (30), 3 (40), 4 (Ad)
    player2Points: number,
    player1Games: number,
    player2Games: number,
    player1Sets: number,
    player2Sets: number,
    isDeuce: boolean,
    isTiebreak: boolean,
    serverSide: ServingSide,
    servingPlayerId: number,
    receivingPlayerId: number,
}

export type BallTrajectory = {
    ballId: string,
    origin: Vector3,
    velocity: Vector3,
    shotType: ShotType,
    startTime: number,       -- время по workspace:GetServerTimeNow()
    hitterUserId: number,
    bounceCount: number,
    courtTarget: Vector3?,
}

export type HitRequestPayload = {
    shotType: ShotType,
    aimDirection: Vector2,   -- (X: смещение влево/вправо [-1, 1], Y: глубина удара [0, 1])
    power: number,           -- сила замаха от 0.5 до 1.0
    timing: TimingQuality,
    clientTimestamp: number,
}

export type MatchStatePayload = {
    courtId: string,
    state: MatchState,
    servingPlayerId: number,
    receivingPlayerId: number,
    servingSide: ServingSide,
    score: ScoreState,
}

export type PointAnnouncePayload = {
    reason: PointEndReason,
    winnerUserId: number,
    newScore: ScoreState,
}

return nil
```

---

## 🔌 Модуль сети (src/shared/Network.luau)

Создай файл `src/shared/Network.luau`:
- Автоматически создает папку `ReplicatedStorage.TennisRemotes` при вызове на сервере, если она еще не создана.
- На клиенте ожидает появления папки через `WaitForChild("TennisRemotes")`.
- Создает следующие RemoteEvent:
  - `HitBallRequest` (Клиент -> Сервер)
  - `BallStateBroadcast` (Сервер -> Клиенты)
  - `MatchStateChanged` (Сервер -> Клиенты)
  - `PointAnnounced` (Сервер -> Клиенты)
  - `PlayerReady` (Клиент -> Сервер)
- Предоставляет типизированные методы:
  - `Network.getRemote(name: string): RemoteEvent`
  - `Network.fireServer(name: string, ...: any)`
  - `Network.fireClient(name: string, player: Player, ...: any)`
  - `Network.fireAllClients(name: string, ...: any)`

---

## ✅ Скрипт верификации (Unit Test)

Запустите данный скрипт в командной строке Roblox Studio Command Bar для проверки:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local Network = require(ReplicatedStorage.Shared.Network)

-- Проверяем получение ремоута
local hitRemote = Network.getRemote("HitBallRequest")
assert(hitRemote ~= nil, "HitBallRequest RemoteEvent не найден!")
assert(hitRemote:IsA("RemoteEvent"), "HitBallRequest должен быть RemoteEvent")

local ballBroadcast = Network.getRemote("BallStateBroadcast")
assert(ballBroadcast ~= nil, "BallStateBroadcast не найден!")

print("✅ Задача 01 успешно проверена: Типы и Сеть работают корректно!")
```

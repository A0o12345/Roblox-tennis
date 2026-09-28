--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local RulesEngine = require(Shared:WaitForChild("RulesEngine"))
local Network = require(Shared:WaitForChild("Network"))

local CourtManager = require(script.Parent:WaitForChild("CourtManager"))
local BallService = require(script.Parent:WaitForChild("BallService"))
local RallyManager = require(script.Parent:WaitForChild("RallyManager"))

local MatchService = {}

type ActiveMatch = {
	courtId: string,
	player1: Player,
	player2: Player,
	score: Types.ScoreState,
	state: Types.MatchState,
	currentBallId: string?,
}

local currentMatch: ActiveMatch? = nil

function MatchService.getState(): Types.MatchState
	return if currentMatch then currentMatch.state else "Waiting"
end

function MatchService.getScore(): Types.ScoreState?
	return if currentMatch then currentMatch.score else nil
end

local function broadcastMatchState(state: Types.MatchState)
	if not currentMatch then
		return
	end

	currentMatch.state = state

	local payload: Types.MatchStatePayload = {
		courtId = currentMatch.courtId,
		state = state,
		servingPlayerId = currentMatch.score.servingPlayerId,
		receivingPlayerId = currentMatch.score.receivingPlayerId,
		servingSide = currentMatch.score.serverSide,
		score = currentMatch.score,
	}

	Network.fireAllClients("MatchStateChanged", payload)
end

local function prepareServing()
	if not currentMatch then
		return
	end

	local score = currentMatch.score
	local isP1Server = (score.servingPlayerId == currentMatch.player1.UserId)
	local serverPlayer = if isP1Server then currentMatch.player1 else currentMatch.player2

	-- Calculate serve spot
	local serveX: number
	local serveZ: number

	if isP1Server then
		serveZ = -38.5
		serveX = if score.serverSide == "Deuce" then 5.0 else -5.0
	else
		serveZ = 38.5
		serveX = if score.serverSide == "Deuce" then -5.0 else 5.0
	end

	local serverChar = serverPlayer.Character
	if serverChar then
		local root = serverChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local lookAngle = if isP1Server then 0 else math.rad(180)
			root.CFrame = CFrame.new(serveX, 3.0, serveZ) * CFrame.Angles(0, lookAngle, 0)
		end
	end

	-- Spawn ball in front of server
	if currentMatch.currentBallId then
		BallService.destroyBall(currentMatch.currentBallId)
		currentMatch.currentBallId = nil
	end

	local ballSpawnOffset = if isP1Server then Vector3.new(0.5, 3.5, 1.2) else Vector3.new(-0.5, 3.5, -1.2)
	local ballPos = Vector3.new(serveX, 0, serveZ) + ballSpawnOffset
	local ballId = BallService.createBall(ballPos)
	currentMatch.currentBallId = ballId

	RallyManager.setServingState(score.servingPlayerId, score.serverSide, false)
	RallyManager.setBallId(ballId)

	broadcastMatchState("Serving")
end

function MatchService.startMatch(p1: Player, p2: Player, courtId: string?)
	local actualCourtId = courtId or "Court_1"
	CourtManager.assignPlayersToCourt(p1, p2, actualCourtId)

	local initialScore = RulesEngine.createInitialScore(p1.UserId, p2.UserId)

	currentMatch = {
		courtId = actualCourtId,
		player1 = p1,
		player2 = p2,
		score = initialScore,
		state = "Warmup",
		currentBallId = nil,
	}

	RallyManager.setActiveMatch(
		actualCourtId,
		p1.UserId,
		p2.UserId,
		initialScore.servingPlayerId,
		initialScore.serverSide
	)

	broadcastMatchState("Warmup")

	task.delay(3.0, function()
		if currentMatch and currentMatch.state == "Warmup" then
			prepareServing()
		end
	end)
end

local function onPointEnded(winnerUserId: number, reason: Types.PointEndReason)
	if not currentMatch then
		return
	end

	local oldScore = currentMatch.score
	local newScore, isGameOver, isMatchOver = RulesEngine.awardPoint(oldScore, winnerUserId)
	currentMatch.score = newScore

	local announcePayload: Types.PointAnnouncePayload = {
		reason = reason,
		winnerUserId = winnerUserId,
		newScore = newScore,
	}
	Network.fireAllClients("PointAnnounced", announcePayload)

	broadcastMatchState("PointEnded")

	task.delay(2.5, function()
		if not currentMatch then
			return
		end

		if isMatchOver then
			broadcastMatchState("MatchEnded")
			task.delay(5.0, function()
				if currentMatch then
					CourtManager.releaseCourt(currentMatch.courtId)
					currentMatch = nil
					broadcastMatchState("Waiting")
				end
			end)
		else
			prepareServing()
		end
	end)
end

function MatchService.init()
	CourtManager.init()
	RallyManager.init()

	RallyManager.OnPointCompleted:Connect(function(winnerUserId, reason)
		onPointEnded(winnerUserId, reason)
	end)

	-- Auto match when 2 players join
	Players.PlayerAdded:Connect(function(player)
		local players = Players:GetPlayers()
		if #players == 2 and not currentMatch then
			task.wait(1.5)
			if #Players:GetPlayers() >= 2 and not currentMatch then
				local pList = Players:GetPlayers()
				MatchService.startMatch(pList[1], pList[2])
			end
		end
	end)
end

return MatchService

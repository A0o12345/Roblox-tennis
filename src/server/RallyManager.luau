--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local TrajectoryMath = require(Shared:WaitForChild("TrajectoryMath"))
local CourtData = require(Shared:WaitForChild("CourtData"))
local Network = require(Shared:WaitForChild("Network"))

local BallService = require(script.Parent:WaitForChild("BallService"))

local RallyManager = {}

local pointCompletedBindable = Instance.new("BindableEvent")
RallyManager.OnPointCompleted = pointCompletedBindable.Event

type ActiveMatchContext = {
	courtId: string,
	ballId: string?,
	player1Id: number,
	player2Id: number,
	servingPlayerId: number,
	servingSide: Types.ServingSide,
	isServe: boolean,
	isSecondServe: boolean,
	lastHitterId: number,
	firstBounceIn: boolean,
	rallyInProgress: boolean,
}

local activeMatch: ActiveMatchContext? = nil

local FLIGHT_TIMES: { [Types.ShotType]: number } = {
	["Flat"] = 0.85,
	["Topspin"] = 0.95,
	["Slice"] = 1.20,
	["Lob"] = 1.70,
	["DropShot"] = 1.10,
	["Serve"] = 0.90,
}

function RallyManager.setActiveMatch(
	courtId: string,
	p1Id: number,
	p2Id: number,
	serverPlayerId: number,
	servingSide: Types.ServingSide
)
	activeMatch = {
		courtId = courtId,
		ballId = nil,
		player1Id = p1Id,
		player2Id = p2Id,
		servingPlayerId = serverPlayerId,
		servingSide = servingSide,
		isServe = true,
		isSecondServe = false,
		lastHitterId = serverPlayerId,
		firstBounceIn = false,
		rallyInProgress = true,
	}
end

function RallyManager.setServingState(serverPlayerId: number, servingSide: Types.ServingSide, isSecondServe: boolean)
	if activeMatch then
		activeMatch.servingPlayerId = serverPlayerId
		activeMatch.servingSide = servingSide
		activeMatch.isServe = true
		activeMatch.isSecondServe = isSecondServe
		activeMatch.lastHitterId = serverPlayerId
		activeMatch.firstBounceIn = false
		activeMatch.rallyInProgress = true
	end
end

function RallyManager.setBallId(ballId: string)
	if activeMatch then
		activeMatch.ballId = ballId
	end
end

function RallyManager.validateHit(
	player: Player,
	payload: Types.HitRequestPayload
): (boolean, string?)
	if not activeMatch or not activeMatch.rallyInProgress then
		return false, "No active rally"
	end

	local ballId = activeMatch.ballId
	if not ballId then
		return false, "No active ball"
	end

	local ballData = BallService.getBall(ballId)
	if not ballData then
		return false, "Ball not found"
	end

	local character = player.Character
	if not character then
		return false, "No character"
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return false, "No root part"
	end

	-- Distance validation
	local playerPos = rootPart.Position
	local ballPos = ballData.instance.Position

	if not activeMatch.isServe then
		local distance = (playerPos - ballPos).Magnitude
		if distance > 9.0 then
			return false, "Too far from ball"
		end
	end

	-- Check double bounce
	if ballData.bounceCount >= 2 then
		-- Too late, double bounce
		local opponentId = if player.UserId == activeMatch.player1Id
			then activeMatch.player2Id
			else activeMatch.player1Id
		RallyManager.finishPoint(opponentId, "DoubleBounce")
		return false, "Double bounce occurred"
	end

	-- Check volley on serve return
	if activeMatch.isServe and player.UserId ~= activeMatch.servingPlayerId then
		if ballData.bounceCount == 0 then
			-- Cannot volley a serve
			RallyManager.finishPoint(activeMatch.servingPlayerId, "Fault")
			return false, "Cannot volley a serve"
		end
	end

	return true, nil
end

function RallyManager.finishPoint(winnerUserId: number, reason: Types.PointEndReason)
	if not activeMatch or not activeMatch.rallyInProgress then
		return
	end

	activeMatch.rallyInProgress = false
	if activeMatch.ballId then
		BallService.stopBall(activeMatch.ballId)
	end

	pointCompletedBindable:Fire(winnerUserId, reason)
end

function RallyManager.onHitRequest(player: Player, payload: any)
	local validPayload = payload :: Types.HitRequestPayload
	local isValid, err = RallyManager.validateHit(player, validPayload)
	if not isValid then
		return
	end

	if not activeMatch or not activeMatch.ballId then
		return
	end

	local ballId = activeMatch.ballId
	local ballData = BallService.getBall(ballId)
	if not ballData then
		return
	end

	local isPlayer1 = (player.UserId == activeMatch.player1Id)
	local currentBallPos = ballData.instance.Position

	-- Target calculation
	local targetX = validPayload.aimDirection.X * 12.0
	local targetZ: number

	local baseFlightTime = FLIGHT_TIMES[validPayload.shotType] or 0.85

	if validPayload.timing == "Perfect" then
		baseFlightTime = baseFlightTime * 0.9
	elseif validPayload.timing == "Early" or validPayload.timing == "Late" then
		local spread = (math.random() - 0.5) * 5.0
		targetX += spread
	end

	if validPayload.shotType == "DropShot" then
		if isPlayer1 then
			targetZ = 7.0
		else
			targetZ = -7.0
		end
	elseif validPayload.shotType == "Serve" then
		-- Target service box diagonally
		if isPlayer1 then
			targetZ = 12.0
			targetX = if activeMatch.servingSide == "Deuce" then 6.0 else -6.0
		else
			targetZ = -12.0
			targetX = if activeMatch.servingSide == "Deuce" then -6.0 else 6.0
		end
	else
		-- Depth based on aimDirection.Y and power
		local depth = math.clamp(validPayload.aimDirection.Y * validPayload.power, 0.2, 1.0)
		if isPlayer1 then
			targetZ = 15.0 + depth * 21.0 -- Z in [19.2, 36.0]
		else
			targetZ = -15.0 - depth * 21.0 -- Z in [-36.0, -19.2]
		end
	end

	local targetPos = Vector3.new(targetX, TrajectoryMath.COURT_Y, targetZ)
	local launchVel = TrajectoryMath.calculateLaunchVelocity(currentBallPos, targetPos, baseFlightTime)

	activeMatch.lastHitterId = player.UserId
	activeMatch.firstBounceIn = false

	if activeMatch.isServe and player.UserId == activeMatch.servingPlayerId then
		-- Serve launched
		activeMatch.isServe = false
	end

	BallService.launch(ballId, launchVel, validPayload.shotType, player.UserId)
end

function RallyManager.onBounce(ballId: string, bouncePos: Vector3, bounceCount: number, hitterUserId: number)
	if not activeMatch or not activeMatch.rallyInProgress or activeMatch.ballId ~= ballId then
		return
	end

	local hitterId = if hitterUserId ~= 0 then hitterUserId else activeMatch.lastHitterId
	local opponentId = if hitterId == activeMatch.player1Id then activeMatch.player2Id else activeMatch.player1Id

	if bounceCount == 1 then
		local isInside = CourtData.isInsideCourt(bouncePos)
		if not isInside then
			-- Ball bounced OUT on first bounce! Hitter loses point
			RallyManager.finishPoint(opponentId, "Out")
			return
		else
			activeMatch.firstBounceIn = true
		end
	elseif bounceCount == 2 then
		-- If first bounce was in court and receiver didn't hit it before second bounce -> Winner!
		if activeMatch.firstBounceIn then
			RallyManager.finishPoint(hitterId, "Winner")
		else
			RallyManager.finishPoint(opponentId, "Out")
		end
	end
end

function RallyManager.onNetHit(ballId: string, netPos: Vector3, hitterUserId: number)
	if not activeMatch or not activeMatch.rallyInProgress or activeMatch.ballId ~= ballId then
		return
	end

	local hitterId = if hitterUserId ~= 0 then hitterUserId else activeMatch.lastHitterId
	local opponentId = if hitterId == activeMatch.player1Id then activeMatch.player2Id else activeMatch.player1Id

	-- Hitter hit into the net -> opponent wins point
	RallyManager.finishPoint(opponentId, "Net")
end

function RallyManager.init()
	local hitRemote = Network.getRemote("HitBallRequest")
	hitRemote.OnServerEvent:Connect(function(player, payload)
		RallyManager.onHitRequest(player, payload)
	end)

	BallService.OnBounce:Connect(function(ballId, bouncePos, bounceCount, hitterUserId)
		RallyManager.onBounce(ballId, bouncePos, bounceCount, hitterUserId)
	end)

	BallService.OnNetHit:Connect(function(ballId, netPos, hitterUserId)
		RallyManager.onNetHit(ballId, netPos, hitterUserId)
	end)
end

return RallyManager

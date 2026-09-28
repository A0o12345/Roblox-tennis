--!strict

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local TrajectoryMath = require(Shared:WaitForChild("TrajectoryMath"))
local Network = require(Shared:WaitForChild("Network"))

export type ActiveBall = {
	ballId: string,
	instance: Part,
	origin: Vector3,
	velocity: Vector3,
	shotType: Types.ShotType,
	startTime: number,
	hitterUserId: number,
	bounceCount: number,
	active: boolean,
	lastCheckedTime: number,
	timeToGround: number?,
}

local BallService = {}

local activeBalls: { [string]: ActiveBall } = {}

local bounceBindable = Instance.new("BindableEvent")
local netHitBindable = Instance.new("BindableEvent")

BallService.OnBounce = bounceBindable.Event
BallService.OnNetHit = netHitBindable.Event

local ballsFolder: Folder
do
	local existing = workspace:FindFirstChild("TennisBalls")
	if existing and existing:IsA("Folder") then
		ballsFolder = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "TennisBalls"
		folder.Parent = workspace
		ballsFolder = folder
	end
end

function BallService.createBall(startPosition: Vector3): string
	local ballId = HttpService:GenerateGUID(false)

	local ballPart = Instance.new("Part")
	ballPart.Name = "TennisBall_" .. ballId
	ballPart.Shape = Enum.PartType.Ball
	ballPart.Size = Vector3.new(0.8, 0.8, 0.8)
	ballPart.Color = Color3.fromRGB(220, 240, 40)
	ballPart.Material = Enum.Material.SmoothPlastic
	ballPart.CanCollide = false
	ballPart.CanTouch = false
	ballPart.CanQuery = false
	ballPart.Anchored = true
	ballPart.CFrame = CFrame.new(startPosition)
	ballPart:SetAttribute("BallId", ballId)
	ballPart.Parent = ballsFolder

	local ballData: ActiveBall = {
		ballId = ballId,
		instance = ballPart,
		origin = startPosition,
		velocity = Vector3.zero,
		shotType = "Flat",
		startTime = workspace:GetServerTimeNow(),
		hitterUserId = 0,
		bounceCount = 0,
		active = false,
		lastCheckedTime = 0,
		timeToGround = nil,
	}

	activeBalls[ballId] = ballData
	return ballId
end

function BallService.getBall(ballId: string): ActiveBall?
	return activeBalls[ballId]
end

function BallService.launch(
	ballId: string,
	velocity: Vector3,
	shotType: Types.ShotType,
	hitterUserId: number
)
	local ball = activeBalls[ballId]
	if not ball then
		return
	end

	local now = workspace:GetServerTimeNow()
	local currentPos = ball.instance.Position

	ball.origin = currentPos
	ball.velocity = velocity
	ball.shotType = shotType
	ball.startTime = now
	ball.hitterUserId = hitterUserId
	ball.bounceCount = 0
	ball.active = true
	ball.lastCheckedTime = 0
	ball.timeToGround = TrajectoryMath.calculateTimeToGround(ball.origin, velocity, TrajectoryMath.COURT_Y)

	Network.fireAllClients("BallStateBroadcast", {
		ballId = ballId,
		origin = ball.origin,
		velocity = velocity,
		shotType = shotType,
		startTime = now,
		hitterUserId = hitterUserId,
		bounceCount = 0,
	})
end

function BallService.stopBall(ballId: string)
	local ball = activeBalls[ballId]
	if ball then
		ball.active = false
		ball.velocity = Vector3.zero
	end
end

function BallService.destroyBall(ballId: string)
	local ball = activeBalls[ballId]
	if ball then
		activeBalls[ballId] = nil
		if ball.instance then
			ball.instance:Destroy()
		end
	end
end

function BallService.onHeartbeat(dt: number)
	local now = workspace:GetServerTimeNow()

	for ballId, ball in pairs(activeBalls) do
		if ball.active then
			local flightTime = now - ball.startTime
			if flightTime < 0 then
				flightTime = 0
			end

			-- Check net collision if ball crossed Z = 0
			local hitNet, tNet, netPoint = TrajectoryMath.checkNetCollision(ball.origin, ball.velocity, 0, 3.2, 3.8)
			if hitNet and tNet and netPoint then
				if flightTime >= tNet and ball.lastCheckedTime < tNet then
					netHitBindable:Fire(ballId, netPoint, ball.hitterUserId)
					-- Net slows ball and deflects downward
					ball.origin = netPoint
					ball.velocity = Vector3.new(ball.velocity.X * 0.2, -5, -ball.velocity.Z * 0.1)
					ball.startTime = now
					flightTime = 0
					ball.timeToGround = TrajectoryMath.calculateTimeToGround(ball.origin, ball.velocity, TrajectoryMath.COURT_Y)

					Network.fireAllClients("BallStateBroadcast", {
						ballId = ballId,
						origin = ball.origin,
						velocity = ball.velocity,
						shotType = ball.shotType,
						startTime = now,
						hitterUserId = ball.hitterUserId,
						bounceCount = ball.bounceCount,
					})
				end
			end

			-- Check bounce on court ground
			local tGround = ball.timeToGround
			if tGround and flightTime >= tGround then
				local bouncePos = TrajectoryMath.calculatePosition(ball.origin, ball.velocity, tGround)
				local impactVel = TrajectoryMath.calculateVelocity(ball.velocity, tGround)
				ball.bounceCount += 1

				bounceBindable:Fire(ballId, bouncePos, ball.bounceCount, ball.hitterUserId)

				if ball.bounceCount <= 3 then
					local newVel = TrajectoryMath.calculateBounce(impactVel, ball.shotType)
					ball.origin = Vector3.new(bouncePos.X, TrajectoryMath.COURT_Y, bouncePos.Z)
					ball.velocity = newVel
					ball.startTime = now
					flightTime = 0
					ball.timeToGround = TrajectoryMath.calculateTimeToGround(ball.origin, newVel, TrajectoryMath.COURT_Y)

					Network.fireAllClients("BallStateBroadcast", {
						ballId = ballId,
						origin = ball.origin,
						velocity = newVel,
						shotType = ball.shotType,
						startTime = now,
						hitterUserId = ball.hitterUserId,
						bounceCount = ball.bounceCount,
					})
				else
					ball.active = false
					ball.instance.CFrame = CFrame.new(bouncePos.X, TrajectoryMath.COURT_Y, bouncePos.Z)
				end
			else
				local currentPos = TrajectoryMath.calculatePosition(ball.origin, ball.velocity, flightTime)
				ball.instance.CFrame = CFrame.new(currentPos)
			end

			ball.lastCheckedTime = flightTime
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	BallService.onHeartbeat(dt)
end)

return BallService

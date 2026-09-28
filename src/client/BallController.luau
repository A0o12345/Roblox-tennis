--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local TrajectoryMath = require(Shared:WaitForChild("TrajectoryMath"))
local Network = require(Shared:WaitForChild("Network"))

type ClientBallState = {
	ballId: string,
	origin: Vector3,
	velocity: Vector3,
	shotType: Types.ShotType,
	startTime: number,
	hitterUserId: number,
	bounceCount: number,
	visualPart: Part?,
	shadowPart: Part?,
	trail: Trail?,
	active: boolean,
}

local BallController = {}

local clientBalls: { [string]: ClientBallState } = {}
local activeBallId: string? = nil

local visualFolder: Folder
do
	local existing = workspace:FindFirstChild("ClientBallVisuals")
	if existing and existing:IsA("Folder") then
		visualFolder = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "ClientBallVisuals"
		folder.Parent = workspace
		visualFolder = folder
	end
end

local function createVisualBall(ballId: string): (Part, Part, Trail)
	local ball = Instance.new("Part")
	ball.Name = "ClientBall_" .. ballId
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.8, 0.8, 0.8)
	ball.Color = Color3.fromRGB(225, 245, 45)
	ball.Material = Enum.Material.Neon
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = false
	ball.Anchored = true
	ball.Parent = visualFolder

	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 0.35, 0)
	att0.Parent = ball

	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, -0.35, 0)
	att1.Parent = ball

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.25
	trail.MinLength = 0.1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 240, 50)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	trail.Parent = ball

	-- Dynamic drop shadow
	local shadow = Instance.new("Part")
	shadow.Name = "BallShadow_" .. ballId
	shadow.Size = Vector3.new(1.2, 0.05, 1.2)
	shadow.Shape = Enum.PartType.Cylinder
	shadow.CFrame = CFrame.Angles(0, 0, math.rad(90))
	shadow.Color = Color3.fromRGB(15, 25, 20)
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Transparency = 0.5
	shadow.CanCollide = false
	shadow.CanTouch = false
	shadow.CanQuery = false
	shadow.Anchored = true
	shadow.Parent = visualFolder

	return ball, shadow, trail
end

function BallController.onBallBroadcast(data: any)
	if not data or not data.ballId then
		return
	end

	local ballId = tostring(data.ballId)
	activeBallId = ballId

	local state = clientBalls[ballId]
	if not state then
		local visualPart, shadowPart, trail = createVisualBall(ballId)
		state = {
			ballId = ballId,
			origin = data.origin or Vector3.zero,
			velocity = data.velocity or Vector3.zero,
			shotType = data.shotType or "Flat",
			startTime = data.startTime or workspace:GetServerTimeNow(),
			hitterUserId = data.hitterUserId or 0,
			bounceCount = data.bounceCount or 0,
			visualPart = visualPart,
			shadowPart = shadowPart,
			trail = trail,
			active = true,
		}
		clientBalls[ballId] = state
	else
		state.origin = data.origin
		state.velocity = data.velocity
		state.shotType = data.shotType
		state.startTime = data.startTime
		state.hitterUserId = data.hitterUserId
		state.bounceCount = data.bounceCount
		state.active = true
	end
end

function BallController.getActiveBall(): (ClientBallState?, Vector3?)
	if not activeBallId then
		return nil, nil
	end
	local ball = clientBalls[activeBallId]
	if not ball or not ball.active then
		return nil, nil
	end

	local now = workspace:GetServerTimeNow()
	local dt = math.max(0, now - ball.startTime)
	local currentPos = TrajectoryMath.calculatePosition(ball.origin, ball.velocity, dt)
	return ball, currentPos
end

function BallController.init()
	local remote = Network.getRemote("BallStateBroadcast")
	remote.OnClientEvent:Connect(function(data)
		BallController.onBallBroadcast(data)
	end)

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()

		for _, state in pairs(clientBalls) do
			if state.active and state.visualPart and state.shadowPart then
				local dt = math.max(0, now - state.startTime)
				local pos = TrajectoryMath.calculatePosition(state.origin, state.velocity, dt)

				state.visualPart.CFrame = CFrame.new(pos)

				-- Update drop shadow
				local heightAboveCourt = math.max(0, pos.Y - TrajectoryMath.COURT_Y)
				local shadowScale = math.clamp(1.0 + heightAboveCourt * 0.12, 0.8, 2.5)
				state.shadowPart.Size = Vector3.new(0.05, 1.2 * shadowScale, 1.2 * shadowScale)
				state.shadowPart.CFrame = CFrame.new(pos.X, 0.52, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
				state.shadowPart.Transparency = math.clamp(0.4 + heightAboveCourt * 0.04, 0.4, 0.85)
			end
		end
	end)
end

return BallController

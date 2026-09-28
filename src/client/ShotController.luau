--!strict

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Network = require(Shared:WaitForChild("Network"))

local BallController = require(script.Parent:WaitForChild("BallController"))
local TimingMeter = require(script.Parent:WaitForChild("TimingMeter"))

local localPlayer = Players.LocalPlayer

local ShotController = {}

local isCharging = false
local chargeStartTime = 0.0
local selectedShotType: Types.ShotType = "Flat"
local chargeHeartbeatConn: RBXScriptConnection? = nil

local KEY_TO_SHOT: { [Enum.KeyCode]: Types.ShotType } = {
	[Enum.KeyCode.E] = "Flat",
	[Enum.KeyCode.Q] = "Topspin",
	[Enum.KeyCode.R] = "Slice",
	[Enum.KeyCode.F] = "Lob",
	[Enum.KeyCode.C] = "DropShot",
	[Enum.KeyCode.Space] = "Serve",
	-- Gamepad bindings
	[Enum.KeyCode.ButtonA] = "Flat",
	[Enum.KeyCode.ButtonX] = "Topspin",
	[Enum.KeyCode.ButtonB] = "Slice",
	[Enum.KeyCode.ButtonY] = "Lob",
	[Enum.KeyCode.ButtonR2] = "DropShot",
}

function ShotController.calculateAim(): Vector2
	local aimX = 0.0
	local aimY = 0.6 -- default medium depth

	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		aimX -= 0.85
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		aimX += 0.85
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		aimY = 1.0 -- deep to baseline
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		aimY = 0.25 -- short court
	end

	return Vector2.new(math.clamp(aimX, -1, 1), math.clamp(aimY, 0, 1))
end

local function calculateTimingQuality(charPos: Vector3, ballPos: Vector3, isServe: boolean): (Types.TimingQuality, boolean)
	if isServe then
		return "Perfect", true
	end

	local dist = (charPos - ballPos).Magnitude
	if dist > 9.0 then
		-- Missed the ball completely
		return "Early", false
	elseif dist >= 3.0 and dist <= 5.8 then
		return "Perfect", true
	elseif dist > 5.8 and dist <= 9.0 then
		return "Early", true
	else
		return "Late", true
	end
end

function ShotController.onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	local shot: Types.ShotType? = nil
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		shot = "Flat"
	elseif input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 then
		shot = KEY_TO_SHOT[input.KeyCode]
	end

	if not shot then
		return
	end

	if isCharging then
		return
	end

	isCharging = true
	chargeStartTime = os.clock()
	selectedShotType = shot

	if chargeHeartbeatConn then
		chargeHeartbeatConn:Disconnect()
	end

	chargeHeartbeatConn = RunService.Heartbeat:Connect(function()
		if not isCharging then
			return
		end
		local elapsed = os.clock() - chargeStartTime
		local ratio = math.clamp(elapsed / 0.5, 0, 1)
		TimingMeter.updateCharge(ratio)
	end)
end

function ShotController.onInputEnded(input: InputObject, gameProcessed: boolean)
	if not isCharging then
		return
	end

	local isRelevant = false
	if input.UserInputType == Enum.UserInputType.MouseButton1 and selectedShotType == "Flat" then
		isRelevant = true
	elseif KEY_TO_SHOT[input.KeyCode] == selectedShotType then
		isRelevant = true
	end

	if not isRelevant then
		return
	end

	isCharging = false
	if chargeHeartbeatConn then
		chargeHeartbeatConn:Disconnect()
		chargeHeartbeatConn = nil
	end
	TimingMeter.hideCharge()

	local elapsed = os.clock() - chargeStartTime
	local power = math.clamp(0.5 + (elapsed / 0.5) * 0.5, 0.5, 1.0)
	local aimVector = ShotController.calculateAim()

	local character = localPlayer.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local isServe = (selectedShotType == "Serve")
	local _, ballPos = BallController.getActiveBall()
	local effectiveBallPos = ballPos or rootPart.Position

	local timingQuality, canHit = calculateTimingQuality(rootPart.Position, effectiveBallPos, isServe)

	if not canHit and not isServe then
		-- Whiff / too far from ball
		TimingMeter.showFeedback("Late")
		return
	end

	TimingMeter.showFeedback(timingQuality)

	local payload: Types.HitRequestPayload = {
		shotType = selectedShotType,
		aimDirection = aimVector,
		power = power,
		timing = timingQuality,
		clientTimestamp = workspace:GetServerTimeNow(),
	}

	Network.fireServer("HitBallRequest", payload)
end

function ShotController.init()
	TimingMeter.init()

	UserInputService.InputBegan:Connect(function(input, gpe)
		ShotController.onInputBegan(input, gpe)
	end)

	UserInputService.InputEnded:Connect(function(input, gpe)
		ShotController.onInputEnded(input, gpe)
	end)
end

return ShotController

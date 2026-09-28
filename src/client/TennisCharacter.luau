--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

local TennisCharacter = {}

local localPlayer = Players.LocalPlayer
local currentSide: Types.CourtSide = "Player1"
local boundaryEnabled = true

local function buildRacket(): Model
	local racketModel = Instance.new("Model")
	racketModel.Name = "TennisRacket"

	-- Handle / Grip
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.3, 1.2, 0.3)
	grip.Color = Color3.fromRGB(30, 30, 30)
	grip.Material = Enum.Material.Fabric
	grip.CanCollide = false
	grip.CanTouch = false
	grip.CanQuery = false
	grip.Massless = true
	grip.Parent = racketModel
	racketModel.PrimaryPart = grip

	-- Throat
	local throat = Instance.new("Part")
	throat.Name = "Throat"
	throat.Size = Vector3.new(0.25, 0.6, 0.2)
	throat.CFrame = grip.CFrame * CFrame.new(0, 0.9, 0)
	throat.Color = Color3.fromRGB(200, 30, 30)
	throat.Material = Enum.Material.SmoothPlastic
	throat.CanCollide = false
	throat.CanTouch = false
	throat.CanQuery = false
	throat.Massless = true
	throat.Parent = racketModel

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = grip
	w1.Part1 = throat
	w1.Parent = grip

	-- Racket Head Frame
	local head = Instance.new("Part")
	head.Name = "HeadFrame"
	head.Size = Vector3.new(1.4, 1.8, 0.15)
	head.CFrame = grip.CFrame * CFrame.new(0, 1.9, 0)
	head.Color = Color3.fromRGB(220, 40, 40)
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.CanTouch = false
	head.CanQuery = false
	head.Massless = true
	head.Parent = racketModel

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = grip
	w2.Part1 = head
	w2.Parent = grip

	-- Strings
	local strings = Instance.new("Part")
	strings.Name = "Strings"
	strings.Size = Vector3.new(1.2, 1.6, 0.05)
	strings.CFrame = head.CFrame
	strings.Color = Color3.fromRGB(240, 240, 240)
	strings.Material = Enum.Material.Glass
	strings.Transparency = 0.55
	strings.CanCollide = false
	strings.CanTouch = false
	strings.CanQuery = false
	strings.Massless = true
	strings.Parent = racketModel

	local w3 = Instance.new("WeldConstraint")
	w3.Part0 = grip
	w3.Part1 = strings
	w3.Parent = grip

	return racketModel
end

function TennisCharacter.equipRacket(character: Model?)
	local char = character or localPlayer.Character
	if not char then
		return
	end

	local existing = char:FindFirstChild("TennisRacket")
	if existing then
		existing:Destroy()
	end

	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end

	local racket = buildRacket()
	local grip = racket.PrimaryPart
	if not grip then
		return
	end

	grip.CFrame = hand.CFrame * CFrame.new(0, -0.6, -0.3) * CFrame.Angles(math.rad(90), 0, 0)
	racket.Parent = char

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = grip
	weld.Parent = hand
end

function TennisCharacter.setCourtSide(side: Types.CourtSide)
	currentSide = side
end

function TennisCharacter.getCourtSide(): Types.CourtSide
	return currentSide
end

function TennisCharacter.setBoundaryEnabled(enabled: boolean)
	boundaryEnabled = enabled
end

function TennisCharacter.init()
	if localPlayer.Character then
		TennisCharacter.equipRacket(localPlayer.Character)
	end

	localPlayer.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		TennisCharacter.equipRacket(char)
	end)

	RunService.RenderStepped:Connect(function()
		if not boundaryEnabled then
			return
		end

		local char = localPlayer.Character
		if not char then
			return
		end

		local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not rootPart or not humanoid or humanoid.Health <= 0 then
			return
		end

		local pos = rootPart.Position
		local clampedX = math.clamp(pos.X, -24, 24)
		local clampedZ: number

		if currentSide == "Player1" then
			-- Half 1: Z in [-52, -1.5]
			clampedZ = math.clamp(pos.Z, -52, -1.5)
		else
			-- Half 2: Z in [1.5, 52]
			clampedZ = math.clamp(pos.Z, 1.5, 52)
		end

		if clampedX ~= pos.X or clampedZ ~= pos.Z then
			rootPart.CFrame = CFrame.new(clampedX, pos.Y, clampedZ) * (rootPart.CFrame - rootPart.CFrame.Position)
		end
	end)
end

return TennisCharacter

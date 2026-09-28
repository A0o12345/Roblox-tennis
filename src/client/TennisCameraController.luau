--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

local TennisCameraController = {}

local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local isEnabled = false
local currentSide: Types.CourtSide = "Player1"
local renderConnection: RBXScriptConnection? = nil

local CAMERA_HEIGHT = 10.0
local CAMERA_DISTANCE = 14.0
local LOOK_OFFSET_Y = 3.0
local LERP_ALPHA = 0.15

function TennisCameraController.onRenderStep(dt: number)
	if not isEnabled or not camera then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local charPos = rootPart.Position
	local targetCamPos: Vector3
	local lookTarget: Vector3

	if currentSide == "Player1" then
		-- Player 1 is on Z < 0, looking towards +Z
		targetCamPos = Vector3.new(charPos.X * 0.7, charPos.Y + CAMERA_HEIGHT, charPos.Z - CAMERA_DISTANCE)
		lookTarget = Vector3.new(charPos.X * 0.4, charPos.Y + LOOK_OFFSET_Y, charPos.Z + 35)
	else
		-- Player 2 is on Z > 0, looking towards -Z
		targetCamPos = Vector3.new(charPos.X * 0.7, charPos.Y + CAMERA_HEIGHT, charPos.Z + CAMERA_DISTANCE)
		lookTarget = Vector3.new(charPos.X * 0.4, charPos.Y + LOOK_OFFSET_Y, charPos.Z - 35)
	end

	local desiredCFrame = CFrame.lookAt(targetCamPos, lookTarget)
	camera.CFrame = camera.CFrame:Lerp(desiredCFrame, math.clamp(dt * 10, 0.05, 0.35))
	camera.FieldOfView = 70
end

function TennisCameraController.enable(side: Types.CourtSide)
	currentSide = side
	isEnabled = true
	camera = workspace.CurrentCamera

	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 70
	end

	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(function(dt)
			TennisCameraController.onRenderStep(dt)
		end)
	end
end

function TennisCameraController.disable()
	isEnabled = false
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

return TennisCameraController

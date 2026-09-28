--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

local TimingMeter = {}

local localPlayer = Players.LocalPlayer
local billboardGui: BillboardGui? = nil
local fillBar: Frame? = nil
local meterFrame: Frame? = nil
local feedbackLabel: TextLabel? = nil

function TimingMeter.init()
	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local existing = playerGui:FindFirstChild("TennisTimingGui")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "TennisTimingGui"
	gui.Size = UDim2.new(0, 160, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 100
	gui.Enabled = false
	billboardGui = gui

	-- Background container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 0, 16)
	container.Position = UDim2.new(0, 0, 0, 24)
	container.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = gui
	meterFrame = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 120, 180)
	stroke.Thickness = 1.5
	stroke.Parent = container

	-- Fill bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
	fill.BorderSizePixel = 0
	fill.Parent = container
	fillBar = fill

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = fill

	-- Feedback label
	local label = Instance.new("TextLabel")
	label.Name = "FeedbackLabel"
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = gui
	feedbackLabel = label

	local function attachToChar(char: Model)
		local head = char:WaitForChild("Head", 5) :: BasePart?
		if head and billboardGui then
			billboardGui.Adornee = head
		end
	end

	if localPlayer.Character then
		attachToChar(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(attachToChar)

	gui.Parent = playerGui
end

function TimingMeter.updateCharge(ratio: number)
	if not billboardGui or not fillBar or not meterFrame then
		return
	end

	billboardGui.Enabled = true
	meterFrame.Visible = true

	local clamped = math.clamp(ratio, 0, 1)
	fillBar.Size = UDim2.new(clamped, 0, 1, 0)

	-- Color shift based on charge: blue -> green -> gold
	if clamped < 0.6 then
		fillBar.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
	elseif clamped < 0.9 then
		fillBar.BackgroundColor3 = Color3.fromRGB(70, 230, 110)
	else
		fillBar.BackgroundColor3 = Color3.fromRGB(255, 215, 40)
	end
end

function TimingMeter.hideCharge()
	if meterFrame then
		meterFrame.Visible = false
	end
	if fillBar then
		fillBar.Size = UDim2.new(0, 0, 1, 0)
	end
end

function TimingMeter.showFeedback(quality: Types.TimingQuality)
	if not billboardGui or not feedbackLabel then
		return
	end

	billboardGui.Enabled = true
	feedbackLabel.Visible = true
	feedbackLabel.TextTransparency = 0
	feedbackLabel.TextSize = 20

	if quality == "Perfect" then
		feedbackLabel.Text = "PERFECT!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	elseif quality == "Good" then
		feedbackLabel.Text = "GOOD"
		feedbackLabel.TextColor3 = Color3.fromRGB(75, 235, 120)
	elseif quality == "Early" then
		feedbackLabel.Text = "EARLY"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 160, 40)
	else
		feedbackLabel.Text = "LATE"
		feedbackLabel.TextColor3 = Color3.fromRGB(245, 60, 60)
	end

	local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(feedbackLabel, tweenInfo, {
		TextTransparency = 1,
		TextSize = 24,
	})
	tween:Play()

	task.delay(0.8, function()
		if feedbackLabel and feedbackLabel.TextTransparency >= 0.9 then
			feedbackLabel.Visible = false
			if meterFrame and not meterFrame.Visible then
				billboardGui.Enabled = false
			end
		end
	end)
end

return TimingMeter

--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Network = require(Shared:WaitForChild("Network"))

local AnnouncerGui = {}

local localPlayer = Players.LocalPlayer
local screenGui: ScreenGui? = nil
local bannerContainer: Frame? = nil
local mainTitle: TextLabel? = nil
local subtitle: TextLabel? = nil
local bannerStroke: UIStroke? = nil

function AnnouncerGui.init()
	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local existing = playerGui:FindFirstChild("TennisAnnouncerGui")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "TennisAnnouncerGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	screenGui = gui

	-- Banner container
	local container = Instance.new("Frame")
	container.Name = "BannerContainer"
	container.Size = UDim2.new(0, 380, 0, 90)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.35, 0)
	container.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Visible = false
	container.Parent = gui
	bannerContainer = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2.0
	stroke.Transparency = 0.2
	stroke.Parent = container
	bannerStroke = stroke

	-- Main title
	local title = Instance.new("TextLabel")
	title.Name = "MainTitle"
	title.Size = UDim2.new(1, 0, 0, 48)
	title.Position = UDim2.new(0, 0, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 34
	title.Text = "OUT!"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.5
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Parent = container
	mainTitle = title

	-- Subtitle
	local sub = Instance.new("TextLabel")
	sub.Name = "Subtitle"
	sub.Size = UDim2.new(1, 0, 0, 24)
	sub.Position = UDim2.new(0, 0, 0, 54)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 16
	sub.Text = "Point to Player"
	sub.TextColor3 = Color3.fromRGB(200, 220, 240)
	sub.TextStrokeTransparency = 0.8
	sub.Parent = container
	subtitle = sub

	gui.Parent = playerGui

	-- Connect network events
	local pointRemote = Network.getRemote("PointAnnounced")
	pointRemote.OnClientEvent:Connect(function(payload: any)
		if not payload or not payload.reason then
			return
		end

		local reason = payload.reason :: Types.PointEndReason
		local winnerId = payload.winnerUserId
		local winnerPlayer = Players:GetPlayerByUserId(winnerId)
		local winnerName = if winnerPlayer then winnerPlayer.DisplayName else "Player"

		if reason == "Out" then
			AnnouncerGui.announce("OUT!", "Point for " .. winnerName, Color3.fromRGB(255, 75, 75))
		elseif reason == "Net" then
			AnnouncerGui.announce("NET", "Point for " .. winnerName, Color3.fromRGB(240, 90, 60))
		elseif reason == "Ace" then
			AnnouncerGui.announce("ACE!", "Serve winner: " .. winnerName, Color3.fromRGB(255, 215, 0))
		elseif reason == "Winner" then
			AnnouncerGui.announce("WINNER!", "Incredible shot by " .. winnerName, Color3.fromRGB(80, 230, 110))
		elseif reason == "DoubleBounce" then
			AnnouncerGui.announce("DOUBLE BOUNCE", "Point for " .. winnerName, Color3.fromRGB(255, 170, 40))
		elseif reason == "Fault" then
			AnnouncerGui.announce("FAULT", "First serve out", Color3.fromRGB(240, 100, 60))
		elseif reason == "DoubleFault" then
			AnnouncerGui.announce("DOUBLE FAULT", "Point for " .. winnerName, Color3.fromRGB(230, 50, 50))
		end
	end)

	local matchRemote = Network.getRemote("MatchStateChanged")
	matchRemote.OnClientEvent:Connect(function(payload: any)
		if not payload then
			return
		end
		if payload.state == "Warmup" then
			AnnouncerGui.announce("WARMUP", "Match starting shortly...", Color3.fromRGB(80, 180, 255))
		elseif payload.state == "MatchEnded" then
			AnnouncerGui.announce("GAME, SET & MATCH!", "Winner crowned!", Color3.fromRGB(255, 215, 50))
		end
	end)
end

function AnnouncerGui.announce(text: string, subText: string?, color: Color3?)
	if not bannerContainer or not mainTitle or not subtitle then
		return
	end

	local strokeColor = color or Color3.fromRGB(255, 255, 255)
	mainTitle.Text = text
	mainTitle.TextColor3 = strokeColor
	subtitle.Text = subText or ""

	if bannerStroke then
		bannerStroke.Color = strokeColor
	end

	bannerContainer.Visible = true
	bannerContainer.Size = UDim2.new(0, 320, 0, 75)
	bannerContainer.BackgroundTransparency = 1
	mainTitle.TextTransparency = 1
	subtitle.TextTransparency = 1

	local popTween = TweenService:Create(bannerContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 380, 0, 90),
		BackgroundTransparency = 0.15,
	})
	local titleTween = TweenService:Create(mainTitle, TweenInfo.new(0.3), { TextTransparency = 0 })
	local subTween = TweenService:Create(subtitle, TweenInfo.new(0.3), { TextTransparency = 0 })

	popTween:Play()
	titleTween:Play()
	subTween:Play()

	task.delay(1.6, function()
		if not bannerContainer then
			return
		end
		local fadeTween = TweenService:Create(bannerContainer, TweenInfo.new(0.4), {
			BackgroundTransparency = 1,
		})
		local fadeTitle = TweenService:Create(mainTitle, TweenInfo.new(0.4), { TextTransparency = 1 })
		local fadeSub = TweenService:Create(subtitle, TweenInfo.new(0.4), { TextTransparency = 1 })

		fadeTween:Play()
		fadeTitle:Play()
		fadeSub:Play()

		task.delay(0.45, function()
			if bannerContainer and bannerContainer.BackgroundTransparency >= 0.95 then
				bannerContainer.Visible = false
			end
		end)
	end)
end

return AnnouncerGui

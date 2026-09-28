--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local RulesEngine = require(Shared:WaitForChild("RulesEngine"))
local Network = require(Shared:WaitForChild("Network"))

local ScoreboardGui = {}

local localPlayer = Players.LocalPlayer
local screenGui: ScreenGui? = nil
local boardFrame: Frame? = nil

-- Player 1 elements
local p1ServeDot: TextLabel? = nil
local p1NameLabel: TextLabel? = nil
local p1SetsLabel: TextLabel? = nil
local p1GamesLabel: TextLabel? = nil
local p1PointsLabel: TextLabel? = nil

-- Player 2 elements
local p2ServeDot: TextLabel? = nil
local p2NameLabel: TextLabel? = nil
local p2SetsLabel: TextLabel? = nil
local p2GamesLabel: TextLabel? = nil
local p2PointsLabel: TextLabel? = nil

local function animateTextChange(label: TextLabel?, newText: string)
	if not label or label.Text == newText then
		return
	end

	local fadeOut = TweenService:Create(label, TweenInfo.new(0.15), { TextTransparency = 0.8 })
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		label.Text = newText
		local fadeIn = TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0 })
		fadeIn:Play()
	end)
end

function ScoreboardGui.updateScore(score: Types.ScoreState)
	if not boardFrame then
		return
	end

	local p1Name = "Player 1"
	local p2Name = "Player 2"

	if score.player1Id then
		local p1 = Players:GetPlayerByUserId(score.player1Id)
		if p1 then
			p1Name = p1.DisplayName
		end
	end
	if score.player2Id then
		local p2 = Players:GetPlayerByUserId(score.player2Id)
		if p2 then
			p2Name = p2.DisplayName
		end
	end

	if p1NameLabel then
		p1NameLabel.Text = p1Name
	end
	if p2NameLabel then
		p2NameLabel.Text = p2Name
	end

	-- Serving dots
	local isP1Serving = (score.servingPlayerId == score.player1Id)
	if p1ServeDot then
		p1ServeDot.Visible = isP1Serving
	end
	if p2ServeDot then
		p2ServeDot.Visible = not isP1Serving
	end

	-- Sets & Games
	animateTextChange(p1SetsLabel, tostring(score.player1Sets))
	animateTextChange(p2SetsLabel, tostring(score.player2Sets))
	animateTextChange(p1GamesLabel, tostring(score.player1Games))
	animateTextChange(p2GamesLabel, tostring(score.player2Games))

	-- Game Points
	local s1, s2 = RulesEngine.formatGameScore(score.player1Points, score.player2Points, score.isTiebreak)
	animateTextChange(p1PointsLabel, s1)
	animateTextChange(p2PointsLabel, s2)
end

function ScoreboardGui.init()
	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local existing = playerGui:FindFirstChild("TennisScoreboardGui")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "TennisScoreboardGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	screenGui = gui

	-- Main board frame
	local board = Instance.new("Frame")
	board.Name = "Scoreboard"
	board.Size = UDim2.new(0, 320, 0, 96)
	board.Position = UDim2.new(0, 24, 0, 24)
	board.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
	board.BackgroundTransparency = 0.15
	board.BorderSizePixel = 0
	board.Parent = gui
	boardFrame = board

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = board

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 75, 110)
	stroke.Thickness = 1.5
	stroke.Parent = board

	-- Tournament Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 20)
	header.Position = UDim2.new(0, 0, 0, 4)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 11
	header.Text = "GRAND SLAM TENNIS • MATCH"
	header.TextColor3 = Color3.fromRGB(140, 175, 220)
	header.Parent = board

	-- Header columns for Sets, Games, Points
	local function createColHeader(name: string, xPos: number)
		local col = Instance.new("TextLabel")
		col.Size = UDim2.new(0, 32, 0, 20)
		col.Position = UDim2.new(0, xPos, 0, 4)
		col.BackgroundTransparency = 1
		col.Font = Enum.Font.GothamBold
		col.TextSize = 10
		col.Text = name
		col.TextColor3 = Color3.fromRGB(140, 175, 220)
		col.Parent = board
	end

	createColHeader("SET", 205)
	createColHeader("GAME", 240)
	createColHeader("PTS", 275)

	-- Row builder
	local function createPlayerRow(yPos: number): (TextLabel, TextLabel, TextLabel, TextLabel, TextLabel)
		local dot = Instance.new("TextLabel")
		dot.Size = UDim2.new(0, 16, 0, 30)
		dot.Position = UDim2.new(0, 8, 0, yPos)
		dot.BackgroundTransparency = 1
		dot.Font = Enum.Font.GothamBlack
		dot.TextSize = 14
		dot.Text = "●"
		dot.TextColor3 = Color3.fromRGB(255, 225, 40)
		dot.Visible = false
		dot.Parent = board

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0, 175, 0, 30)
		name.Position = UDim2.new(0, 26, 0, yPos)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 14
		name.Text = "Player"
		name.TextColor3 = Color3.fromRGB(240, 245, 255)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = board

		local sets = Instance.new("TextLabel")
		sets.Size = UDim2.new(0, 32, 0, 30)
		sets.Position = UDim2.new(0, 205, 0, yPos)
		sets.BackgroundTransparency = 1
		sets.Font = Enum.Font.GothamBold
		sets.TextSize = 15
		sets.Text = "0"
		sets.TextColor3 = Color3.fromRGB(200, 220, 250)
		sets.Parent = board

		local games = Instance.new("TextLabel")
		games.Size = UDim2.new(0, 32, 0, 30)
		games.Position = UDim2.new(0, 240, 0, yPos)
		games.BackgroundTransparency = 1
		games.Font = Enum.Font.GothamBold
		games.TextSize = 15
		games.Text = "0"
		games.TextColor3 = Color3.fromRGB(255, 255, 255)
		games.Parent = board

		local pts = Instance.new("TextLabel")
		pts.Size = UDim2.new(0, 36, 0, 30)
		pts.Position = UDim2.new(0, 275, 0, yPos)
		pts.BackgroundTransparency = 1
		pts.Font = Enum.Font.GothamBlack
		pts.TextSize = 16
		pts.Text = "0"
		pts.TextColor3 = Color3.fromRGB(255, 225, 50)
		pts.Parent = board

		return dot, name, sets, games, pts
	end

	p1ServeDot, p1NameLabel, p1SetsLabel, p1GamesLabel, p1PointsLabel = createPlayerRow(28)
	p2ServeDot, p2NameLabel, p2SetsLabel, p2GamesLabel, p2PointsLabel = createPlayerRow(60)

	gui.Parent = playerGui

	-- Network connections
	local matchRemote = Network.getRemote("MatchStateChanged")
	matchRemote.OnClientEvent:Connect(function(payload: any)
		if payload and payload.score then
			ScoreboardGui.updateScore(payload.score)
		end
	end)

	local pointRemote = Network.getRemote("PointAnnounced")
	pointRemote.OnClientEvent:Connect(function(payload: any)
		if payload and payload.newScore then
			ScoreboardGui.updateScore(payload.newScore)
		end
	end)
end

return ScoreboardGui

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local PlayerScripts = localPlayer:WaitForChild("PlayerScripts")
local Client = PlayerScripts:WaitForChild("Client")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Network = require(Shared:WaitForChild("Network"))

local BallController = require(Client:WaitForChild("BallController"))
local TennisCameraController = require(Client:WaitForChild("TennisCameraController"))
local TennisCharacter = require(Client:WaitForChild("TennisCharacter"))
local ShotController = require(Client:WaitForChild("ShotController"))
local ScoreboardGui = require(Client:WaitForChild("ScoreboardGui"))
local AnnouncerGui = require(Client:WaitForChild("AnnouncerGui"))
local SoundManager = require(Client:WaitForChild("SoundManager"))

print("[Roblox Tennis] Initializing client subsystems...")

SoundManager.init()
ScoreboardGui.init()
AnnouncerGui.init()
TennisCharacter.init()
BallController.init()
ShotController.init()

-- Hook sound reactions
local pointRemote = Network.getRemote("PointAnnounced")
pointRemote.OnClientEvent:Connect(function(payload: any)
	if not payload then
		return
	end
	local reason = payload.reason :: Types.PointEndReason
	if reason == "Ace" or reason == "Winner" then
		SoundManager.playCheerSound()
	elseif reason == "Out" or reason == "Fault" or reason == "DoubleFault" then
		SoundManager.playWhistleSound()
	end
end)

local ballBroadcast = Network.getRemote("BallStateBroadcast")
ballBroadcast.OnClientEvent:Connect(function(payload: any)
	if not payload then
		return
	end
	if payload.bounceCount and payload.bounceCount > 0 then
		SoundManager.playBounceSound()
	else
		SoundManager.playHitSound(0.8)
	end
end)

-- Camera side alignment on match state change
local matchRemote = Network.getRemote("MatchStateChanged")
matchRemote.OnClientEvent:Connect(function(payload: any)
	if not payload then
		return
	end

	local state = payload.state :: Types.MatchState
	local score = payload.score :: Types.ScoreState?

	if state == "Warmup" or state == "Serving" or state == "Rally" then
		if score then
			local isP1 = (score.player1Id == localPlayer.UserId)
			local side: Types.CourtSide = if isP1 then "Player1" else "Player2"
			TennisCharacter.setCourtSide(side)
			TennisCameraController.enable(side)
		end
	elseif state == "MatchEnded" or state == "Waiting" then
		TennisCameraController.disable()
	end
end)

print("[Roblox Tennis] Client initialized successfully!")

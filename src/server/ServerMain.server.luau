--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Server = ServerScriptService:WaitForChild("Server")
local MatchService = require(Server:WaitForChild("MatchService"))
local CourtManager = require(Server:WaitForChild("CourtManager"))

print("[Roblox Tennis] Initializing server systems...")

MatchService.init()

print("[Roblox Tennis] Server ready! Waiting for players to join court...")

-- Support single-player testing in Studio: if only 1 player joins, create an automated practice/match opponent
Players.PlayerAdded:Connect(function(player)
	task.wait(2.0)
	local currentPlayers = Players:GetPlayers()
	if #currentPlayers == 1 and MatchService.getState() == "Waiting" then
		print(string.format("[Roblox Tennis] Player %s joined. Ready for match!", player.Name))
	end
end)

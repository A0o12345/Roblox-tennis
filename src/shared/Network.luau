--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTE_FOLDER_NAME = "TennisRemotes"
local REMOTE_EVENT_NAMES = {
	"HitBallRequest",
	"BallStateBroadcast",
	"MatchStateChanged",
	"PointAnnounced",
	"PlayerReady",
}

local Network = {}

local remotesFolder: Folder

if RunService:IsServer() then
	local existingFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if existingFolder and existingFolder:IsA("Folder") then
		remotesFolder = existingFolder
	else
		local newFolder = Instance.new("Folder")
		newFolder.Name = REMOTE_FOLDER_NAME
		newFolder.Parent = ReplicatedStorage
		remotesFolder = newFolder
	end

	for _, name in ipairs(REMOTE_EVENT_NAMES) do
		if not remotesFolder:FindFirstChild(name) then
			local remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = name
			remoteEvent.Parent = remotesFolder
		end
	end
else
	remotesFolder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 15) :: Folder
	if not remotesFolder then
		remotesFolder = (ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME) or Instance.new("Folder")) :: Folder
	end
end

function Network.getRemote(name: string): RemoteEvent
	if RunService:IsServer() then
		local remote = remotesFolder:FindFirstChild(name)
		if remote and remote:IsA("RemoteEvent") then
			return remote
		end
		local newRemote = Instance.new("RemoteEvent")
		newRemote.Name = name
		newRemote.Parent = remotesFolder
		return newRemote
	else
		local remote = remotesFolder:WaitForChild(name, 10)
		if remote and remote:IsA("RemoteEvent") then
			return remote
		end
		error(string.format("RemoteEvent %s not found in %s", name, REMOTE_FOLDER_NAME))
	end
end

function Network.fireServer(name: string, ...: any)
	local remote = Network.getRemote(name)
	remote:FireServer(...)
end

function Network.fireClient(name: string, player: Player, ...: any)
	local remote = Network.getRemote(name)
	remote:FireClient(player, ...)
end

function Network.fireAllClients(name: string, ...: any)
	local remote = Network.getRemote(name)
	remote:FireAllClients(...)
end

return Network

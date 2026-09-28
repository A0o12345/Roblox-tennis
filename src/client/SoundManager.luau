--!strict

local SoundService = game:GetService("SoundService")

local SoundManager = {}

local soundsFolder: Folder

-- Common verified Roblox library audio IDs for sports
local SOUND_IDS = {
	RacketHit = "rbxassetid://9114223177", -- Crisp tennis hit
	BallBounce = "rbxassetid://9114223450", -- Court bounce
	NetHit = "rbxassetid://9114223789", -- Net impact
	CrowdCheer = "rbxassetid://9114224012", -- Applause & cheer
	Whistle = "rbxassetid://9114224255", -- Ref whistle
}

local soundInstances: { [string]: Sound } = {}

function SoundManager.init()
	local existing = SoundService:FindFirstChild("TennisSounds")
	if existing and existing:IsA("Folder") then
		soundsFolder = existing
	else
		soundsFolder = Instance.new("Folder")
		soundsFolder.Name = "TennisSounds"
		soundsFolder.Parent = SoundService
	end

	for name, assetId in pairs(SOUND_IDS) do
		local snd = Instance.new("Sound")
		snd.Name = name
		snd.SoundId = assetId
		snd.Volume = 0.7
		snd.Parent = soundsFolder
		soundInstances[name] = snd
	end
end

function SoundManager.playHitSound(power: number?)
	local snd = soundInstances["RacketHit"]
	if snd then
		local actualPower = power or 0.8
		snd.Volume = math.clamp(0.5 + actualPower * 0.5, 0.4, 1.0)
		snd.PlaybackSpeed = 0.95 + math.random() * 0.15
		snd:Play()
	end
end

function SoundManager.playBounceSound()
	local snd = soundInstances["BallBounce"]
	if snd then
		snd.Volume = 0.6
		snd.PlaybackSpeed = 0.9 + math.random() * 0.2
		snd:Play()
	end
end

function SoundManager.playNetSound()
	local snd = soundInstances["NetHit"]
	if snd then
		snd.Volume = 0.7
		snd:Play()
	end
end

function SoundManager.playCheerSound()
	local snd = soundInstances["CrowdCheer"]
	if snd then
		snd.Volume = 0.8
		snd:Play()
	end
end

function SoundManager.playWhistleSound()
	local snd = soundInstances["Whistle"]
	if snd then
		snd.Volume = 0.75
		snd:Play()
	end
end

return SoundManager

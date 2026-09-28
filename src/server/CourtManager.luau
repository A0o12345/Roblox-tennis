--!strict

local Players = game:GetService("Players")
local CourtBuilder = require(script.Parent:WaitForChild("CourtBuilder"))

type CourtRecord = {
	courtId: string,
	model: Model,
	occupied: boolean,
	player1: Player?,
	player2: Player?,
	spawn1CFrame: CFrame,
	spawn2CFrame: CFrame,
}

local CourtManager = {}

local courts: { [string]: CourtRecord } = {}

function CourtManager.init()
	-- Create primary court if not already created
	if not courts["Court_1"] then
		CourtManager.registerCourt(Vector3.new(0, 0, 0), "Court_1")
	end
end

function CourtManager.registerCourt(centerPosition: Vector3, courtId: string): string
	local model = CourtBuilder.buildCourt(centerPosition, courtId)

	local s1 = model:FindFirstChild("Spawn_Player1") :: BasePart?
	local s2 = model:FindFirstChild("Spawn_Player2") :: BasePart?

	local spawn1CF = if s1 then s1.CFrame else CFrame.new(centerPosition + Vector3.new(0, 3, -38))
	local spawn2CF = if s2
		then s2.CFrame
		else CFrame.new(centerPosition + Vector3.new(0, 3, 38)) * CFrame.Angles(0, math.rad(180), 0)

	courts[courtId] = {
		courtId = courtId,
		model = model,
		occupied = false,
		player1 = nil,
		player2 = nil,
		spawn1CFrame = spawn1CF,
		spawn2CFrame = spawn2CF,
	}

	return courtId
end

function CourtManager.getCourt(courtId: string): Model?
	local record = courts[courtId]
	return if record then record.model else nil
end

function CourtManager.getSpawns(courtId: string): (CFrame, CFrame)
	local record = courts[courtId]
	if record then
		return record.spawn1CFrame, record.spawn2CFrame
	end
	return CFrame.new(0, 3, -38), CFrame.new(0, 3, 38) * CFrame.Angles(0, math.rad(180), 0)
end

function CourtManager.assignPlayersToCourt(p1: Player, p2: Player, targetCourtId: string?): string
	local courtId = targetCourtId or "Court_1"
	local record = courts[courtId]

	if not record then
		CourtManager.registerCourt(Vector3.new(0, 0, 0), courtId)
		record = courts[courtId]
	end

	record.occupied = true
	record.player1 = p1
	record.player2 = p2

	local function teleport(player: Player, cf: CFrame)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = cf
			end
		end
	end

	teleport(p1, record.spawn1CFrame)
	teleport(p2, record.spawn2CFrame)

	return courtId
end

function CourtManager.releaseCourt(courtId: string)
	local record = courts[courtId]
	if record then
		record.occupied = false
		record.player1 = nil
		record.player2 = nil
	end
end

return CourtManager

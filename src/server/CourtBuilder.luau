--!strict

local CourtData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CourtData"))

local CourtBuilder = {}

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

function CourtBuilder.buildCourt(centerPosition: Vector3, courtId: string): Model
	local courtModel = Instance.new("Model")
	courtModel.Name = "TennisCourt_" .. courtId
	courtModel:SetAttribute("CourtId", courtId)

	local groundY = centerPosition.Y + 0.5

	-- 1. Outer green surround
	local surround = createPart(
		"Surround",
		Vector3.new(55, 1, 110),
		CFrame.new(centerPosition.X, groundY - 0.51, centerPosition.Z),
		Color3.fromRGB(45, 120, 75),
		Enum.Material.SmoothPlastic,
		true
	)
	surround.Parent = courtModel

	-- 2. Blue playing surface
	local courtBase = createPart(
		"CourtBase",
		Vector3.new(CourtData.DOUBLES_WIDTH, 1, CourtData.LENGTH),
		CFrame.new(centerPosition.X, groundY - 0.5, centerPosition.Z),
		Color3.fromRGB(56, 118, 191),
		Enum.Material.SmoothPlastic,
		true
	)
	courtBase.Parent = courtModel
	courtModel.PrimaryPart = courtBase

	-- 3. Lines
	local linesFolder = Instance.new("Folder")
	linesFolder.Name = "Lines"
	linesFolder.Parent = courtModel

	local lineY = groundY + 0.05
	local lineColor = Color3.new(1, 1, 1)
	local lineMaterial = Enum.Material.SmoothPlastic

	local function addLine(name: string, size: Vector3, offset: Vector3)
		local line = createPart(
			name,
			size,
			CFrame.new(centerPosition.X + offset.X, lineY, centerPosition.Z + offset.Z),
			lineColor,
			lineMaterial,
			false
		)
		line.Parent = linesFolder
	end

	-- Baselines (Z = -40 and Z = +40)
	addLine("Baseline_P1", Vector3.new(CourtData.DOUBLES_WIDTH, 0.1, 0.3), Vector3.new(0, 0, -CourtData.HALF_LENGTH))
	addLine("Baseline_P2", Vector3.new(CourtData.DOUBLES_WIDTH, 0.1, 0.3), Vector3.new(0, 0, CourtData.HALF_LENGTH))

	-- Doubles Sidelines (X = -19 and X = +19)
	addLine("DoublesSideline_Left", Vector3.new(0.3, 0.1, CourtData.LENGTH), Vector3.new(-CourtData.HALF_DOUBLES_WIDTH, 0, 0))
	addLine("DoublesSideline_Right", Vector3.new(0.3, 0.1, CourtData.LENGTH), Vector3.new(CourtData.HALF_DOUBLES_WIDTH, 0, 0))

	-- Singles Sidelines (X = -15 and X = +15)
	addLine("SinglesSideline_Left", Vector3.new(0.3, 0.1, CourtData.LENGTH), Vector3.new(-CourtData.HALF_SINGLES_WIDTH, 0, 0))
	addLine("SinglesSideline_Right", Vector3.new(0.3, 0.1, CourtData.LENGTH), Vector3.new(CourtData.HALF_SINGLES_WIDTH, 0, 0))

	-- Service Lines (Z = -22 and Z = +22)
	addLine("ServiceLine_P1", Vector3.new(CourtData.SINGLES_WIDTH, 0.1, 0.3), Vector3.new(0, 0, -CourtData.SERVICE_LINE_DIST))
	addLine("ServiceLine_P2", Vector3.new(CourtData.SINGLES_WIDTH, 0.1, 0.3), Vector3.new(0, 0, CourtData.SERVICE_LINE_DIST))

	-- Center Service Line (Z from -22 to +22)
	addLine("CenterServiceLine", Vector3.new(0.3, 0.1, CourtData.SERVICE_LINE_DIST * 2), Vector3.new(0, 0, 0))

	-- Center Marks (Z = -40 and Z = +40, length 1.5)
	addLine("CenterMark_P1", Vector3.new(0.3, 0.1, 1.5), Vector3.new(0, 0, -CourtData.HALF_LENGTH + 0.75))
	addLine("CenterMark_P2", Vector3.new(0.3, 0.1, 1.5), Vector3.new(0, 0, CourtData.HALF_LENGTH - 0.75))

	-- 4. Net
	local netModel = Instance.new("Model")
	netModel.Name = "Net"
	netModel.Parent = courtModel

	local postRadius = 0.5
	local postHeight = CourtData.NET_HEIGHT_POST
	local postX = 16.5

	-- Posts
	local leftPost = createPart(
		"LeftPost",
		Vector3.new(postRadius, postHeight, postRadius),
		CFrame.new(centerPosition.X - postX, groundY + postHeight / 2, centerPosition.Z),
		Color3.fromRGB(60, 60, 60),
		Enum.Material.Metal,
		true
	)
	leftPost.Parent = netModel

	local rightPost = createPart(
		"RightPost",
		Vector3.new(postRadius, postHeight, postRadius),
		CFrame.new(centerPosition.X + postX, groundY + postHeight / 2, centerPosition.Z),
		Color3.fromRGB(60, 60, 60),
		Enum.Material.Metal,
		true
	)
	rightPost.Parent = netModel

	-- Net Mesh Part
	local netHeight = CourtData.NET_HEIGHT_CENTER
	local netMesh = createPart(
		"NetMesh",
		Vector3.new(postX * 2, netHeight, 0.2),
		CFrame.new(centerPosition.X, groundY + netHeight / 2, centerPosition.Z),
		Color3.fromRGB(30, 30, 30),
		Enum.Material.Fabric,
		true,
		0.35
	)
	netMesh.Parent = netModel

	-- Net Cord (top white strip)
	local netCord = createPart(
		"NetCord",
		Vector3.new(postX * 2, 0.15, 0.25),
		CFrame.new(centerPosition.X, groundY + netHeight + 0.075, centerPosition.Z),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic,
		false
	)
	netCord.Parent = netModel

	-- 5. Spawn points
	local spawnP1 = Instance.new("Part")
	spawnP1.Name = "Spawn_Player1"
	spawnP1.Size = Vector3.new(3, 0.2, 3)
	spawnP1.CFrame = CFrame.new(centerPosition.X, groundY + 2.5, centerPosition.Z - 38)
		* CFrame.Angles(0, 0, 0)
	spawnP1.Anchored = true
	spawnP1.CanCollide = false
	spawnP1.Transparency = 1
	spawnP1.Parent = courtModel

	local spawnP2 = Instance.new("Part")
	spawnP2.Name = "Spawn_Player2"
	spawnP2.Size = Vector3.new(3, 0.2, 3)
	spawnP2.CFrame = CFrame.new(centerPosition.X, groundY + 2.5, centerPosition.Z + 38)
		* CFrame.Angles(0, math.rad(180), 0)
	spawnP2.Anchored = true
	spawnP2.CanCollide = false
	spawnP2.Transparency = 1
	spawnP2.Parent = courtModel

	courtModel.Parent = workspace
	return courtModel
end

function CourtBuilder.clearCourt(courtModel: Model)
	courtModel:Destroy()
end

return CourtBuilder

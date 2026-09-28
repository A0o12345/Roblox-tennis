--!strict

local Types = require(script.Parent.Types)

local CourtData = {}

CourtData.LENGTH = 80.0
CourtData.HALF_LENGTH = 40.0
CourtData.SINGLES_WIDTH = 30.0
CourtData.HALF_SINGLES_WIDTH = 15.0
CourtData.DOUBLES_WIDTH = 38.0
CourtData.HALF_DOUBLES_WIDTH = 19.0
CourtData.SERVICE_LINE_DIST = 22.0
CourtData.NET_HEIGHT_CENTER = 3.2
CourtData.NET_HEIGHT_POST = 3.8
CourtData.LINE_TOLERANCE = 0.35

function CourtData.isInsideCourt(point: Vector3, isDoubles: boolean?): boolean
	local halfWidth = if isDoubles then CourtData.HALF_DOUBLES_WIDTH else CourtData.HALF_SINGLES_WIDTH
	local maxX = halfWidth + CourtData.LINE_TOLERANCE
	local maxZ = CourtData.HALF_LENGTH + CourtData.LINE_TOLERANCE

	return math.abs(point.X) <= maxX and math.abs(point.Z) <= maxZ
end

function CourtData.getCourtSide(point: Vector3): Types.CourtSide
	if point.Z < 0 then
		return "Player1"
	else
		return "Player2"
	end
end

function CourtData.isInServiceBox(
	point: Vector3,
	serverSide: Types.CourtSide,
	box: Types.ServingSide
): boolean
	local tol = CourtData.LINE_TOLERANCE

	if serverSide == "Player1" then
		-- Server on Player 1 side (Z < 0), ball lands on Player 2 side (Z in [0, 22])
		local validZ = (point.Z >= -tol) and (point.Z <= CourtData.SERVICE_LINE_DIST + tol)
		if not validZ then
			return false
		end

		if box == "Deuce" then
			-- Diagonal to receiver's right box (X in [-tol, 15 + tol])
			return (point.X >= -tol) and (point.X <= CourtData.HALF_SINGLES_WIDTH + tol)
		else
			-- Diagonal to receiver's left box (X in [-15 - tol, tol])
			return (point.X >= -CourtData.HALF_SINGLES_WIDTH - tol) and (point.X <= tol)
		end
	else
		-- Server on Player 2 side (Z > 0), ball lands on Player 1 side (Z in [-22, 0])
		local validZ = (point.Z >= -CourtData.SERVICE_LINE_DIST - tol) and (point.Z <= tol)
		if not validZ then
			return false
		end

		if box == "Deuce" then
			-- Diagonal to receiver's right box (X in [-15 - tol, tol])
			return (point.X >= -CourtData.HALF_SINGLES_WIDTH - tol) and (point.X <= tol)
		else
			-- Diagonal to receiver's left box (X in [-tol, 15 + tol])
			return (point.X >= -tol) and (point.X <= CourtData.HALF_SINGLES_WIDTH + tol)
		end
	end
end

return CourtData

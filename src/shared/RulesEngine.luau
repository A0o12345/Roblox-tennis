--!strict

local Types = require(script.Parent.Types)

local RulesEngine = {}

function RulesEngine.createInitialScore(p1Id: number, p2Id: number): Types.ScoreState
	return {
		player1Points = 0,
		player2Points = 0,
		player1Games = 0,
		player2Games = 0,
		player1Sets = 0,
		player2Sets = 0,
		isDeuce = false,
		isTiebreak = false,
		serverSide = "Deuce",
		servingPlayerId = p1Id,
		receivingPlayerId = p2Id,
		player1Id = p1Id,
		player2Id = p2Id,
	}
end

function RulesEngine.formatGameScore(
	p1Points: number,
	p2Points: number,
	isTiebreak: boolean?
): (string, string)
	if isTiebreak then
		return tostring(p1Points), tostring(p2Points)
	end

	if p1Points >= 3 and p2Points >= 3 then
		if p1Points == p2Points then
			return "40", "40"
		elseif p1Points == 4 and p2Points == 3 then
			return "AD", "40"
		elseif p2Points == 4 and p1Points == 3 then
			return "40", "AD"
		end
	end

	local pointNames = { [0] = "0", [1] = "15", [2] = "30", [3] = "40" }
	local s1 = pointNames[p1Points] or tostring(p1Points)
	local s2 = pointNames[p2Points] or tostring(p2Points)

	return s1, s2
end

function RulesEngine.awardPoint(
	currentScore: Types.ScoreState,
	winningPlayerId: number
): (Types.ScoreState, boolean, boolean)
	local p1Id = currentScore.player1Id or currentScore.servingPlayerId
	local p2Id = currentScore.player2Id or currentScore.receivingPlayerId
	local isP1 = (winningPlayerId == p1Id)

	local newScore: Types.ScoreState = {
		player1Points = currentScore.player1Points,
		player2Points = currentScore.player2Points,
		player1Games = currentScore.player1Games,
		player2Games = currentScore.player2Games,
		player1Sets = currentScore.player1Sets,
		player2Sets = currentScore.player2Sets,
		isDeuce = currentScore.isDeuce,
		isTiebreak = currentScore.isTiebreak,
		serverSide = currentScore.serverSide,
		servingPlayerId = currentScore.servingPlayerId,
		receivingPlayerId = currentScore.receivingPlayerId,
		player1Id = p1Id,
		player2Id = p2Id,
	}

	local isGameOver = false
	local isMatchOver = false

	if newScore.isTiebreak then
		-- Tiebreak scoring (1, 2, 3...)
		if isP1 then
			newScore.player1Points += 1
		else
			newScore.player2Points += 1
		end

		local totalPoints = newScore.player1Points + newScore.player2Points

		-- Tiebreak win condition: >= 7 points and lead by >= 2
		if newScore.player1Points >= 7 and (newScore.player1Points - newScore.player2Points) >= 2 then
			isGameOver = true
			newScore.player1Games += 1
			newScore.player1Sets += 1
			newScore.player1Games = 0
			newScore.player2Games = 0
			newScore.player1Points = 0
			newScore.player2Points = 0
			newScore.isTiebreak = false
		elseif newScore.player2Points >= 7 and (newScore.player2Points - newScore.player1Points) >= 2 then
			isGameOver = true
			newScore.player2Games += 1
			newScore.player2Sets += 1
			newScore.player1Games = 0
			newScore.player2Games = 0
			newScore.player1Points = 0
			newScore.player2Points = 0
			newScore.isTiebreak = false
		else
			-- Switch server after odd point totals: 1, 3, 5, 7...
			if totalPoints % 2 == 1 then
				local temp = newScore.servingPlayerId
				newScore.servingPlayerId = newScore.receivingPlayerId
				newScore.receivingPlayerId = temp
			end
			newScore.serverSide = if (totalPoints % 2 == 0) then "Deuce" else "Ad"
		end

		if newScore.player1Sets >= 2 or newScore.player2Sets >= 2 then
			isMatchOver = true
		end

		return newScore, isGameOver, isMatchOver
	end

	-- Standard game logic
	if isP1 then
		local p1 = newScore.player1Points
		local p2 = newScore.player2Points

		if p1 <= 2 then
			newScore.player1Points += 1
		elseif p1 == 3 then
			if p2 < 3 then
				isGameOver = true
			elseif p2 == 3 then
				newScore.player1Points = 4
				newScore.isDeuce = false
			elseif p2 == 4 then
				newScore.player2Points = 3
				newScore.isDeuce = true
			end
		elseif p1 == 4 then
			isGameOver = true
		end
	else
		local p1 = newScore.player1Points
		local p2 = newScore.player2Points

		if p2 <= 2 then
			newScore.player2Points += 1
		elseif p2 == 3 then
			if p1 < 3 then
				isGameOver = true
			elseif p1 == 3 then
				newScore.player2Points = 4
				newScore.isDeuce = false
			elseif p1 == 4 then
				newScore.player1Points = 3
				newScore.isDeuce = true
			end
		elseif p2 == 4 then
			isGameOver = true
		end
	end

	newScore.isDeuce = (newScore.player1Points >= 3 and newScore.player2Points >= 3 and newScore.player1Points == newScore.player2Points)

	if not isGameOver then
		newScore.serverSide = if newScore.serverSide == "Deuce" then "Ad" else "Deuce"
	else
		newScore.player1Points = 0
		newScore.player2Points = 0
		newScore.isDeuce = false
		newScore.serverSide = "Deuce"

		-- Switch server after game
		local temp = newScore.servingPlayerId
		newScore.servingPlayerId = newScore.receivingPlayerId
		newScore.receivingPlayerId = temp

		if isP1 then
			newScore.player1Games += 1
		else
			newScore.player2Games += 1
		end

		-- Check set win
		if newScore.player1Games >= 6 and (newScore.player1Games - newScore.player2Games) >= 2 then
			newScore.player1Sets += 1
			newScore.player1Games = 0
			newScore.player2Games = 0
		elseif newScore.player2Games >= 6 and (newScore.player2Games - newScore.player1Games) >= 2 then
			newScore.player2Sets += 1
			newScore.player1Games = 0
			newScore.player2Games = 0
		elseif newScore.player1Games == 6 and newScore.player2Games == 6 then
			newScore.isTiebreak = true
		end

		if newScore.player1Sets >= 2 or newScore.player2Sets >= 2 then
			isMatchOver = true
		end
	end

	return newScore, isGameOver, isMatchOver
end

return RulesEngine

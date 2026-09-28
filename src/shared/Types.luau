--!strict

export type ShotType = "Flat" | "Topspin" | "Slice" | "Lob" | "DropShot" | "Serve"

export type TimingQuality = "Perfect" | "Good" | "Early" | "Late"

export type ServingSide = "Deuce" | "Ad"

export type CourtSide = "Player1" | "Player2"

export type MatchState = "Waiting" | "Warmup" | "Serving" | "Rally" | "PointEnded" | "MatchEnded"

export type PointEndReason = 
    | "Out" 
    | "Net" 
    | "DoubleBounce" 
    | "Ace" 
    | "Winner" 
    | "Fault" 
    | "DoubleFault"

export type ScoreState = {
    player1Points: number,  -- 0, 1 (15), 2 (30), 3 (40), 4 (Ad)
    player2Points: number,
    player1Games: number,
    player2Games: number,
    player1Sets: number,
    player2Sets: number,
    isDeuce: boolean,
    isTiebreak: boolean,
    serverSide: ServingSide,
    servingPlayerId: number,
    receivingPlayerId: number,
    player1Id: number?,
    player2Id: number?,
}

export type BallTrajectory = {
    ballId: string,
    origin: Vector3,
    velocity: Vector3,
    shotType: ShotType,
    startTime: number,       -- время по workspace:GetServerTimeNow()
    hitterUserId: number,
    bounceCount: number,
    courtTarget: Vector3?,
}

export type HitRequestPayload = {
    shotType: ShotType,
    aimDirection: Vector2,   -- (X: смещение влево/вправо [-1, 1], Y: глубина удара [0, 1])
    power: number,           -- сила замаха от 0.5 до 1.0
    timing: TimingQuality,
    clientTimestamp: number,
}

export type MatchStatePayload = {
    courtId: string,
    state: MatchState,
    servingPlayerId: number,
    receivingPlayerId: number,
    servingSide: ServingSide,
    score: ScoreState,
}

export type PointAnnouncePayload = {
    reason: PointEndReason,
    winnerUserId: number,
    newScore: ScoreState,
}

return nil

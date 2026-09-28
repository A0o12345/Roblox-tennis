--!strict

local Types = require(script.Parent.Types)

local TrajectoryMath = {}

TrajectoryMath.GRAVITY = 55.0
TrajectoryMath.BALL_RADIUS = 0.4
TrajectoryMath.COURT_Y = 0.5
TrajectoryMath.RESTITUTION_DEFAULT = 0.72
TrajectoryMath.FRICTION_DEFAULT = 0.82

function TrajectoryMath.calculatePosition(origin: Vector3, velocity: Vector3, t: number): Vector3
	local g = TrajectoryMath.GRAVITY
	local x = origin.X + velocity.X * t
	local y = origin.Y + velocity.Y * t - 0.5 * g * t * t
	local z = origin.Z + velocity.Z * t
	return Vector3.new(x, y, z)
end

function TrajectoryMath.calculateVelocity(initialVelocity: Vector3, t: number): Vector3
	local g = TrajectoryMath.GRAVITY
	return Vector3.new(initialVelocity.X, initialVelocity.Y - g * t, initialVelocity.Z)
end

function TrajectoryMath.calculateTimeToGround(origin: Vector3, velocity: Vector3, groundY: number?): number?
	local g = TrajectoryMath.GRAVITY
	local targetY = groundY or TrajectoryMath.COURT_Y

	local a = 0.5 * g
	local b = -velocity.Y
	local c = targetY - origin.Y

	local discriminant = b * b - 4 * a * c
	if discriminant < 0 then
		return nil
	end

	local sqrtD = math.sqrt(discriminant)
	local t1 = (-b - sqrtD) / (2 * a)
	local t2 = (-b + sqrtD) / (2 * a)

	local epsilon = 0.001
	if t1 > epsilon then
		return t1
	elseif t2 > epsilon then
		return t2
	end

	return nil
end

function TrajectoryMath.calculateBounce(velocityAtImpact: Vector3, shotType: Types.ShotType): Vector3
	local ey: number
	local friction: number

	if shotType == "Topspin" then
		ey = 0.85
		friction = 0.88
	elseif shotType == "Slice" then
		ey = 0.48
		friction = 0.75
	elseif shotType == "DropShot" then
		ey = 0.35
		friction = 0.50
	else
		ey = TrajectoryMath.RESTITUTION_DEFAULT
		friction = TrajectoryMath.FRICTION_DEFAULT
	end

	local newVx = velocityAtImpact.X * friction
	local newVy = math.abs(velocityAtImpact.Y) * ey
	local newVz = velocityAtImpact.Z * friction

	return Vector3.new(newVx, newVy, newVz)
end

function TrajectoryMath.calculateLaunchVelocity(origin: Vector3, target: Vector3, flightTime: number): Vector3
	if flightTime <= 0 then
		return Vector3.zero
	end

	local g = TrajectoryMath.GRAVITY
	local vx = (target.X - origin.X) / flightTime
	local vz = (target.Z - origin.Z) / flightTime
	local vy = (target.Y - origin.Y + 0.5 * g * flightTime * flightTime) / flightTime

	return Vector3.new(vx, vy, vz)
end

function TrajectoryMath.checkNetCollision(
	origin: Vector3,
	velocity: Vector3,
	netZ: number?,
	centerHeight: number?,
	postHeight: number?
): (boolean, number?, Vector3?)
	local actualNetZ = netZ or 0.0
	local actualCenter = centerHeight or 3.2
	local actualPost = postHeight or 3.8

	if math.abs(velocity.Z) < 0.0001 then
		return false, nil, nil
	end

	local tNet = (actualNetZ - origin.Z) / velocity.Z
	if tNet <= 0 then
		return false, nil, nil
	end

	local g = TrajectoryMath.GRAVITY
	local xNet = origin.X + velocity.X * tNet
	local yNet = origin.Y + velocity.Y * tNet - 0.5 * g * tNet * tNet

	local widthRatio = math.clamp(math.abs(xNet) / 16.0, 0, 1)
	local currentNetHeight = actualCenter + (actualPost - actualCenter) * widthRatio

	if yNet <= currentNetHeight then
		return true, tNet, Vector3.new(xNet, yNet, actualNetZ)
	else
		return false, tNet, nil
	end
end

return TrajectoryMath

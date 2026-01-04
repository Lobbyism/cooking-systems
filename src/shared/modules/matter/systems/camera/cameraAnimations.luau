local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local cameraAnimations = require(ReplicatedStorage.shared.modules.constants.cameraAnimations)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local firstRunSystem = true
local function getBindName(cameraId)
	return cameraAnimations.CAMERA_ANIMATION_BIND_PREFIX .. cameraId
end
local function stepLinear(currentAlpha, deltaTime, duration)
	if duration <= 0 then return 1 end
	return math.clamp(currentAlpha + deltaTime / duration, 0, 1)
end
local function stepSpring(value, target, velocity, deltaTime, mass, tension, friction)
	local force = -tension * (value - target)
	local damping = -friction * velocity
	local acceleration = (force + damping) / mass
	velocity += acceleration * deltaTime
	value += velocity * deltaTime
	return value, velocity
end
local function cleanupCameraAnimation(world, cameraId)
	RunService:UnbindFromRenderStep(getBindName(cameraId))
	if not world:contains(cameraId) then return end
	world:remove(cameraId, components.CameraAnimation)
end
return function(world)
	if firstRunSystem then
		firstRunSystem = false
		world:spawn(components.Camera({
			camera = workspace.CurrentCamera
		}))
	end
	for cameraAnimationId, cameraAnimationRecord in world:queryChanged(components.CameraAnimation) do
		if not world:contains(cameraAnimationId) then continue end
		if not cameraAnimationRecord.new then continue end
		local camera = world:get(cameraAnimationId, components.Camera)
		if not camera then continue end
		local alpha, velocity = 0, 0
		local config = cameraAnimationRecord.new.config or {}
		local mass = config.mass or 1
		local tension = config.tension or 170
		local friction = config.friction or 26
		local precision = config.precision or 0.01
		local clamp = config.clamp or false
		RunService:UnbindFromRenderStep(getBindName(cameraAnimationId))
		RunService:BindToRenderStep(getBindName(cameraAnimationId), Enum.RenderPriority.Camera.Value, function(deltaTime)
			if cameraAnimationRecord.new.mode == cameraAnimations.CAMERA_ANIMATION_MOTION_MODE.linear then
				alpha = stepLinear(alpha, deltaTime, cameraAnimationRecord.new.duration)
				camera.camera.CFrame = cameraAnimationRecord.new.startCFrame:Lerp(cameraAnimationRecord.new.targetCFrame, alpha)
				if alpha < 1 then return end
				cleanupCameraAnimation(world, cameraAnimationId)
			elseif cameraAnimationRecord.new.mode == cameraAnimations.CAMERA_ANIMATION_MOTION_MODE.spring then
				alpha, velocity = stepSpring(alpha, 1, velocity, deltaTime, mass, tension, friction)
				alpha = if clamp then math.clamp(alpha, 0, 1) else alpha
				camera.camera.CFrame = cameraAnimationRecord.new.startCFrame:Lerp(cameraAnimationRecord.new.targetCFrame, alpha)
				if math.abs(1 - alpha) < precision and math.abs(velocity) < precision then
					cleanupCameraAnimation(world, cameraAnimationId)
				end
			end
		end)
	end
end
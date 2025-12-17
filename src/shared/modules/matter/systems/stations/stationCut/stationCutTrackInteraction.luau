local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local atoms = require(ReplicatedStorage.shared.modules.atoms)
local cameraAnimations = require(ReplicatedStorage.shared.modules.constants.cameraAnimations)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stations = require(ReplicatedStorage.shared.modules.stations)
return function(world, state)
	for usedById, usedByRecord in world:queryChanged(components.UsedBy) do
		if not world:contains(usedById) then continue end
		if not usedByRecord.new then continue end
		if usedByRecord.old and usedByRecord.old.id == usedByRecord.new.id then continue end
		if not world:contains(state.entityIdMap[tostring(usedByRecord.new.id)]) then continue end
		local player = world:get(state.entityIdMap[tostring(usedByRecord.new.id)], components.Player)
		if not player then continue end
		if player.player ~= Players.LocalPlayer then continue end
		if not stations.isStationEntity(world, usedById) then continue end
		local stationModel = world:get(usedById, components.Model)
		if not stationModel then continue end
		atoms.cuttingStationModel(stationModel.model)
		for cameraId, camera in world:query(components.Camera) do
			camera.camera.CameraType = Enum.CameraType.Scriptable
			world:insert(cameraId, components.CameraAnimation({
				animationId = cameraAnimations.CAMERA_ANIMATION_IDS.STATION_CUT_FOCUS,
				startCFrame = camera.camera.CFrame,
				targetCFrame = stationModel.model:GetPivot() * CFrame.new(0, 3.31097746, -3.27201939, -0.999975741, -0.00256703119, 0.00648307707, 0, 0.929766774, 0.368149251, -0.00697280001, 0.36814031, -0.929744124),
				config = {
					mass = 2.5
				},
				mode = cameraAnimations.CAMERA_ANIMATION_MOTION_MODE.spring
			}))
		end
	end
	for cameraId, cameraAnimationRecord in world:queryChanged(components.CameraAnimation) do
		if cameraAnimationRecord.new or not cameraAnimationRecord.old then continue end
		if cameraAnimationRecord.old.animationId ~= cameraAnimations.CAMERA_ANIMATION_IDS.STATION_CUT_FOCUS then continue end
		for stationCutId, stationCut, stationCutUsedBy in world:query(components.StationCut, components.UsedBy) do
			if not world:contains(state.entityIdMap[tostring(stationCutUsedBy.id)]) then continue end
			local player = world:get(state.entityIdMap[tostring(stationCutUsedBy.id)], components.Player)
			if not player or player.player ~= Players.LocalPlayer then continue end
			world:insert(stationCutId, stationCutUsedBy:patch({ interactionReady = true }))
		end
	end
	for usedById, usedByRecord in world:queryChanged(components.UsedBy) do
		if not usedByRecord.old then continue end
		if usedByRecord.new then
			if usedByRecord.old.id == usedByRecord.new.id then continue end
		end
		if not world:contains(state.entityIdMap[tostring(usedByRecord.old.id)]) then continue end
		local player = world:get(state.entityIdMap[tostring(usedByRecord.old.id)], components.Player)
		if not player then continue end
		if player.player ~= Players.LocalPlayer then continue end
		if not stations.isStationEntity(world, usedById) then continue end
		atoms.cuttingStationModel(nil)
		if usedByRecord.new then
			world:insert(usedById, usedByRecord.new:patch({ interactionReady = false }))
		end
	end
end
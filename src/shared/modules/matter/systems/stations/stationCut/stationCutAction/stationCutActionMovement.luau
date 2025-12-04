local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stationCut = require(ReplicatedStorage.shared.modules.stations.stationCut)
local fakePart = ReplicatedStorage.fakePart
return function(world, state)
	for usedById, usedByRecord in world:queryChanged(components.UsedBy) do
		if not world:contains(usedById) then continue end
		if not usedByRecord.new then continue end
		if not usedByRecord.new.interactionReady then continue end
		if usedByRecord.old and usedByRecord.old.interactionReady then continue end
		if not world:get(usedById, components.StationCut) then continue end
		if not state.entityIdMap[tostring(usedByRecord.new.id)] then continue end
		if not world:contains(state.entityIdMap[tostring(usedByRecord.new.id)]) then continue end
		local player, playerModel = world:get(state.entityIdMap[tostring(usedByRecord.new.id)], components.Player, components.Model)
		if not player or not playerModel or player.player ~= Players.LocalPlayer then continue end
		local humanoid = playerModel.model:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then continue end
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then continue end
		for _, animationTrack in animator:GetPlayingAnimationTracks() do
			animationTrack:Stop()
		end
		local updatedUsedBy = usedByRecord.new:patch({
			fakeKnife = ReplicatedStorage.models.mocks.fakeKnife:Clone(),
			fakeArm = ReplicatedStorage.models.mocks.fakeArm:Clone()
		})
		updatedUsedBy.fakeKnife.Parent = workspace
		updatedUsedBy.fakeArm.Parent = workspace
		world:insert(usedById, updatedUsedBy)
	end
	for usedById, usedByRecord in world:queryChanged(components.UsedBy) do
		if not world:contains(usedById) then continue end
		if not usedByRecord.new or not usedByRecord.old then continue end
		if not usedByRecord.new.interactionReady then continue end
		if not usedByRecord.old.knifeEnteredFromAbove or usedByRecord.new.knifeEnteredFromAbove then continue end
		if not world:get(usedById, components.StationCut) then continue end
		if not state.entityIdMap[tostring(usedByRecord.new.id)] then continue end
		if not world:contains(state.entityIdMap[tostring(usedByRecord.new.id)]) then continue end
		if not usedByRecord.new.chopped then continue end
		world:insert(usedById, usedByRecord.new:patch({
			chopped = false
		}))
	end
	for stationId, station, stationModel, stationUsedBy, stationHasItem in world:query(components.StationCut, components.Model, components.UsedBy, components.HasItem) do
		if not stationUsedBy.interactionReady then continue end
		local usedById = state.entityIdMap[tostring(stationUsedBy.id)]
		if not usedById or not world:contains(usedById) then continue end
		local player, playerModel, hasItem = world:get(usedById, components.Player, components.Model, components.HasItem)
		if not player or not playerModel or not hasItem or player.player ~= Players.LocalPlayer then continue end
		if not world:contains(state.entityIdMap[tostring(hasItem.id)]) then continue end
		if not world:contains(state.entityIdMap[tostring(stationHasItem.id)]) then continue end
		local stationItemModel = world:get(state.entityIdMap[tostring(stationHasItem.id)], components.Model)
		if not stationItemModel then continue end
		local itemModel = world:get(state.entityIdMap[tostring(hasItem.id)], components.Model)
		if not itemModel then continue end
		for _, input, gameProcessedEvent in Matter.useEvent(UserInputService, UserInputService.InputChanged) do
			if gameProcessedEvent then continue end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then continue end
			stationCut.updateKnifeAndArmPosition(world, playerModel, {
				id = stationId,
				model = stationModel,
				itemModel = stationItemModel,
				usedBy = stationUsedBy
			})
		end
	end
	fakePart.Parent = workspace
end
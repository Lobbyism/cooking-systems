local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local RAYCAST_LENGTH = 10
return function(world, state)
	for stationId, station, stationModel, stationUsedBy in world:query(components.StationCut, components.Model, components.UsedBy) do
		if not stationUsedBy.interactionReady then continue end
		local usedById = state.entityIdMap[tostring(stationUsedBy.id)]
		if not usedById or not world:contains(usedById) then continue end
		local player, playerModel = world:get(usedById, components.Player, components.Model)
		if not player or not playerModel or player.player ~= Players.LocalPlayer then continue end
		for _, input, gameProcessedEvent in Matter.useEvent(UserInputService, UserInputService.InputChanged) do
			if gameProcessedEvent then continue end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then continue end
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Include
			for _, itemRegion in stationUsedBy.itemRegions do
				raycastParams:AddToFilter(itemRegion)
			end
			local knifeRaycastResult = workspace:Raycast(
				stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition,
				-Vector3.yAxis * RAYCAST_LENGTH,
				raycastParams
			)
			if stationUsedBy.knifeIsAboveIngredient and not knifeRaycastResult then
				world:insert(stationId, stationUsedBy:patch({ knifeIsAboveIngredient = false }))
			elseif not stationUsedBy.knifeIsAboveIngredient and knifeRaycastResult then
				world:insert(stationId, stationUsedBy:patch({ knifeIsAboveIngredient = true }))
			end
		end
	end
end
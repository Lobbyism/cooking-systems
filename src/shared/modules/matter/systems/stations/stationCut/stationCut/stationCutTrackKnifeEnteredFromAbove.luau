local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stationCut = require(ReplicatedStorage.shared.modules.stations.stationCut)
local RAYCAST_LENGTH = 10
return function(world, state)
	for stationId, station, stationModel, stationUsedBy in world:query(components.StationCut, components.Model, components.UsedBy) do
		if not stationUsedBy.knifeEnteredFromAbove then continue end
		if not stationUsedBy.interactionReady then continue end
		local usedById = state.entityIdMap[tostring(stationUsedBy.id)]
		if not usedById or not world:contains(usedById) then continue end
		local player, playerModel = world:get(usedById, components.Player, components.Model)
		if not player or not playerModel or player.player ~= Players.LocalPlayer then continue end
		if stationUsedBy.cutId ~= stationUsedBy.clientCutId then continue end
		for _, input, gameProcessedEvent in Matter.useEvent(UserInputService, UserInputService.InputChanged) do
			if gameProcessedEvent then continue end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then continue end
			if stationUsedBy.chopped then
				local closestSurfaces = stationCut.computeClosestSurfacesFromKnife({
					model = stationModel,
					usedBy = stationUsedBy
				}, stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition)
				if not closestSurfaces.leftSurfacePosition and not closestSurfaces.rightSurfacePosition then
					world:insert(stationId, stationUsedBy:patch({
						knifeEnteredFromAbove = false,
						chopped = false
					}))
				end
			else
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				for _, itemRegion in stationUsedBy.itemRegions do
					raycastParams:AddToFilter(itemRegion)
				end
				local ingredientTopRaycastResult = workspace:Raycast(
					stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition + Vector3.yAxis * RAYCAST_LENGTH / 2,
					-Vector3.yAxis * RAYCAST_LENGTH,
					raycastParams
				)
				if not ingredientTopRaycastResult then continue end
				if stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition.Y <= ingredientTopRaycastResult.Position.Y then continue end
				world:insert(stationId, stationUsedBy:patch({
					knifeEnteredFromAbove = false
				}))
			end
		end
	end
end
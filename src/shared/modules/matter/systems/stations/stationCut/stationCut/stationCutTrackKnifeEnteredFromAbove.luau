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
				if #stationUsedBy.itemRegions == 1 then
					local stationModelUpVector = stationModel.model:GetPivot().UpVector
					local itemRegion = stationUsedBy.itemRegions[1]
					local itemRegionCFrame, itemRegionSize = itemRegion:GetBoundingBox()
					local itemModelHalfHeight =
						math.abs((itemRegionCFrame.RightVector * itemRegionSize.X / 2):Dot(stationModelUpVector))
						+ math.abs((itemRegionCFrame.UpVector * itemRegionSize.Y / 2):Dot(stationModelUpVector))
						+ math.abs((itemRegionCFrame.LookVector * itemRegionSize.Z / 2):Dot(stationModelUpVector))
					local itemModelHeight = (itemRegionCFrame.Position - stationModel.model:GetPivot().Position):Dot(stationModelUpVector) + itemModelHalfHeight
					local bladeBottomHeight = (stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition - stationModel.model:GetPivot().Position):Dot(stationModelUpVector)
					if bladeBottomHeight <= itemModelHeight then continue end
				elseif closestSurfaces.leftSurfacePosition or closestSurfaces.rightSurfacePosition then
					continue
				end
				world:insert(stationId, stationUsedBy:patch({
					knifeEnteredFromAbove = false,
					chopped = false
				}))
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
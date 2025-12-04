local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local RAYCAST_LENGTH = 10
local function castKnifeRay(stationUsedBy, raycastDirection, raycastParams)
	return workspace:Raycast(
		stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition - raycastDirection * RAYCAST_LENGTH / 2,
		raycastDirection * RAYCAST_LENGTH,
		raycastParams
	)
end
local function isBetweenPlanes(attachmentPosition, upperPlanePosition, lowerPlanePosition)
	return attachmentPosition.Y <= upperPlanePosition.Y and lowerPlanePosition.Y <= attachmentPosition.Y
end
return function(world, state)
	for stationId, station, stationUsedBy, stationHasItem in world:query(components.StationCut, components.UsedBy, components.HasItem) do
		if not stationUsedBy.interactionReady then continue end
		local usedById = state.entityIdMap[tostring(stationUsedBy.id)]
		if not usedById or not world:contains(usedById) then continue end
		local player, playerModel = world:get(usedById, components.Player, components.Model)
		if not player or not playerModel or player.player ~= Players.LocalPlayer then continue end
		if not world:contains(state.entityIdMap[tostring(stationHasItem.id)]) then continue end
		local stationItemModel = world:get(state.entityIdMap[tostring(stationHasItem.id)], components.Model)
		if not stationItemModel then continue end
		for _, input, gameProcessedEvent in Matter.useEvent(UserInputService, UserInputService.InputChanged) do
			if gameProcessedEvent then continue end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then continue end
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Include
			raycastParams:AddToFilter(stationItemModel.model)
			local aboveIngredientRaycastResult, belowIngredientRaycastResult = castKnifeRay(stationUsedBy, -Vector3.yAxis, raycastParams), castKnifeRay(stationUsedBy, Vector3.yAxis, raycastParams)
			local knifeRaycastResult = workspace:Raycast(
				stationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition,
				-Vector3.yAxis * RAYCAST_LENGTH,
				raycastParams
			)
			local updatedStationUsedBy = stationUsedBy
			local prevKnifeWasAboveIngredientLastFrame = updatedStationUsedBy.knifeWasAboveIngredientLastFrame
			if stationUsedBy.knifeWasAboveIngredientLastFrame ~= (knifeRaycastResult ~= nil) then
				updatedStationUsedBy = updatedStationUsedBy:patch({ knifeWasAboveIngredientLastFrame = knifeRaycastResult ~= nil })
			end
			local fakeKnifeBladeTopPosition = updatedStationUsedBy.fakeKnife.Blade.TopAttachment.WorldPosition
			local fakeKnifeBladeBottomPosition = updatedStationUsedBy.fakeKnife.Blade.BottomAttachment.WorldPosition
			if not aboveIngredientRaycastResult or not belowIngredientRaycastResult then
				if stationUsedBy == updatedStationUsedBy and not stationUsedBy.knifeIntersectingIngredient then continue end
				world:insert(stationId, updatedStationUsedBy:patch({ knifeIntersectingIngredient = false }))
				continue
			end
			local knifeIntersectingIngredient = isBetweenPlanes(fakeKnifeBladeBottomPosition, aboveIngredientRaycastResult.Position, belowIngredientRaycastResult.Position) or isBetweenPlanes(fakeKnifeBladeTopPosition, aboveIngredientRaycastResult.Position, belowIngredientRaycastResult.Position)
			if updatedStationUsedBy.knifeIntersectingIngredient ~= knifeIntersectingIngredient then
				updatedStationUsedBy = updatedStationUsedBy:patch({ knifeIntersectingIngredient = knifeIntersectingIngredient })
			end
			if prevKnifeWasAboveIngredientLastFrame and fakeKnifeBladeBottomPosition.Y < aboveIngredientRaycastResult.Position.Y then
				updatedStationUsedBy = updatedStationUsedBy:patch({ knifeEnteredFromAbove = true })
			elseif updatedStationUsedBy.knifeEnteredFromAbove and fakeKnifeBladeBottomPosition.Y >= aboveIngredientRaycastResult.Position.Y then
				updatedStationUsedBy = updatedStationUsedBy:patch({ knifeEnteredFromAbove = false })
			end
			if stationUsedBy == updatedStationUsedBy then continue end
			world:insert(stationId, updatedStationUsedBy)
		end
	end
end
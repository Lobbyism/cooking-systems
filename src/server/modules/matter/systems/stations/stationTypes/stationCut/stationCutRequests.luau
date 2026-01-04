local GeometryService = game:GetService("GeometryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.packages.matter)
local remotePayloads = require(ReplicatedStorage.shared.modules.constants.remotePayloads)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stationCutEvent = ReplicatedStorage.remotes.stationCutEvent
local MIN_ITEM_REGION_THICKNESS = 0.055
local function computeItemRegionThicknessAlongAxis(itemRegion, axis)
	local itemRegionCFrame, itemRegionSize = itemRegion:GetBoundingBox()
	return 2 * (
		math.abs((itemRegionCFrame.RightVector * itemRegionSize.X / 2):Dot(axis))
		+ math.abs((itemRegionCFrame.UpVector * itemRegionSize.Y / 2):Dot(axis))
		+ math.abs((itemRegionCFrame.LookVector * itemRegionSize.Z / 2):Dot(axis))
	)
end
return function(world)
	for _, playerInstance, requestPayload in Matter.useEvent(stationCutEvent, stationCutEvent.OnServerEvent) do
		for stationId, stationCut, stationModel, stationHasItem, stationUsedBy in world:query(components.StationCut, components.Model, components.HasItem, components.UsedBy) do
			if not world:contains(stationUsedBy.id) then continue end
			if not world:contains(stationHasItem.id) then continue end
			local player = world:get(stationUsedBy.id, components.Player)
			if not player then continue end
			if player.player ~= playerInstance then continue end
			local stationItemModel = world:get(stationHasItem.id, components.Model)
			if not stationItemModel then continue end
			if requestPayload.type == remotePayloads.stationCut.cut then
				if typeof(requestPayload.clientCutId) ~= "number" then continue end
				local stationItemModelSize = stationItemModel.model:GetExtentsSize()
				local subtractPlaneSideLength = math.max(stationItemModelSize.X, stationItemModelSize.Y, stationItemModelSize.Z)
				local subtractPlane = Instance.new("Part")
				subtractPlane.Material = Enum.Material.SmoothPlastic
				subtractPlane.Size = Vector3.new(subtractPlaneSideLength, .01, subtractPlaneSideLength)
				subtractPlane.Transparency = .75
				subtractPlane.CFrame = CFrame.lookAt(
					requestPayload.bottomAttachmentPosition,
					requestPayload.topAttachmentPosition
				) * CFrame.Angles(0, 0, math.pi / 2)
				subtractPlane.Position = requestPayload.topAttachmentPosition:Lerp(requestPayload.bottomAttachmentPosition, .5)
				subtractPlane.Anchored = true
				subtractPlane.CanCollide = false
				subtractPlane:Destroy()
				local stationRightVector = stationModel.model:GetPivot().RightVector
				task.spawn(function()
					if not stationUsedBy.itemRegions then return end
					local _, referenceItemRegion = next(stationUsedBy.itemRegions)
					if not referenceItemRegion then return end
					local itemRegionsToAdd, itemRegionsToRemove = {}, {}
					for _, itemRegion in stationUsedBy.itemRegions do
						local itemRegionBaseParts = itemRegion:QueryDescendants("BasePart")
						if not itemRegionBaseParts or #itemRegionBaseParts > 1 then continue end
						local itemRegionBasePart = itemRegionBaseParts[1]
						if not itemRegionBasePart then continue end
						local itemRegionBasePartSideThickness = computeItemRegionThicknessAlongAxis(itemRegion, stationRightVector)
						if itemRegionBasePartSideThickness < MIN_ITEM_REGION_THICKNESS then continue end
						local success, addedItemRegionBaseParts = pcall(function()
							return GeometryService:SubtractAsync(itemRegionBasePart, {subtractPlane}, {
								CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
								RenderFidelity = Enum.RenderFidelity.Automatic,
								SplitApart = true
							})
						end)
						if not success then continue end
						local acceptCut = true
						for _, addedItemRegionBasePart in addedItemRegionBaseParts do
							local tempItemRegion = Instance.new("Model")
							local tempItemRegionBasePart = addedItemRegionBasePart:Clone()
							tempItemRegionBasePart.CFrame = itemRegionBasePart.CFrame
							tempItemRegionBasePart.Parent = tempItemRegion
							local tempItemRegionSideThickness = computeItemRegionThicknessAlongAxis(tempItemRegion, stationRightVector)
							tempItemRegion:Destroy()
							if tempItemRegionSideThickness < MIN_ITEM_REGION_THICKNESS then
								acceptCut = false
							end
						end
						if not acceptCut then
							for _, addedItemRegionBasePart in addedItemRegionBaseParts do
								addedItemRegionBasePart:Destroy()
							end
							continue
						end
						for _, addedItemRegionBasePart in addedItemRegionBaseParts do
							local addedItemRegion = Instance.new("Model")
							addedItemRegion.Parent = itemRegion.Parent
							addedItemRegionBasePart.CFrame = itemRegionBasePart.CFrame
							addedItemRegionBasePart.UsePartColor = true
							addedItemRegionBasePart.Anchored = true
							addedItemRegionBasePart.Parent = addedItemRegion
							table.insert(itemRegionsToAdd, addedItemRegion)
						end
						table.insert(itemRegionsToRemove, itemRegion)
					end
					local updatedItemRegions = table.clone(stationUsedBy.itemRegions)
					for _, itemRegionToAdd in itemRegionsToAdd do
						table.insert(updatedItemRegions, itemRegionToAdd)
						itemRegionToAdd.Parent = stationItemModel.model
					end
					for _, itemRegionToRemove in itemRegionsToRemove do
						local itemRegionToRemoveIndex = table.find(updatedItemRegions, itemRegionToRemove)
						if not itemRegionToRemoveIndex then continue end
						table.remove(updatedItemRegions, itemRegionToRemoveIndex)
						itemRegionToRemove:Destroy()
					end
					stationUsedBy = world:get(stationId, components.UsedBy)
					world:insert(stationId, stationUsedBy:patch({
						itemRegions = updatedItemRegions
					}))
				end)
				world:insert(stationId, stationUsedBy:patch({
					cutId = requestPayload.clientCutId
				}))
			end
		end
	end
end
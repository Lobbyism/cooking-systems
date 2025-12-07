local GeometryService = game:GetService("GeometryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.packages.matter)
local remotePayloads = require(ReplicatedStorage.shared.modules.constants.remotePayloads)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stationCutEvent = ReplicatedStorage.remotes.stationCutEvent
return function(world)
	for _, playerInstance, requestPayload in Matter.useEvent(stationCutEvent, stationCutEvent.OnServerEvent) do
		for stationId, stationCut, stationHasItem, stationUsedBy in world:query(components.StationCut, components.HasItem, components.UsedBy) do
			if not world:contains(stationUsedBy.id) then continue end
			if not world:contains(stationHasItem.id) then continue end
			local player = world:get(stationUsedBy.id, components.Player)
			if not player then continue end
			if player.player ~= playerInstance then continue end
			local stationItemModel = world:get(stationHasItem.id, components.Model)
			if not stationItemModel then continue end
			if requestPayload.type == remotePayloads.stationCut.cut then
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
				subtractPlane.Parent = workspace
				local stationItemModelParts = stationItemModel.model:QueryDescendants("BasePart")
				if not stationItemModelParts or #stationItemModelParts > 1 then continue end
				local stationItemModelPart = stationItemModelParts[1]
				task.spawn(function()
					local success, addedParts = pcall(function()
						return GeometryService:SubtractAsync(stationItemModelPart, {subtractPlane}, {
							CollisionFidelity = Enum.CollisionFidelity.Default,
							RenderFidelity = Enum.RenderFidelity.Automatic,
							SplitApart = true
						})
					end)
					if not success or not addedParts then return end
					for _, addedPart in addedParts do
						addedPart.CFrame = stationItemModelPart.CFrame
						addedPart.UsePartColor = true
						addedPart.Anchored = true
						addedPart.Parent = stationItemModel.model
					end
					stationItemModelPart:Destroy()
				end)
			end
		end
	end
end
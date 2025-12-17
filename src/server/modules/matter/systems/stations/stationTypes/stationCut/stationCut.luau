local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Matter = require(ReplicatedStorage.packages.matter)
local items = require(ReplicatedStorage.shared.modules.constants.items)
local stations = require(ServerScriptService.server.modules.matter.stations)
local components = require(ReplicatedStorage.shared.modules.matter.components)
return function(world)
	for usedById, usedByRecord in world:queryChanged(components.UsedBy) do
		if not world:contains(usedById) then continue end
		if not world:get(usedById, components.StationCut) then continue end
		if not usedByRecord.new then continue end
		if usedByRecord.old then
			if usedByRecord.old.id == usedByRecord.new.id then continue end
		end
		if not world:get(usedById, components.StationCut) then continue end
		if not world:contains(usedByRecord.new.id) then continue end
		stations.swapItems(world, usedById, usedByRecord.new.id)
		world:insert(usedByRecord.new.id, components.HasItem({
			id = world:spawn(components.Item({ key = items.knife, states = {} }))
		}))
		local stationModel = world:get(usedById, components.Model)
		if not stationModel then continue end
		local playerModel = world:get(usedByRecord.new.id, components.Model)
		if not playerModel then continue end
		local humanoid = playerModel.model:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or not humanoid.RootPart then continue end
		humanoid.RootPart.Anchored = true
		humanoid.RootPart:PivotTo(stationModel.model.PrimaryPart:GetPivot() * CFrame.new(0, 1.75293255, -3.65760612, -0.999990523, 0, 0.00439012097, 0, 1, 0, -0.00439012097, 0, -0.999990523))
	end
	for usedById, usedByRecord in world:queryChanged(components.UsedBy) do
		if not world:contains(usedById) then continue end
		if not world:get(usedById, components.StationCut) then continue end
		if not usedByRecord.old then continue end
		if usedByRecord.new then
			if usedByRecord.old.id == usedByRecord.new.id then continue end
		end
		if not world:contains(usedByRecord.old.id) then continue end
		local playerModel = world:get(usedByRecord.old.id, components.Model)
		if not playerModel then continue end
		local humanoid = playerModel.model:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or not humanoid.RootPart then continue end
		humanoid.RootPart.Anchored = false
		local hasItem = world:remove(usedByRecord.old.id, components.HasItem)
		if not hasItem then continue end
		world:despawn(hasItem.id)
	end
	for stationId, _, stationUsedBy, stationHasItem in world:query(components.StationCut, components.UsedBy, components.HasItem) do
		if stationUsedBy.itemRegions then continue end
		if not world:contains(stationHasItem.id) then continue end
		local stationItemModel = world:get(stationHasItem.id, components.Model)
		if not stationItemModel then continue end
		-- for _, _, stationItemModelParent in Matter.useEvent(stationItemModel.model, stationItemModel.model.AncestryChanged) do
		-- 	print("Oh no!")
		-- 	local stationItemModelRegion = Instance.new("Model")
		-- 	stationItemModelRegion.Parent = stationItemModelParent
		-- 	stationItemModel.model.Parent = stationItemModelRegion
		-- 	world:insert(stationId, stationUsedBy:patch({ itemRegions = {stationItemModelRegion} }))
		-- end
		for _, _, stationItemModelParent in Matter.useEvent(stationItemModel.model, stationItemModel.model.AncestryChanged) do
			local stationItemModelRegion = Instance.new("Model")
			for _, stationItemModelChild in stationItemModel.model:GetChildren() do
				stationItemModelChild.Parent = stationItemModelRegion
			end
			stationItemModelRegion.Parent = stationItemModel.model
			world:insert(stationId, stationUsedBy:patch({ itemRegions = {stationItemModelRegion} }))
		end
	end
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
local items = require(ReplicatedStorage.shared.modules.items)
return function(world)
	for itemId, itemRecord in world:queryChanged(components.Item) do
		if not world:contains(itemId) then continue end
		if not itemRecord.new then continue end
		if world:get(itemId, components.Model) then continue end
		local resolvedItem = items.resolve(world, itemId)
		if not resolvedItem then continue end
		local itemModel = resolvedItem.model:Clone()
		itemModel.Parent = workspace
		world:insert(itemId, components.Model({ model = itemModel }))
	end
	-- local itemBuffer = {}
	-- for itemId, itemRecord in world:queryChanged(components.Item) do
	-- 	if world:contains(itemId) then continue end
	-- 	itemBuffer[tostring(itemId)] = true
	-- end
	-- for modelId, modelRecord in world:queryChanged(components.Model) do
	-- 	if world:contains(modelId) then continue end
	-- 	if not modelRecord.old then continue end
	-- 	if not itemBuffer[tostring(modelId)] then continue end
	-- 	modelRecord.old.model:Destroy()
	-- end
end
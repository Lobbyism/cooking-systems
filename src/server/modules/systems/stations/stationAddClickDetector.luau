local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.components)
local stations = require(ReplicatedStorage.shared.modules.stations)
return function(world)
	for modelId, modelRecord in world:queryChanged(components.Model) do
		if not world:contains(modelId) then continue end
		if modelRecord.old or not modelRecord.new then continue end
		if not stations.isStationEntity(world, modelId) then continue end
		local interactionClickDetector = Instance.new("ClickDetector")
		interactionClickDetector.Parent = modelRecord.new.model
	end
end
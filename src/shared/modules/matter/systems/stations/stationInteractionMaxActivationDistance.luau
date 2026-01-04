local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stations = require(ReplicatedStorage.shared.modules.stations)
return function(world)
	for modelId, model in world:query(components.Model) do
		if not stations.isStationEntity(world, modelId) then continue end
		local interactionClickDetector = model.model:FindFirstChild("ClickDetector")
		if not interactionClickDetector then continue end
		interactionClickDetector.MaxActivationDistance = if stations.isWithinInteractionRange(model.model, Players.LocalPlayer) then math.huge else 0
	end
end
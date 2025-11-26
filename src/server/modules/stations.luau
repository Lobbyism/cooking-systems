local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.components)
local station = {}
function station.loadStations(world, instance)
	for _, instanceChild in instance:GetChildren() do
		if not instanceChild:IsA("Model") then continue end
		local stationId
		if instanceChild.Name == "StationCut" then
			stationId = world:spawn(components.StationCut())
		elseif instanceChild.Name == "StationStorage" then
			stationId = world:spawn(components.StationStorage())
		end
		if not stationId then continue end
		world:insert(stationId, components.Model({ model = instanceChild }))
	end
end
return station
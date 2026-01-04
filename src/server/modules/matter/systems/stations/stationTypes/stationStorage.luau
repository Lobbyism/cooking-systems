local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local stations = require(ServerScriptService.server.modules.matter.stations)
local components = require(ReplicatedStorage.shared.modules.matter.components)
return function(world)
	for stationId, _, stationUsedBy in world:query(components.StationStorage, components.UsedBy) do
		world:remove(stationId, components.UsedBy)
		stations.swapItems(world, stationId, stationUsedBy.id)
	end
end
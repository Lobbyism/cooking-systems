local ReplicatedStorage = game:GetService("ReplicatedStorage")
local stationConstants = require(ReplicatedStorage.shared.modules.constants.stations)
local stations = {}
function stations.isStationEntity(world, id)
	return next({world:get(id, table.unpack(stationConstants.STATION_COMPONENTS))}) ~= nil
end
function stations.getStation(world, id)
	return next({world:get(id, table.unpack(stationConstants.STATION_COMPONENTS))})
end
function stations.getStationComponent(world, id)
	for _, stationComponent in stationConstants.STATION_COMPONENTS do
		if world:get(id, stationComponent) then return stationComponent end
	end
	return nil
end
function stations.isWithinInteractionRange(stationPVInstance, player)
	if not player.Character then return false end
	return (stationPVInstance:GetPivot().Position - player.Character:GetPivot().Position).Magnitude < stationConstants.STATION_INTERACTION_RANGE
end
return stations
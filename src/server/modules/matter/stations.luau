local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
local itemStates = require(ReplicatedStorage.shared.modules.constants.itemStates)
local items = require(ReplicatedStorage.shared.modules.items)
local stations = require(ReplicatedStorage.shared.modules.stations)
local station = {}
local stationUsageRules = {
	[components.StationCut] = function(world, stationId, playerId)
		local hasItem = world:get(playerId, components.HasItem)
		if not hasItem then return false end
		local resolvedItem = items.resolve(world, hasItem.id)
		if not resolvedItem.children then return false end
		return resolvedItem.children[itemStates.states.cut] ~= nil
	end
}
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
function station.canPlayerUseStation(world, stationId, playerId)
	local stationComponent = stations.getStationComponent(world, stationId)
	if not stationComponent then return false end
	if not stationUsageRules[stationComponent] then return true end
	return stationUsageRules[stationComponent](world, stationId, playerId)
end
function station.swapItems(world, entity1, entity2)
	if not world:contains(entity1) or not world:contains(entity2) then return end
	local hasItem1, hasItem2 = world:remove(entity1, components.HasItem), world:remove(entity2, components.HasItem)
	local tempHasItem = hasItem1
	hasItem1 = hasItem2
	hasItem2 = tempHasItem
	if hasItem1 then
		world:insert(entity1, hasItem1)
	end
	if hasItem2 then
		world:insert(entity2, hasItem2)
	end
end
return station
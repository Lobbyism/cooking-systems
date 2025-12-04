local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stationConstants = require(ReplicatedStorage.shared.modules.constants.stations)
local stations = require(ReplicatedStorage.shared.modules.stations)
local serverStations = require(ServerScriptService.server.modules.matter.stations)
local stationEvent = ReplicatedStorage.remotes.stationEvent
local playerLastRequestTimes = {}
local requestThrottle = .05
return function(world)
	for player, playerLastRequestTime in playerLastRequestTimes do
		if playerLastRequestTime > workspace:GetServerTimeNow() then continue end
		playerLastRequestTimes[player] = nil
	end
	for _, requestPlayer, requestPayload in Matter.useEvent(stationEvent, stationEvent.OnServerEvent) do
		if playerLastRequestTimes[requestPlayer] then continue end
		playerLastRequestTimes[requestPlayer] = workspace:GetServerTimeNow() + requestThrottle
		if typeof(requestPayload) ~= "table" then continue end
		if typeof(requestPayload.stationModel) ~= "Instance" then continue end
		if not requestPayload.stationModel:IsA("Model") then continue end
		local requestPlayerUsesSomeStation = false
		local requestPlayerId
		for playerId, player in world:query(components.Player) do
			if player.player ~= requestPlayer then continue end
			requestPlayerId = playerId
		end
		if not requestPlayerId then continue end
		for _, stationComponent in stationConstants.STATION_COMPONENTS do
			for _, _, stationUsedBy in world:query(stationComponent, components.UsedBy) do
				if stationUsedBy.id ~= requestPlayerId then continue end
				requestPlayerUsesSomeStation = true
			end
		end
		if requestPlayerUsesSomeStation then continue end
		if not stations.isWithinInteractionRange(requestPayload.stationModel, requestPlayer) then continue end
		for _, stationComponent in stationConstants.STATION_COMPONENTS do
			for stationId, _, stationModel in world:query(stationComponent, components.Model) do
				if stationModel.model ~= requestPayload.stationModel then continue end
				if not serverStations.canPlayerUseStation(world, stationId, requestPlayerId) then continue end
				world:insert(stationId, components.UsedBy({ id = requestPlayerId }))
			end
		end
	end
end
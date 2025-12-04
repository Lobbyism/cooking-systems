local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Matter = require(ReplicatedStorage.packages.matter)
local replication = require(ServerScriptService.server.modules.matter.componentReplication)
local remoteEvent = Instance.new("RemoteEvent");
remoteEvent.Name = "matterEvent";
remoteEvent.Parent = ReplicatedStorage.remotes;
return {
	priority = math.huge,
	system = function(world)
		for _, player in Matter.useEvent(Players, "PlayerAdded") do
			local payload = {}
			for entityId, entityData in world do
				local entityPayload = {}
				payload[tostring(entityId)] = entityPayload
				for component, componentData in entityData do
					local componentReplication = replication.getFor(component)
					if not componentReplication then continue end
					if not componentReplication.isPlayerSubscribed(world, entityId, player) then continue end
					entityPayload[tostring(component)] = {
						data = componentReplication.mapComponent(world, componentData)
					}
				end
			end
			remoteEvent:FireClient(player, payload)
		end
		local players = Players:GetPlayers()
		local playerBuffers = {}
		for _, player in players do
			playerBuffers[player] = {}
		end
		for component, componentReplication in replication.getAll() do
			for entityId, record in world:queryChanged(component) do
				for _, player in players do
					if not componentReplication.isPlayerSubscribed(world, entityId, player, record.new) then continue end
					local key, name = tostring(entityId), tostring(component)
					if playerBuffers[player][key] == nil then
						playerBuffers[player][key] = {}
					end
					if world:contains(entityId) then
						playerBuffers[player][key][name] = {
							data = componentReplication.mapComponent(world, record.new)
						}
					end
				end
			end
		end
		for _, player in players do
			local changes = playerBuffers[player]
			if next(changes) then
				remoteEvent:FireClient(player, changes)
			end
		end
	end
}
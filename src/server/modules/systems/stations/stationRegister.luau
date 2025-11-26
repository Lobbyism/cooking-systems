local ServerScriptService = game:GetService("ServerScriptService")
local stations = require(ServerScriptService.server.modules.stations)
local firstRunSystem = true
return function(world)
	if firstRunSystem then
		firstRunSystem = false
		stations.loadStations(world, workspace)
	end
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.components)
return {
	STATION_COMPONENTS = {
		components.StationCut
	},
	STATION_HOVER_RAYCAST_LENGTH = 500,
	STATION_INTERACTION_RANGE = 15
}
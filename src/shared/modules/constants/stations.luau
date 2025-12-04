local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
return {
	STATION_SURFACES = {
		[components.StationCut] = CFrame.new(0, 2, -0.75, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		[components.StationStorage] = CFrame.new(0, 1.75, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	},
	STATION_COMPONENTS = {
		components.StationCut,
		components.StationStorage
	},
	STATION_HOVER_RAYCAST_LENGTH = 500,
	STATION_INTERACTION_RANGE = 15
}
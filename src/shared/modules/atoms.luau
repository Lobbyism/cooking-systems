local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.packages.charm)
local atom = Charm.atom
return {
	cuttingStationModel = atom(nil),
	cuttingIngredientModel = atom(nil)
}
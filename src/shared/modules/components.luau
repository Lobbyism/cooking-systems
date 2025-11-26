local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.packages.matter)
local COMPONENT_NAMES = {
	"Player",
	"Model",
	"StationCut",
	"UsedBy"
}
local components = {}
for _, componentName in COMPONENT_NAMES do
	components[componentName] = Matter.component(componentName)
end
return components
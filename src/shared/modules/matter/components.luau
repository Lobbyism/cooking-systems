local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.packages.matter)
local COMPONENT_NAMES = {
	"Player",
	"Model",
	"StationCut",
	"StationStorage",
	"UsedBy",
	"Item",
	"HasItem",
	"Camera",
	"CameraAnimation"
}
local components = {}
for _, componentName in COMPONENT_NAMES do
	components[componentName] = Matter.component(componentName)
end
return components
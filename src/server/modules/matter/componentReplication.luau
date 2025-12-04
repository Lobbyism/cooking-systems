local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
local componentReplicationMap = {
	components = {
		[components.Player] = {},
		[components.Model] = {},
		[components.StationCut] = {},
		[components.StationStorage] = {},
		[components.UsedBy] = {},
		[components.HasItem] = {}
	}
}
for component, componentReplication in componentReplicationMap.components do
	if not componentReplication.mapComponent then
		componentReplication.mapComponent = function(_, component) return component end
	end
	if not componentReplication.isPlayerSubscribed then
		componentReplication.isPlayerSubscribed = function() return true end
	end
end
local componentReplication = {}
function componentReplication.getFor(component)
	return componentReplicationMap.components[component]
end
function componentReplication.getAll()
	return componentReplicationMap.components
end
return componentReplication
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.packages.react)
return function(props)
	local mostRecent = props.children
	for providerIndex = #props.providers, 1, -1 do
		local providerElement = props.providers[providerIndex]
		mostRecent = React.cloneElement(providerElement, nil, mostRecent)
	end
	return mostRecent
end
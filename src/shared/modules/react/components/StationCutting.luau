local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.packages.react)
local e = React.createElement
local function StationCutting()
	return e("Frame")
end
return StationCutting
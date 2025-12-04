local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.packages.react)
local function useCamera()
	local camera, setCamera = React.useState(workspace.CurrentCamera)
	React.useEffect(function()
		local connection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			if not workspace.CurrentCamera then return end
			setCamera(workspace.CurrentCamera)
		end)
		return function()
			connection:Disconnect()
		end
	end)
	return camera
end
return useCamera
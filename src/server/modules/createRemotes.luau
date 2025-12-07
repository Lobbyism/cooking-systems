local ReplicatedStorage = game:GetService("ReplicatedStorage")
local REMOTE_EVENT_NAMES = {"station", "stationCut"}
local REMOTE_FUNCTION_NAMES = {}
local hasCreatedRemotes = false
return function()
	if hasCreatedRemotes then return end
	hasCreatedRemotes = true
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "remotes"
	for _, remoteEventName in REMOTE_EVENT_NAMES do
		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = remoteEventName .. "Event"
		remoteEvent.Parent = remotesFolder
	end
	for _, remoteFunctionName in REMOTE_FUNCTION_NAMES do
		local remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = remoteFunctionName .. "Function"
		remoteFunction.Parent = remotesFolder
	end
	remotesFolder.Parent = ReplicatedStorage
end
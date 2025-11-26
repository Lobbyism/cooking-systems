local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.components)
local stationConstants = require(ReplicatedStorage.shared.modules.constants.stations)
local stations = require(ReplicatedStorage.shared.modules.stations)
local stationEvent = ReplicatedStorage.remotes.stationEvent
return function(world)
	local stationModels = {}
	for _, stationComponent in stationConstants.STATION_COMPONENTS do
		for _, _, stationModel in world:query(stationComponent, components.Model) do
			table.insert(stationModels, stationModel.model)
		end
	end
	local viewportRay
	if UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
		viewportRay = workspace.CurrentCamera:ViewportPointToRay(
			UserInputService:GetMouseLocation().X,
			UserInputService:GetMouseLocation().Y
		)
	end
	if not viewportRay then return end
	local raycastParams = RaycastParams.new()
	raycastParams:AddToFilter(stationModels)
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local raycastResult = workspace:Raycast(
		viewportRay.Origin,
		viewportRay.Direction.Unit * stationConstants.STATION_HOVER_RAYCAST_LENGTH,
		raycastParams
	)
	local hoveredStationModel
	if raycastResult then
		for _, stationModel in stationModels do
			if not raycastResult.Instance:IsDescendantOf(stationModel) then continue end
			if not stations.isWithinInteractionRange(stationModel, Players.LocalPlayer) then continue end
			hoveredStationModel = stationModel
		end
	end
	if not hoveredStationModel then return end
	for _, input, gameProcessedEvent in Matter.useEvent(UserInputService, UserInputService.InputBegan) do
		if gameProcessedEvent then continue end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then continue end
		stationEvent:FireServer({ stationModel = hoveredStationModel })
	end
end
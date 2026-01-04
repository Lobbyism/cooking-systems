local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
local stationConstants = require(ReplicatedStorage.shared.modules.constants.stations)
local items = require(ReplicatedStorage.shared.modules.items)
local stations = require(ReplicatedStorage.shared.modules.stations)
local itemHoldAnimationTrackName = "HoldItem"
return function(world)
	local hasItemIdBuffer = {}
	for modelId, modelRecord in world:queryChanged(components.Model) do
		if not world:contains(modelId) then continue end
		if not modelRecord.new then continue end
		if not world:get(modelId, components.Item) then continue end
		for hasItemId, hasItem in world:query(components.HasItem) do
			if hasItem.id ~= modelId then continue end
			hasItemIdBuffer[tostring(hasItemId)] = modelId
		end
	end
	for hasItemId, hasItemRecord in world:queryChanged(components.HasItem) do
		if not world:contains(hasItemId) then continue end
		if not hasItemRecord.new then continue end
		hasItemIdBuffer[tostring(hasItemId)] = hasItemRecord.new.id
	end
	for hasItemId, itemId in hasItemIdBuffer do
		if not world:contains(tonumber(hasItemId)) then continue end
		if not world:contains(itemId) then continue end
		local item, itemModel = world:get(itemId, components.Item, components.Model)
		if not item or not itemModel then continue end
		local resolvedItem = items.resolve(world, itemId)
		local itemHolder, itemGripOffset
		local stationModelItemHolder
		local player = world:get(tonumber(hasItemId), components.Player)
		if player then
			if not player.player.Character then continue end
			local rightArm = player.player.Character:FindFirstChild("Right Arm")
			if not rightArm then continue end
			itemHolder, itemGripOffset = rightArm, resolvedItem.grip.offsets.rightHand
			if resolvedItem.grip.animationId then
				local humanoid = player.player.Character:FindFirstChildWhichIsA("Humanoid")
				if not humanoid then continue end
				local animator = humanoid:FindFirstChildWhichIsA("Animator")
				if not animator then continue end
				local animation = Instance.new("Animation")
				animation.AnimationId = resolvedItem.grip.animationId
				local animationTrack = animator:LoadAnimation(animation)
				animationTrack.Name = itemHoldAnimationTrackName
				animationTrack:Play()
			end
		else
			stationModelItemHolder = world:get(tonumber(hasItemId), components.Model)
			if not stationModelItemHolder or not stationModelItemHolder.model.PrimaryPart then continue end
			itemHolder = stationModelItemHolder.model.PrimaryPart
			local stationComponent = stations.getStationComponent(world, tonumber(hasItemId))
			if not stationComponent then continue end
			itemGripOffset = (stationConstants.STATION_SURFACES[stationComponent] or CFrame.new()) * resolvedItem.grip.offsets.station
		end
		if not itemHolder or not itemGripOffset then continue end
		local prevItemHandle = itemModel.model.PrimaryPart:FindFirstChild("Handle")
		if prevItemHandle then
			prevItemHandle:Destroy()
		end
		local itemHandle = Instance.new("Weld")
		itemHandle.Name = "Handle"
		itemHandle.Part0, itemHandle.Part1, itemHandle.C0 = itemHolder, itemModel.model.PrimaryPart, itemGripOffset
		itemHandle.Parent = itemHandle.Part1
		itemModel.model.Parent = if player then workspace else stationModelItemHolder.model
	end
	for hasItemId, hasItemRecord in world:queryChanged(components.HasItem) do
		if not world:contains(hasItemId) then continue end
		if not hasItemRecord.old then continue end
		if hasItemRecord.new then
			local itemResolved = items.resolve(world, hasItemRecord.new.id)
			if not itemResolved then continue end
			local previousItemResolved = if world:contains(hasItemRecord.old.id) then items.resolve(world, hasItemRecord.old.id) else nil
			if previousItemResolved and previousItemResolved.grip.animationId == itemResolved.grip.animationId then continue end
		end
		local player = world:get(hasItemId, components.Player)
		if not player then continue end
		if not player.player.Character then continue end
		local humanoid = player.player.Character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then continue end
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then continue end
		for _, playingAnimationTrack in animator:GetPlayingAnimationTracks() do
			if playingAnimationTrack.Name == itemHoldAnimationTrackName then playingAnimationTrack:Stop() end
		end
	end
end
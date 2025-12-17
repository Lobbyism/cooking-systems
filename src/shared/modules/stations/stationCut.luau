local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local items = require(ReplicatedStorage.shared.modules.items)
local itemConstants = require(ReplicatedStorage.shared.modules.constants.items)
local remotePayloads = require(ReplicatedStorage.shared.modules.constants.remotePayloads)
local stationCutEvent = ReplicatedStorage.remotes.stationCutEvent
local RAYCAST_DISTANCE = 10
local FAKE_KNIFE_WIDTH = 0.025
local GAP_EPSILON = 0.25
local stationCut = {}
local function applyLateralKnifeConstraint(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
	local function getFurthestDistanceAlongStationLateralVector(distances)
		local furthestDistance
		for _, distance in distances do
			if not distance then continue end
			if not furthestDistance then
				furthestDistance = distance
			else
				furthestDistance = math.max(furthestDistance, distance)
			end
		end
		return furthestDistance
	end
	local function distanceAlongStationLateralVector(stationLateralVector, station, raycastResult)
		if not raycastResult then return nil end
		return (raycastResult.Position - station.model.model:GetPivot().Position):Dot(stationLateralVector)
	end
	local function raycastIngredientLaterally(targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset, raycastParams)
	local function raycastOppositeRays(raycastOrigin, raycastDirection)
		return workspace:Raycast(
				raycastOrigin + raycastDirection * RAYCAST_DISTANCE / 2,
				-raycastDirection * RAYCAST_DISTANCE,
				raycastParams
			), workspace:Raycast(
				raycastOrigin - raycastDirection * RAYCAST_DISTANCE / 2,
				raycastDirection * RAYCAST_DISTANCE,
				raycastParams
			)
		end
		local topLeftRaycastResult, topRightRaycastResult = raycastOppositeRays(
			(targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * topAttachmentOffset).Position,
			targetKnifeCFrame.LookVector
		)
		local bottomLeftRaycastResult, bottomRightRaycastResult = raycastOppositeRays(
			(targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * bottomAttachmentOffset).Position,
			targetKnifeCFrame.LookVector
		)
		return topLeftRaycastResult, bottomLeftRaycastResult, topRightRaycastResult, bottomRightRaycastResult
	end
	local function computeItemModelBounds(station)
		if #station.itemRegions == 0 then return nil, nil end
		local stationPivot = station.model.model:GetPivot()
		local stationRightVector = stationPivot.RightVector
		local globalLeftStationLateral = math.huge
		local globalRightStationLateral = -math.huge
		for _, itemRegion in station.itemRegions do
			local regionCFrame, regionSize = itemRegion:GetBoundingBox()
			local stationToRegionProjection = (regionCFrame.Position - stationPivot.Position):Dot(stationRightVector)
			local regionExtentsToStationProjection =
				math.abs(stationRightVector:Dot(regionCFrame.RightVector)) * (regionSize.X / 2)
				+ math.abs(stationRightVector:Dot(regionCFrame.UpVector)) * (regionSize.Y / 2)
				+ math.abs(stationRightVector:Dot(regionCFrame.LookVector)) * (regionSize.Z / 2)
			local regionLeftStationLateral = stationToRegionProjection - (regionExtentsToStationProjection + FAKE_KNIFE_WIDTH)
			local regionRightStationLateral = stationToRegionProjection + (regionExtentsToStationProjection + FAKE_KNIFE_WIDTH)
			globalLeftStationLateral = math.min(globalLeftStationLateral, regionLeftStationLateral)
			globalRightStationLateral = math.max(globalRightStationLateral, regionRightStationLateral)
		end
		return globalLeftStationLateral, globalRightStationLateral
	end
	local stationPivot = station.model.model:GetPivot()
	local stationLateralVector = stationPivot.RightVector
	local knifeLateralCoordinate = (targetKnifeCFrame.Position - stationPivot.Position):Dot(stationLateralVector)
	for _, itemRegion in station.itemRegions do
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams:AddToFilter(itemRegion)
		local topLeftRaycastResult, bottomLeftRaycastResult, topRightRaycastResult, bottomRightRaycastResult = raycastIngredientLaterally(targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset, raycastParams)
		local distancesLeft = {distanceAlongStationLateralVector(stationLateralVector, station, topLeftRaycastResult), distanceAlongStationLateralVector(stationLateralVector, station, bottomLeftRaycastResult)}
		local distancesRight =  {distanceAlongStationLateralVector(stationLateralVector, station, topRightRaycastResult), distanceAlongStationLateralVector(stationLateralVector, station, bottomRightRaycastResult)}
		local leftmostDistance, rightmostDistance = getFurthestDistanceAlongStationLateralVector(distancesLeft), getFurthestDistanceAlongStationLateralVector(distancesRight)
		if not leftmostDistance or not rightmostDistance then continue end
		local minimumLateralCoordinate, maximumLateralCoordinate = math.min(leftmostDistance, rightmostDistance), math.max(leftmostDistance, rightmostDistance)
		if knifeLateralCoordinate > minimumLateralCoordinate and knifeLateralCoordinate < maximumLateralCoordinate then
			if station.usedBy.knifeIsAboveIngredient and not station.usedBy.knifeEnteredFromAbove then
				world:insert(station.id, station.usedBy:patch({ knifeEnteredFromAbove = true }))
				return targetKnifeCFrame
			end
			local itemLeftBound, itemRightBound = computeItemModelBounds(station)
			if not itemLeftBound or not itemRightBound then return targetKnifeCFrame end
			local snapLateral = if math.abs(knifeLateralCoordinate - itemLeftBound) < math.abs(knifeLateralCoordinate - itemRightBound) then itemLeftBound else itemRightBound
			local stationToKnife = targetKnifeCFrame.Position - stationPivot.Position
			local distanceParallel = stationLateralVector * knifeLateralCoordinate
			local distancePerpendicular = stationToKnife - distanceParallel
			local snappedPosition = stationPivot.Position + stationLateralVector * snapLateral + distancePerpendicular
			return CFrame.new(snappedPosition) * (targetKnifeCFrame - targetKnifeCFrame.Position)
		end
	end
	local closestSurfaces = stationCut.computeClosestSurfacesFromKnife(station, (targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * bottomAttachmentOffset).Position)
	if closestSurfaces.minimumLeftDistance and closestSurfaces.minimumRightDistance and (closestSurfaces.minimumLeftDistance + closestSurfaces.minimumRightDistance) < GAP_EPSILON then
		local itemLeftBound, itemRightBound = computeItemModelBounds(station)
		if not itemLeftBound or not itemRightBound then
			return targetKnifeCFrame
		end
		local snapLateral = if math.abs(knifeLateralCoordinate - itemLeftBound) < math.abs(knifeLateralCoordinate - itemRightBound) then itemLeftBound else itemRightBound
		local stationToKnife = targetKnifeCFrame.Position - stationPivot.Position
		local distanceParallel = stationLateralVector * knifeLateralCoordinate
		local distancePerpendicular = stationToKnife - distanceParallel
		local snappedPosition = stationPivot.Position + stationLateralVector * snapLateral + distancePerpendicular
		return CFrame.new(snappedPosition) * (targetKnifeCFrame - targetKnifeCFrame.Position)
	end
	return targetKnifeCFrame
end
local function applyVerticalKnifeConstraint(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local stationCutBoard = station.model.model:FindFirstChild("Board")
	if not stationCutBoard then return targetKnifeCFrame end
	raycastParams:AddToFilter(stationCutBoard)
	local raycastResult = workspace:Raycast(
		targetKnifeCFrame.Position + 0.5 * Vector3.yAxis * RAYCAST_DISTANCE,
		-Vector3.yAxis * RAYCAST_DISTANCE,
		raycastParams
	)
	if not raycastResult then return targetKnifeCFrame end
	local boardCFrame = stationCutBoard:GetPivot()
	local boardUp = boardCFrame.UpVector
	local boardPoint = raycastResult.Position
	local bottomAttachmentPosition = (targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * bottomAttachmentOffset).Position
	local bottomAttachmentPositionToBoard = bottomAttachmentPosition - boardPoint
	local bottomAttachmentHeightRelativeToBoard = bottomAttachmentPositionToBoard:Dot(boardUp)
	if bottomAttachmentHeightRelativeToBoard < 0 then
		local correctionOffset = -bottomAttachmentHeightRelativeToBoard * boardUp
		local correctedPosition = targetKnifeCFrame.Position + correctionOffset
		if not station.usedBy.knifeLockedXOnBoard then
			station.usedBy = station.usedBy:patch({
				knifeLockedXOnBoard = correctedPosition.X
			})
			world:insert(station.id, station.usedBy)
		end
		correctedPosition = Vector3.new(
			station.usedBy.knifeLockedXOnBoard,
			correctedPosition.Y,
			correctedPosition.Z
		)
		targetKnifeCFrame = CFrame.new(correctedPosition) * (targetKnifeCFrame - targetKnifeCFrame.Position)
		if not station.usedBy.chopped then
			station.usedBy = station.usedBy:patch({
				chopped = true,
				clientCutId = (if station.usedBy.clientCutId then station.usedBy.clientCutId else 0) + 1
			})
			stationCutEvent:FireServer({
				type = remotePayloads.stationCut.cut,
				topAttachmentPosition = (targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * topAttachmentOffset).Position,
				bottomAttachmentPosition = (targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * bottomAttachmentOffset).Position,
				clientCutId = station.usedBy.clientCutId
			})
			world:insert(station.id, station.usedBy)
		end
	elseif station.usedBy.knifeLockedXOnBoard then
		world:insert(station.id, station.usedBy:patch({
			knifeLockedXOnBoard = Matter.None
		}))
	end
	return targetKnifeCFrame
end
local function constraintTargetKnifeCFrame(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
	local stationId, stationUsedBy = station.id, station.usedBy
	local _, fakeKnife = stationUsedBy.fakeArm, stationUsedBy.fakeKnife
	if stationUsedBy.knifeEnteredFromAbove then
		if not stationUsedBy.knifeLockedZ then
			stationUsedBy = stationUsedBy:patch({
				knifeLockedZ = fakeKnife:GetPivot().Position.Z
			})
			world:insert(stationId, stationUsedBy)
		end
		return applyVerticalKnifeConstraint(world, station, CFrame.new(
			targetKnifeCFrame.Position.X,
			targetKnifeCFrame.Position.Y,
			stationUsedBy.knifeLockedZ
		), topAttachmentOffset, bottomAttachmentOffset)
	else
		if stationUsedBy.knifeLockedZ then
			world:insert(stationId, stationUsedBy:patch({
				knifeLockedZ = Matter.None
			}))
		end
	end
	return applyLateralKnifeConstraint(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
end
function stationCut.updateKnifeAndArmPosition(world, playerModel, station)
	local mouseLocation = UserInputService:GetMouseLocation()
	local mouseViewportRay = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local characterTorso = playerModel.model:FindFirstChild("Torso")
	local characterShoulder = characterTorso:FindFirstChild("Right Shoulder")
	if not characterTorso or not characterShoulder then return end
	local denominator = mouseViewportRay.Direction:Dot(workspace.CurrentCamera.CFrame.LookVector)
	if math.abs(denominator) < 1e-4 then return end
	local t = 1.5 / denominator
	if t < 0 then return end
	local topAttachmentOffset, bottomAttachmentOffset
	local knifeModel = station.usedBy.fakeKnife
	for _, attachment in knifeModel:QueryDescendants("Attachment") do
		if attachment.Parent.Name ~= "Blade" then continue end
		if attachment.Name == "TopAttachment" then
			topAttachmentOffset = knifeModel:GetPivot():ToObjectSpace(attachment.WorldCFrame)
		elseif attachment.Name == "BottomAttachment" then
			bottomAttachmentOffset = knifeModel:GetPivot():ToObjectSpace(attachment.WorldCFrame)
		end
	end
	if not topAttachmentOffset or not bottomAttachmentOffset then return end
	local knifeTargetCFrame = constraintTargetKnifeCFrame(world, station, CFrame.new(mouseViewportRay.Origin + mouseViewportRay.Direction * t), topAttachmentOffset, bottomAttachmentOffset)
	local stationUsedBy = station.usedBy
	local fakeArm, fakeKnife = stationUsedBy.fakeArm, stationUsedBy.fakeKnife
	fakeKnife:PivotTo(knifeTargetCFrame * CFrame.Angles(0, math.pi / 2, 0))
	local shoulderPositionFromTorso = (characterShoulder.Part0.CFrame * CFrame.new(3, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)).Position
	local armToKnifeOffset = items.tree.Root.children[itemConstants.knife].grip.offsets.rightHand:Inverse()
	fakeArm.CFrame = CFrame.lookAt(shoulderPositionFromTorso, (fakeKnife:GetPivot() * armToKnifeOffset).Position) * CFrame.Angles(math.pi / 2, 0, 0)
	fakeArm:PivotTo(CFrame.new(fakeKnife:GetPivot().Position) * CFrame.fromMatrix(
		Vector3.zero,
		fakeArm.CFrame.RightVector,
		fakeArm.CFrame.UpVector,
		fakeArm.CFrame.LookVector
	) * CFrame.new(0, 1, 0))
end
local function raycastIngredientLeftAndRight(raycastOrigin, stationRightVector, raycastParams)
	local function raycastIngredientSurfaceRay(raycastDirection)
		return workspace:Raycast(
			raycastOrigin,
			raycastDirection * RAYCAST_DISTANCE,
			raycastParams
		)
	end
	return raycastIngredientSurfaceRay(-stationRightVector), raycastIngredientSurfaceRay(stationRightVector)
end
function stationCut.computeClosestSurfacesFromKnife(station, knifePosition)
	local stationPivot = station.model.model:GetPivot()
	local stationRightVector = stationPivot.RightVector
	local knifeProjection = (knifePosition - stationPivot.Position):Dot(stationRightVector)
	local minimumLeftDistance, minimumRightDistance
	local closestLeftSurfacePosition, closestRightSurfacePosition
	for _, itemRegion in station.usedBy.itemRegions do
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams:AddToFilter(itemRegion)
		local leftRaycastResult, rightRaycastResult = raycastIngredientLeftAndRight(knifePosition, stationRightVector, raycastParams)
		if leftRaycastResult then
			local hitProjection = (leftRaycastResult.Position - stationPivot.Position):Dot(stationRightVector)
			local hitProjectionDistance = knifeProjection - hitProjection
			if hitProjectionDistance >= 0 and (not minimumLeftDistance or hitProjectionDistance < minimumLeftDistance) then
				minimumLeftDistance = hitProjectionDistance
				closestLeftSurfacePosition = leftRaycastResult.Position
			end
		end
		if rightRaycastResult then
			local hitProjection = (rightRaycastResult.Position - stationPivot.Position):Dot(stationRightVector)
			local hitProjectionDistance = hitProjection - knifeProjection
			if hitProjectionDistance >= 0 and (not minimumRightDistance or hitProjectionDistance < minimumRightDistance) then
				minimumRightDistance = hitProjectionDistance
				closestRightSurfacePosition = rightRaycastResult.Position
			end
		end
	end
	return {
		minimumLeftDistance = minimumLeftDistance,
		minimumRightDistance = minimumRightDistance,
		leftSurfacePosition = closestLeftSurfacePosition,
		rightSurfacePosition = closestRightSurfacePosition
	}
end
return stationCut
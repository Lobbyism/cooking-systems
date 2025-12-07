local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Matter = require(ReplicatedStorage.packages.matter)
local items = require(ReplicatedStorage.shared.modules.items)
local itemConstants = require(ReplicatedStorage.shared.modules.constants.items)
local remotePayloads = require(ReplicatedStorage.shared.modules.constants.remotePayloads)
local stationCutEvent = ReplicatedStorage.remotes.stationCutEvent
local stationCut = {}
local RAYCAST_DISTANCE = 10
local function raycastOppositeRays(raycastOrigin, raycastDirection, raycastParams)
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
local function raycastIngredientLaterally(targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset, raycastParams)
	local topLeftRaycastResult, topRightRaycastResult = raycastOppositeRays(
		(targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * topAttachmentOffset).Position,
		targetKnifeCFrame.LookVector,
		raycastParams
	)
	local bottomLeftRaycastResult, bottomRightRaycastResult = raycastOppositeRays(
		(targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * bottomAttachmentOffset).Position,
		targetKnifeCFrame.LookVector,
		raycastParams
	)
	return topLeftRaycastResult, bottomLeftRaycastResult, topRightRaycastResult, bottomRightRaycastResult
end
local function distanceAlongStationLateralVector(stationLateralVector, station, raycastResult)
	if not raycastResult then return nil end
	return (raycastResult.Position - station.model.model:GetPivot().Position):Dot(stationLateralVector)
end
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
function stationCut.applyVerticalKnifeConstraint(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
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
			stationCutEvent:FireServer({
				type = remotePayloads.stationCut.cut,
				topAttachmentPosition = (targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * topAttachmentOffset).Position,
				bottomAttachmentPosition = (targetKnifeCFrame * CFrame.Angles(0, math.pi / 2, 0) * bottomAttachmentOffset).Position,
			})
			station.usedBy = station.usedBy:patch({
				chopped = true
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
function stationCut.applyLateralKnifeConstraint(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams:AddToFilter(station.itemModel.model)
	local stationLateralVector = station.model.model:GetPivot().RightVector
	local topLeftRaycastResult, bottomLeftRaycastResult, topRightRaycastResult, bottomRightRaycastResult = raycastIngredientLaterally(targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset, raycastParams)
	local distancesLeft = {distanceAlongStationLateralVector(stationLateralVector, station, topLeftRaycastResult), distanceAlongStationLateralVector(stationLateralVector, station, bottomLeftRaycastResult)}
	local distancesRight =  {distanceAlongStationLateralVector(stationLateralVector, station, topRightRaycastResult), distanceAlongStationLateralVector(stationLateralVector, station, bottomRightRaycastResult)}
	local leftmostDistance, rightmostDistance = getFurthestDistanceAlongStationLateralVector(distancesLeft), getFurthestDistanceAlongStationLateralVector(distancesRight)
	if not leftmostDistance or not rightmostDistance then return targetKnifeCFrame end
	local knifeLateralCoordinate = (targetKnifeCFrame.Position - station.model.model:GetPivot().Position):Dot(stationLateralVector)
	local minimumLateralCoordinate, maximumLateralCoordinate = math.min(leftmostDistance, rightmostDistance), math.max(leftmostDistance, rightmostDistance)
	if knifeLateralCoordinate > minimumLateralCoordinate and knifeLateralCoordinate < maximumLateralCoordinate then
		local distanceToLeft, distanceToRight = math.abs(knifeLateralCoordinate - minimumLateralCoordinate), math.abs(knifeLateralCoordinate - maximumLateralCoordinate)
		local snapCoordinate = if distanceToLeft < distanceToRight then minimumLateralCoordinate else maximumLateralCoordinate
		local stationToKnifeOffset = targetKnifeCFrame.Position - station.model.model:GetPivot().Position
		local distanceParallelToStationLateralAxis = stationLateralVector * knifeLateralCoordinate
		local distancePerpendicularToStationLateralAxis = stationToKnifeOffset - distanceParallelToStationLateralAxis
		local snappedPosition = station.model.model:GetPivot().Position + stationLateralVector * snapCoordinate + distancePerpendicularToStationLateralAxis
		targetKnifeCFrame = CFrame.new(snappedPosition) * (targetKnifeCFrame - targetKnifeCFrame.Position)
	end
	return targetKnifeCFrame
end
function stationCut.constraintTargetKnifeCFrame(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
	local stationId, _, stationUsedBy = station.id, station.itemModel, station.usedBy
	local _, fakeKnife = stationUsedBy.fakeArm, stationUsedBy.fakeKnife
	if stationUsedBy.knifeEnteredFromAbove then
		if not stationUsedBy.knifeLockedZ then
			stationUsedBy = stationUsedBy:patch({
				knifeLockedZ = fakeKnife:GetPivot().Position.Z
			})
			world:insert(stationId, stationUsedBy)
		end
		return stationCut.applyVerticalKnifeConstraint(world, station, CFrame.new(
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
	if stationUsedBy.knifeWasAboveIngredientLastFrame then return targetKnifeCFrame end
	return stationCut.applyLateralKnifeConstraint(world, station, targetKnifeCFrame, topAttachmentOffset, bottomAttachmentOffset)
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
	local knifeTargetCFrame = stationCut.constraintTargetKnifeCFrame(world, station, CFrame.new(mouseViewportRay.Origin + mouseViewportRay.Direction * t), topAttachmentOffset, bottomAttachmentOffset)
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
return stationCut
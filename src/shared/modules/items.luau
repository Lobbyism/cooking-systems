local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.shared.modules.matter.components)
local animations = require(ReplicatedStorage.shared.modules.constants.animations)
local itemStates = require(ReplicatedStorage.shared.modules.constants.itemStates)
local items = require(ReplicatedStorage.shared.modules.constants.items)
local function createItemTreeNode(parameters)
	return {
		children = parameters.children,
		discriminant = parameters.discriminant,
		model = parameters.model,
		grip = parameters.grip,
		key = parameters.key
	}
end
local itemTree = {
	tree = {
		Root = createItemTreeNode({
			children = {
				[items.flour] = createItemTreeNode({
					key = items.flour
				}),
				[items.butter] = createItemTreeNode({
					children = {
						[itemStates.states.cut] = {},
					},
					key = items.butter,
					model = ReplicatedStorage.models.items.butter,
					grip = {
						animationId = animations.itemGrip.default,
						offsets = {
							station = CFrame.new(0, 0.25, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
							rightHand = CFrame.new(-0.472413063, -0.868741989, -0.639924049, -0.815182388, 0.0669332966, 0.57532382, -0.513829112, 0.374858469, -0.771661043, -0.267314851, -0.924662709, -0.271185726)
						}
					}
				}),
				[items.knife] = {
					key = items.knife,
					model = ReplicatedStorage.models.items.knife,
					grip = {
						offsets = {
							rightHand = CFrame.new(0, -0.987184763, -0.453267574, -1, 0, 0, 0, 1, 0, 0, 0, -1)
						}
					}
				},
				[items.bowl] = createItemTreeNode({
					key = items.bowl,
					model = ReplicatedStorage.models.items.bowl,
					grip = {
						animationId = animations.itemGrip.default,
						offsets = {
							station = CFrame.new(0, 1.75, 0, 0.99999994, 0, -2.98023224e-08, 0, 1, -1.77635684e-15, -2.98023224e-08, -1.77635684e-15, 1),
							rightHand = CFrame.new(-0.30755806, -1.17798805, -0.556856155, 0.815182328, 0.00836148858, -0.579143941, 0.513828993, 0.451032877, 0.729759455, 0.267314792, -0.892468154, 0.363377661)
						}
					}
				})
			},
			discriminant = function(world, itemId)
				local item = world:get(itemId, components.Item)
				if not item then return end
				return item.key
			end,
			key = "Root"
		})
	}
}
function itemTree.resolve(world, itemId)
	local itemNode = itemTree.tree.Root
	while itemNode do
		if not world:contains(itemId) then return end
		if not itemNode.discriminant then return itemNode end
		local itemNodeKey = itemNode.discriminant(world, itemId)
		if not itemNodeKey then return end
		if not itemNode.children or not itemNode.children[itemNodeKey] then return end
		itemNode = itemNode.children[itemNodeKey]
	end
	return
end
return itemTree
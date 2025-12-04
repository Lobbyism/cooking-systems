local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.packages.matter)
local components = require(ReplicatedStorage.shared.modules.matter.components)
local items = require(ReplicatedStorage.shared.modules.constants.items)
local firstRunSystem = true
local function characterAdded(world, playerId, character)
	world:insert(playerId, components.Model({ model = character }))
	task.delay(.25, function()
		world:insert(playerId, components.HasItem({
			id = world:spawn(components.Item({ key = items.butter, states = {} }))
		}))
	end)
end
local function playerAdded(world, player)
	local playerId = world:spawn(components.Player({ player = player }))
	player.CharacterAdded:Connect(function(character)
		characterAdded(world, playerId, character)
	end)
	if player.Character then
		characterAdded(world, playerId, player.Character)
	end
end
return function(world)
	if firstRunSystem then
		firstRunSystem = false
		for _, player in Players:GetPlayers() do
			playerAdded(world, player)
		end
	end
	for _, player in Matter.useEvent(Players, Players.PlayerAdded) do
		playerAdded(world, player)
	end
end
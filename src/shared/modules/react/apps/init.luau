local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.packages.react)
local ReactRoblox = require(ReplicatedStorage.packages["react-roblox"])
local ContextStack = require(ReplicatedStorage.shared.modules.react.components.ContextStack)
local StationCutting = require(ReplicatedStorage.shared.modules.react.components.StationCutting)
local e = React.createElement
return function()
	local container = Instance.new("ScreenGui")
	container.IgnoreGuiInset = true
	container.ResetOnSpawn = false
	container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	container.Name = "React"
	container.Parent = Players.LocalPlayer.PlayerGui
	local handle = ReactRoblox.createRoot(container)
	handle:render(
		e(ContextStack, {
			providers = {}
		}, {
			e(StationCutting)
		})
	)
end
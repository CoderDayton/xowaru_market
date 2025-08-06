local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

local ShopUI = script.Parent
local MainPanel = ShopUI:WaitForChild("CanvasGroup"):WaitForChild("MainPanel")
local CloseButton = MainPanel:WaitForChild("CloseButton")

-- ===== Remote Signal =====
local SetupButtonsLocal = RemoteSignal.new("SetupButtonsLocal")

CloseButton.MouseButton1Click:Connect(function()
    ShopUI.Enabled = false
end)

-- Exit menu with escape key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
		ShopUI.Enabled = false
	end
end)

SetupButtonsLocal:FireLocal(ShopUI)
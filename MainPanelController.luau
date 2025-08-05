local MainPanel = script.Parent
local ShopUI = MainPanel.Parent.Parent

local CloseButton = MainPanel:WaitForChild("CloseButton")

CloseButton.MouseButton1Click:Connect(function()
    ShopUI.Enabled = false
end)
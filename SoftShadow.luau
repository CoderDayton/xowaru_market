local StyleGuide = require(game.ReplicatedStorage.Shared.StyleGuide)

local SoftShadow = {}

function SoftShadow.apply(gui: GuiObject)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "SoftShadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://11999950713" -- 11999950713 512×512 radial gradient
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 1 - StyleGuide.Shadow.SoftShadow.Opacity
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(256, 256, 256, 256)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromScale(0, 0)
	shadow.Parent = gui
end

return SoftShadow

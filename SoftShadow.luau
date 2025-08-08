local StyleGuide = require(game.ReplicatedStorage.Shared.StyleGuide)

local SoftShadow = {}

-- Applies a soft shadow to a GuiObject
-- options: {
--     Id: string,         -- Unique name suffix (e.g. "Glow", "Outline")
--     Color: Color3,      -- Override shadow color
--     Opacity: number,    -- Override opacity
--     SizeScale: number,  -- Override relative size
--     ZIndex: number,     -- Override ZIndex
-- }
function SoftShadow.apply(gui: GuiObject, options: {
    SizeScale: number?,
    Opacity: number?,
    Color: Color3?,
    Position: "Inside" | "Outside"?
})
	options = options or {}
	local style = StyleGuide.Shadow.SoftShadow

	-- Unique shadow name
	local id = options.Id or tostring(math.random(100000, 999999))
	local shadowName = "SoftShadow_" .. id

	-- Create new shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = shadowName
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://11999950713" -- radial gradient
	shadow.ImageColor3 = options.Color or StyleGuide.Colors.Glow
	shadow.ImageTransparency = 1 - (options.Opacity or style.Opacity)
	shadow.ScaleType = Enum.ScaleType.Fit
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.ZIndex = options.ZIndex or (gui.ZIndex - 1)

	-- Resize function
	local function updateShadow()
		local sizeScale = options.SizeScale or (1 + (style.Size / 100))
		if style.Blur and style.Blur > 0 then
			sizeScale += style.Blur / 100
		end
		shadow.Size = UDim2.fromScale(sizeScale, sizeScale)
		shadow.Position = UDim2.fromScale(0.5, 0.5)
	end

    if options.Position == "Outside" then
        -- Put behind the gui by making it a sibling with lower ZIndex
        shadow.ZIndex = gui.ZIndex - 1
        shadow.Parent = gui.Parent
    elseif options.Position == "Inside" then
        -- Insert just above gui’s children but below anything “on top”
        shadow.ZIndex = gui.ZIndex + 1
        shadow.Parent = gui
    else
        -- Default: just put inside the gui at same ZIndex
        shadow.ZIndex = gui.ZIndex
        shadow.Parent = gui
    end

	updateShadow()

	-- Store connection
	local conn = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateShadow)
	shadow:SetAttribute("_SizeConnId", id)
	shadow:SetAttribute("_ParentGui", gui)

	-- Keep reference so we can disconnect later
	if not gui:FindFirstChild("_SoftShadowConns") then
		local folder = Instance.new("Folder")
		folder.Name = "_SoftShadowConns"
		folder.Parent = gui
	end
	local connValue = Instance.new("ObjectValue")
	connValue.Name = id
	connValue.Value = conn
	connValue.Parent = gui._SoftShadowConns

	return shadow
end

-- Removes one or all shadows from a GuiObject
function SoftShadow.remove(gui: GuiObject, id: string?)
	if id then
		local shadow = gui:FindFirstChild("SoftShadow_" .. id)
		if shadow then shadow:Destroy() end
		local connValue = gui:FindFirstChild("_SoftShadowConns") and gui._SoftShadowConns:FindFirstChild(id)
		if connValue and connValue.Value then
			connValue.Value:Disconnect()
			connValue:Destroy()
		end
	else
		-- Remove all
		if gui:FindFirstChild("_SoftShadowConns") then
			for _, connValue in ipairs(gui._SoftShadowConns:GetChildren()) do
				if connValue.Value then
					connValue.Value:Disconnect()
				end
			end
			gui._SoftShadowConns:Destroy()
		end
		for _, child in ipairs(gui:GetChildren()) do
			if child.Name:match("^SoftShadow_") then
				child:Destroy()
			end
		end
	end
end

return SoftShadow

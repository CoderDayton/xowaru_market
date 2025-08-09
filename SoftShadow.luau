local StyleGuide = require(game.ReplicatedStorage.Shared.StyleGuide)

local SoftShadow = {}

-- Weak map of targetGui -> { [shadowId] = { RBXScriptConnection, ... } }
local shadowConnections = setmetatable({}, { __mode = "k" })

-- options:
-- {
--   Id: string?,
--   Color: Color3?,
--   Opacity: number?,
--   SizeScale: number?,
--   ZIndex: number?,
--   Location: "Inside" | "Outside"?, -- default "Outside"
--   Position: UDim2?,                 -- only needed if you want a custom spot
--   AnchorPoint: Vector2?,            -- only needed if you want a custom point
-- }
function SoftShadow.apply(
	targetGui: GuiObject,
	options: {
		SizeScale: number?,
		Opacity: number?,
		Color: Color3?,
		Location: "Inside" | "Outside"?,
		Position: UDim2?,
		ZIndex: number?,
		Id: string?,
		AnchorPoint: Vector2?,
	}
)
	options = options or {}
	local style = StyleGuide.Shadow.SoftShadow

	-- Unique identity per layer
	local shadowId = options.Id or tostring(math.random(100000, 999999))
	local shadowName = "SoftShadow_" .. shadowId

	-- Create the visual
	local shadowImage = Instance.new("ImageLabel")
	shadowImage.Name = shadowName
	shadowImage.BackgroundTransparency = 1
	shadowImage.Image = "rbxassetid://11999950713" -- radial gradient
	shadowImage.ImageColor3 = options.Color or StyleGuide.Colors.Glow
	shadowImage.ImageTransparency = 1 - (options.Opacity or style.Opacity)
	shadowImage.ScaleType = Enum.ScaleType.Fit

	-- Decide where it lives and how it layers
	local placement = options.Location or "Outside"
	local anchorPoint: Vector2
	local position: UDim2

	if placement == "Outside" then
		shadowImage.Parent = targetGui.Parent
		shadowImage.ZIndex = options.ZIndex ~= nil and options.ZIndex or (targetGui.ZIndex - 1)
		anchorPoint = options.AnchorPoint or targetGui.AnchorPoint
		position = options.Position or targetGui.Position
	elseif placement == "Inside" then
		shadowImage.Parent = targetGui
		shadowImage.ZIndex = options.ZIndex ~= nil and options.ZIndex or (targetGui.ZIndex + 1)
		anchorPoint = options.AnchorPoint or Vector2.new(0.5, 0.5)
		position = options.Position or UDim2.fromScale(0.5, 0.5)
	else
		-- Treat unknown as "Inside" same-Z
		shadowImage.Parent = targetGui
		shadowImage.ZIndex = options.ZIndex ~= nil and options.ZIndex or targetGui.ZIndex
		anchorPoint = options.AnchorPoint or Vector2.new(0.5, 0.5)
		position = options.Position or UDim2.fromScale(0.5, 0.5)
	end

	shadowImage.AnchorPoint = anchorPoint
	shadowImage.Position = position

	-- Only size is responsive to target size (don’t stomp position)
	local function updateSize()
		local sizeScale = options.SizeScale or (1 + (style.Size / 100))
		if style.Blur and style.Blur > 0 then
			sizeScale += style.Blur / 100
		end
		shadowImage.Size = UDim2.fromScale(sizeScale, sizeScale)
	end
	updateSize()

	-- Track connections so we can clean up
	local conns = {}
	table.insert(conns, targetGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize))

	-- If it's an OUTSIDE shadow and the caller didn't pin a custom Position,
	-- keep it aligned to the target when the target moves/changes anchor.
	if placement == "Outside" and options.Position == nil then
		local function alignToTarget()
			shadowImage.AnchorPoint = targetGui.AnchorPoint
			shadowImage.Position = targetGui.Position
		end
		alignToTarget()
		table.insert(conns, targetGui:GetPropertyChangedSignal("Position"):Connect(alignToTarget))
		table.insert(conns, targetGui:GetPropertyChangedSignal("AnchorPoint"):Connect(alignToTarget))
	end

	shadowConnections[targetGui] = shadowConnections[targetGui] or {}
	shadowConnections[targetGui][shadowId] = conns

	-- Tag the owner GUI on the shadow so we can find outside siblings during removal
	local ownerTag = Instance.new("ObjectValue")
	ownerTag.Name = "_ParentGui"
	ownerTag.Value = targetGui
	ownerTag.Parent = shadowImage

	return shadowImage
end

-- Remove one shadow by Id, or all shadows for a target GUI.
function SoftShadow.remove(targetGui: GuiObject, shadowId: string?)
	local function destroy(inst: Instance?)
		if inst then
			inst:Destroy()
		end
	end

	local function disconnect(target: Instance, id: string?)
		local byId = shadowConnections[target]
		if not byId then
			return
		end

		if id then
			local list = byId[id]
			if list then
				for _, c in ipairs(list) do
					if c then
						c:Disconnect()
					end
				end
				byId[id] = nil
			end
		else
			for idKey, list in pairs(byId) do
				for _, c in ipairs(list) do
					if c then
						c:Disconnect()
					end
				end
				byId[idKey] = nil
			end
			shadowConnections[target] = nil
		end
	end

	if shadowId then
		local name = "SoftShadow_" .. shadowId
		-- child
		destroy(targetGui:FindFirstChild(name))
		-- sibling (outside)
		if targetGui.Parent then
			for _, s in ipairs(targetGui.Parent:GetChildren()) do
				if s.Name == name then
					local tag = s:FindFirstChild("_ParentGui")
					if tag and tag.Value == targetGui then
						destroy(s)
					end
				end
			end
		end
		disconnect(targetGui, shadowId)
		return
	end

	-- remove ALL for this gui
	for _, c in ipairs(targetGui:GetChildren()) do
		if c.Name:match("^SoftShadow_") then
			destroy(c)
		end
	end
	if targetGui.Parent then
		for _, s in ipairs(targetGui.Parent:GetChildren()) do
			if s.Name:match("^SoftShadow_") then
				local tag = s:FindFirstChild("_ParentGui")
				if tag and tag.Value == targetGui then
					destroy(s)
				end
			end
		end
	end
	disconnect(targetGui, nil)
end

return SoftShadow

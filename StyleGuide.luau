--[[ StyleGuide.lua
    Global visual tokens for the entire experience.
    Authoritative and immutable at runtime.
--]]

export type Colors = {
	PrimarySurface: Color3,
	Elevation1: Color3,
	Accent: Color3,
	Glow: Color3,
}

export type Typography = {
	Header: Font,
	Body: Font,
}

export type Spacing = {
	CornerSmall: number,
	CornerLarge: number,
}

export type Shadow = {
	SoftShadow: {
		Blur: number,
		Size: number,
		Opacity: number,
	},
}

local StyleGuide = {}

local function font(id: string, weight: Enum.FontWeight): Font
    return Font.new(id, weight, Enum.FontStyle.Normal)
end

StyleGuide.Colors = {
	PrimarySurface = Color3.fromRGB(18, 18, 20),
	Elevation1 = Color3.fromRGB(28, 28, 32),
	Accent = Color3.fromRGB(0, 132, 255),
	Glow = Color3.fromRGB(0, 170, 255),
}

StyleGuide.Typography = {
	Header = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
	Body = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	Regular = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
}

-- ===== Scale ======
local REF_X, REF_Y = 1920, 1080 -- Reference resolution for scaling
local function X(px: number): number return px / REF_X end
local function Y(py: number): number return py / REF_Y end

StyleGuide.Scale = {
    Padding      = UDim.new(0,0), -- Placeholder, can be set later
    CornerSmall  = UDim.new(X(4), 0),
    CornerLarge  = UDim.new(X(12), 0),

    CardSize     = UDim2.fromScale(0.48, 0.3)
}

StyleGuide.Spacing = {
	CornerSmall = 4,
	CornerLarge = 12,
}

StyleGuide.Shadow = {
	SoftShadow = {
		Blur = 24,
		Size = 0,
		Opacity = 0.25,
	},
}

return StyleGuide

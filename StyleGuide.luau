--[[ StyleGuide.lua
    Global visual tokens for the entire experience.
    Authoritative and immutable at runtime.
]]

export type Colors = {
	PrimarySurface: Color3,
	Elevation1: Color3,
	Accent: Color3,
	Glow: Color3,
}

export type Typography = {
	Header: Font,
	Body: Font,
	Regular: Font,
}

export type Spacing = {
	CornerSmall: number,
	CornerLarge: number,
	PaddingSmall: number,
	PaddingMedium: number,
	PaddingLarge: number,
}

export type Shadow = {
	SoftShadow: {
		Blur: number,
		Size: number,
		Opacity: number,
	},
}

local StyleGuide = {}

-- ===== Font Helper =====
local function font(id: string, weight: Enum.FontWeight): Font
	return Font.new(id, weight, Enum.FontStyle.Normal)
end

-- ===== Colors =====
StyleGuide.Colors = {
	PrimarySurface = Color3.fromRGB(18, 18, 20),
	Elevation1 = Color3.fromRGB(28, 28, 32),
	Accent = Color3.fromRGB(0, 132, 255),
	Glow = Color3.fromRGB(0, 170, 255),
    Glow2 = Color3.fromRGB(0, 255, 255),
    Glow3 = Color3.fromRGB(255, 255, 255),
    Glow4 = Color3.fromRGB(63, 18, 18),
    Glow5 = Color3.fromRGB(255, 215, 0),
} :: Colors

-- ===== Typography =====
StyleGuide.Typography = {
	Header = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
	Body = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	Regular = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
} :: Typography

-- ===== Scaling Helpers =====
local REF_X, REF_Y = 1280, 720
local function X(px: number): number return px / REF_X end
local function Y(py: number): number return py / REF_Y end
StyleGuide.ScaleFuncs = { X = X, Y = Y }

-- ===== Scale Tokens =====
StyleGuide.Scale = {
}

-- ===== Spacing =====
StyleGuide.Spacing = {
	CornerSmall = 4,
	CornerLarge = 12,
	PaddingSmall = 6,
	PaddingMedium = 12,
	PaddingLarge = 18,
} :: Spacing

-- ===== Shadows =====
StyleGuide.Shadow = {
	SoftShadow = {
		Blur = 24,
		Size = 0,
		Opacity = 0.25,
	},
} :: Shadow

return table.freeze(StyleGuide)

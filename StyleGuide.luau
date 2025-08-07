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

StyleGuide.Colors = {
	PrimarySurface = Color3.fromRGB(18, 18, 20),
	Elevation1 = Color3.fromRGB(28, 28, 32),
	Accent = Color3.fromRGB(0, 132, 255),
	Glow = Color3.fromRGB(0, 170, 255),
}

StyleGuide.Typography = {
	Header = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
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

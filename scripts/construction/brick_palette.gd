class_name BrickPalette
extends RefCounted

# Saturated molded-plastic colors. No logos, copied textures, or proprietary
# assets are used. Readability comes from color blocking, seams, shine, studs,
# transparent inserts, and recognizable construction silhouettes.
const RED: Color = Color(0.72, 0.055, 0.045)
const DARK_RED: Color = Color(0.42, 0.035, 0.035)
const BLUE: Color = Color(0.035, 0.30, 0.67)
const DARK_BLUE: Color = Color(0.025, 0.12, 0.32)
const YELLOW: Color = Color(0.95, 0.72, 0.04)
const GREEN: Color = Color(0.06, 0.48, 0.17)
const DARK_GREEN: Color = Color(0.025, 0.25, 0.09)
const ORANGE: Color = Color(0.96, 0.34, 0.035)
const WHITE: Color = Color(0.93, 0.93, 0.88)
const BLACK: Color = Color(0.035, 0.04, 0.045)
const LIGHT_GRAY: Color = Color(0.62, 0.66, 0.67)
const DARK_GRAY: Color = Color(0.23, 0.26, 0.27)
const TAN: Color = Color(0.72, 0.60, 0.39)
const DARK_TAN: Color = Color(0.44, 0.35, 0.22)
const BROWN: Color = Color(0.34, 0.17, 0.075)
const DARK_BROWN: Color = Color(0.18, 0.075, 0.035)
const SAND_GREEN: Color = Color(0.34, 0.50, 0.39)
const GLASS_BLUE: Color = Color(0.30, 0.67, 0.83, 0.46)
const GLASS_DARK: Color = Color(0.10, 0.34, 0.46, 0.52)
const GLASS_CLEAR: Color = Color(0.84, 0.94, 1.0, 0.30)
const RUBBER: Color = Color(0.045, 0.05, 0.05)
const SILVER: Color = Color(0.62, 0.66, 0.66)
const CHROME_DARK: Color = Color(0.28, 0.31, 0.33)

const PLASTIC_ROUGHNESS: float = 0.24
const SOFT_PLASTIC_ROUGHNESS: float = 0.38
const TRANSPARENT_ROUGHNESS: float = 0.12
const RUBBER_ROUGHNESS: float = 0.82
const METAL_ROUGHNESS: float = 0.20

static func classic_colors() -> Array[Color]:
	var colors: Array[Color] = [RED, BLUE, YELLOW, GREEN, ORANGE, WHITE, BLACK, LIGHT_GRAY, DARK_GRAY, TAN, BROWN]
	return colors

static func accent_for(color: Color) -> Color:
	var amount: float = 0.10
	return Color(
		clampf(color.r + amount, 0.0, 1.0),
		clampf(color.g + amount, 0.0, 1.0),
		clampf(color.b + amount, 0.0, 1.0),
		color.a
	)

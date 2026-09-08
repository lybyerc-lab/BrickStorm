# @brickstorm.system pickups
# @brickstorm.role Canonical LEGO-style stud denominations and visual identity for every physical currency pickup.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract stud_denominations,stud_color_identity
# @brickstorm.north_star classic_lego_currency
# @brickstorm.owner openai/brickstorm

class_name StudCurrency
extends RefCounted

const VALUE_SILVER: int = 10
const VALUE_GOLD: int = 100
const VALUE_BLUE: int = 1000
const VALUE_PURPLE: int = 10000

const COLOR_SILVER: Color = Color(0.68, 0.72, 0.75)
const COLOR_GOLD: Color = Color(0.94, 0.68, 0.08)
const COLOR_BLUE: Color = Color(0.08, 0.34, 0.92)
const COLOR_PURPLE: Color = Color(0.60, 0.12, 0.86)

const ACCENT_SILVER: Color = Color(0.92, 0.95, 0.97)
const ACCENT_GOLD: Color = Color(1.0, 0.86, 0.22)
const ACCENT_BLUE: Color = Color(0.30, 0.62, 1.0)
const ACCENT_PURPLE: Color = Color(0.82, 0.36, 1.0)

static func is_canonical(value: int) -> bool:
	return value in [VALUE_SILVER, VALUE_GOLD, VALUE_BLUE, VALUE_PURPLE]

static func canonicalize(value: int) -> int:
	if value >= VALUE_PURPLE:
		return VALUE_PURPLE
	if value >= VALUE_BLUE:
		return VALUE_BLUE
	if value >= VALUE_GOLD:
		return VALUE_GOLD
	return VALUE_SILVER

static func color_for(value: int) -> Color:
	match canonicalize(value):
		VALUE_PURPLE:
			return COLOR_PURPLE
		VALUE_BLUE:
			return COLOR_BLUE
		VALUE_GOLD:
			return COLOR_GOLD
		_:
			return COLOR_SILVER

static func accent_for(value: int) -> Color:
	match canonicalize(value):
		VALUE_PURPLE:
			return ACCENT_PURPLE
		VALUE_BLUE:
			return ACCENT_BLUE
		VALUE_GOLD:
			return ACCENT_GOLD
		_:
			return ACCENT_SILVER

static func label_for(value: int) -> String:
	match canonicalize(value):
		VALUE_PURPLE:
			return "PURPLE"
		VALUE_BLUE:
			return "BLUE"
		VALUE_GOLD:
			return "GOLD"
		_:
			return "SILVER"

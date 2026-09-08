# The joke layer.
#
# The LEGO games are silent comedies: nobody speaks, everything is pantomime and
# sound effect, and the game is constantly making small jokes at the player's
# expense. That is not decoration on top of the game - it is half of why anyone
# plays them. This node owns it.
class_name Comedy
extends Node3D

# ============================================================================
# [BS:COMEDY:VOCABULARY]
# Purpose: The word banks. Comic-book onomatopoeia, drawn at the impact.
# Invariants:
# - Nothing here is ever a real word of dialogue. The cast does not speak
#   (Docs/GAME_CONCEPT.md §9, silent-comedy pantomime).
# - The joke is always at the player's or the scenery's expense, never at an
#   actor's - nothing that moves is ever harmed, so nothing that moves is ever
#   the butt of a cruel joke either.
# ============================================================================
const SMASH_WORDS: Array[String] = [
	"SMASH!", "CRUNCH!", "KRAK!", "WHUMP!", "BONK!", "SPLAT!", "CLONK!", "WHACK!",
]
const RAM_WORDS: Array[String] = [
	"YEEHAW!", "KRUNCH!", "WHAM!", "OOF!", "TIMBER!", "SORRY!",
]
const TUMBLE_WORDS: Array[String] = [
	"WHOOPS!", "OOF!", "YIKES!", "AAAA!", "MY HAT!", "NOT AGAIN!",
]
const COW_WORDS: Array[String] = [
	"MOO!", "MOOO!", "M O O !", "MOO?!",
]
const BUILD_WORDS: Array[String] = [
	"TA-DA!", "NICE!", "SOLID!",
]
# [BS:COMEDY:VOCABULARY:END]

const GRAVITY := 3.0

var _live: Array = []


# ============================================================================
# [BS:COMEDY:POPUPS]
# Purpose: Floating comic-book words that pop at the point of impact.
# Invariants:
# - Billboarded and depth-tested off, so a joke is never lost behind the barn
#   it is about.
# - Short-lived and capped. Comedy that clutters the screen stops being funny
#   and starts being a readability bug (North Star pillar 5).
# - Purely cosmetic: nothing here may affect simulation or score.
# ============================================================================
const MAX_LIVE := 10

func pop(at: Vector3, text: String, colour: Color = Color(1, 1, 1), size: int = 120) -> void:
	while _live.size() >= MAX_LIVE:
		_retire(0)

	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = maxi(8, size / 8)
	l.modulate = colour
	l.outline_modulate = Color(0.06, 0.06, 0.09, 1.0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	add_child(l)
	l.global_position = at + Vector3(randf_range(-1.6, 1.6), randf_range(0.3, 1.4), randf_range(-1.6, 1.6))

	_live.append({
		"node": l,
		"life": 1.15,
		"vel": Vector3(randf_range(-0.7, 0.7), randf_range(3.4, 4.6), randf_range(-0.7, 0.7)),
	})


func smash(at: Vector3) -> void:
	pop(at, SMASH_WORDS.pick_random(), Color(1.0, 0.92, 0.35), 130)


func ram(at: Vector3) -> void:
	pop(at, RAM_WORDS.pick_random(), Color(1.0, 0.62, 0.20), 150)


func tumble(at: Vector3) -> void:
	pop(at, TUMBLE_WORDS.pick_random(), Color(1.0, 0.55, 0.5), 130)


func moo(at: Vector3) -> void:
	pop(at, COW_WORDS.pick_random(), Color(1, 1, 1), 110)


func built(at: Vector3) -> void:
	pop(at, BUILD_WORDS.pick_random(), Color(0.55, 1.0, 0.65), 130)


func _retire(i: int) -> void:
	var e: Dictionary = _live[i]
	if is_instance_valid(e["node"]):
		e["node"].queue_free()
	_live.remove_at(i)


func _process(delta: float) -> void:
	var i := _live.size() - 1
	while i >= 0:
		var e: Dictionary = _live[i]
		var n: Label3D = e["node"]
		if not is_instance_valid(n):
			_live.remove_at(i)
			i -= 1
			continue
		var v: Vector3 = e["vel"]
		v.y -= GRAVITY * delta
		e["vel"] = v
		n.global_position += v * delta
		e["life"] -= delta
		var life: float = e["life"]
		n.modulate.a = clampf(life / 0.5, 0.0, 1.0)
		var k: float = 1.0 + clampf((1.15 - life) * 2.2, 0.0, 0.35)
		n.scale = Vector3(k, k, k)
		if life <= 0.0:
			_retire(i)
		i -= 1
# [BS:COMEDY:POPUPS:END]

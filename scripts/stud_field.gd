# Loose studs.
#
# Deliberately not physics bodies - a few hundred RigidBody3D studs would eat a
# phone alive. They pop, fall on a hand-rolled arc, settle, spin, and magnet to
# the player. Value is decided at the MOMENT OF COLLECTION from the player's own
# risk band, which is what makes standing close to the funnel the whole game.
class_name StudField
extends Node3D

signal collected(value: int, band: int, at: Vector3, denom: int)

const MAX_STUDS := 240
const PICKUP_DIST := 1.05


# ============================================================================
# [BS:ECONOMY:DENOMINATION]
# Purpose: Studs come in sizes, and the big ones mean something.
# Invariants:
# - SILVER IS THE COMMON ONE, as it is in the LEGO games. Every payout in this
#   game used to be base ten times the band, and a 200-second round logged
#   roughly 370 near-identical +10/+20/+30 events. The playtest note was that
#   the stud stream had no texture: no jackpots, no surprises, nothing worth
#   crossing a room for. See Docs/PLAYTEST_VS_LEGO_INDY.md finding 4.
# - A BIG STUD IS EARNED, NOT ROLLED. Gold and blue are not a random weight on
#   rubble - they are dropped when a structure is finished off, so a jackpot has
#   a LOCATION and the reward is for completing a smash rather than starting
#   one. A random roll would have added variance without adding a decision.
# - DENOMINATION MULTIPLIES WITH THE BAND, it does not replace it. The band
#   multiplier at the moment of collection is still the whole game
#   (BS:ECONOMY:STUD_VALUE), so a gold stud sitting inside the red band is
#   worth going in for.
# - Size on screen follows value. A jackpot the player cannot pick out of a
#   field of silver is not a jackpot.
# ============================================================================
const VALUE_SILVER := 10
const VALUE_GOLD := 100
const VALUE_BLUE := 1000


static func denom_colour(denom: int) -> Color:
	if denom >= VALUE_BLUE:
		return Color(0.30, 0.55, 0.92)
	if denom >= VALUE_GOLD:
		return Color(0.98, 0.78, 0.18)
	return Color(0.78, 0.80, 0.82)


static func denom_scale(denom: int) -> float:
	if denom >= VALUE_BLUE:
		return 1.9
	if denom >= VALUE_GOLD:
		return 1.4
	return 1.0
# [BS:ECONOMY:DENOMINATION:END]

var studs: Array = []


# ============================================================================
# [BS:ECONOMY:STUD_RECYCLING]
# Purpose: Stud spawning under a hard cap.
# Invariants:
# - At the cap, retire the OLDEST stud rather than refusing the new
#   one. Refusing starves the field: loot strands behind the storm and
#   the player walks through an empty world. This has already been a
#   bug once.
# - Studs are deliberately not physics bodies - a few hundred
#   RigidBody3D studs would eat a phone alive.
# ============================================================================
func spawn_burst(at: Vector3, count: int, denom: int = VALUE_SILVER) -> void:
	for i in range(count):
		# At the cap, retire the OLDEST stud rather than refusing the new one.
		# Refusing starves the field: every stud ends up stranded behind the
		# storm and the player walks through an empty world.
		while studs.size() >= MAX_STUDS:
			_retire_oldest()
		var n := BrickLib.stud_visual(denom_colour(denom))
		add_child(n)
		n.scale = Vector3.ONE * denom_scale(denom)
		n.global_position = at + Vector3(randf_range(-0.4, 0.4), 0.3, randf_range(-0.4, 0.4))
		studs.append({
			"node": n,
			"vel": Vector3(randf_range(-3.2, 3.2), randf_range(3.0, 6.5), randf_range(-3.2, 3.2)),
			"settled": false,
			"spin": randf_range(2.0, 4.5),
			"denom": denom,
		})
# [BS:ECONOMY:STUD_RECYCLING:END]


# ============================================================================
# [BS:ECONOMY:STUD_VALUE]
# Purpose: Magnet, pickup, and the value decision.
# Invariants:
# - Value is decided at the MOMENT OF COLLECTION from the PLAYER's
#   current risk band - not from where the stud spawned. This is what
#   makes standing close to the funnel the whole game.
# - A tumbling player collects nothing; the toll must have a cost.
# ============================================================================
func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var tor := get_tree().get_first_node_in_group("tornado") as Tornado
	var magnet: float = player.magnet_range() if player != null else 0.0
	var ppos: Vector3 = player.global_position if player != null else Vector3.ZERO

	var i := studs.size() - 1
	while i >= 0:
		var s: Dictionary = studs[i]
		var n: Node3D = s["node"]
		if not is_instance_valid(n):
			studs.remove_at(i)
			i -= 1
			continue

		n.rotation.y += s["spin"] * delta

		if not s["settled"]:
			var v: Vector3 = s["vel"]
			v.y -= 22.0 * delta
			n.global_position += v * delta
			s["vel"] = v
			if n.global_position.y <= 0.16:
				n.global_position.y = 0.16
				s["settled"] = true
		var far := n.global_position.distance_squared_to(ppos) > 900.0
		if not far and s["settled"]:
			n.global_position.y = 0.16 + sin(Time.get_ticks_msec() * 0.004 + float(i)) * 0.06

		if not far and player != null and player.tumble_timer <= 0.0:
			var d := n.global_position.distance_to(ppos + Vector3(0, 0.5, 0))
			if d < magnet:
				var pull: float = clampf(1.0 - d / magnet, 0.0, 1.0)
				n.global_position = n.global_position.lerp(
					ppos + Vector3(0, 0.7, 0), delta * (5.0 + pull * 16.0))
				s["settled"] = true
			if d < PICKUP_DIST:
				var band: int = tor.band_of(ppos) if tor != null else 0
				var denom: int = int(s.get("denom", VALUE_SILVER))
				var value: int = denom * Tornado.band_multiplier(band)
				collected.emit(value, band, n.global_position, denom)
				n.queue_free()
				studs.remove_at(i)
		i -= 1
# [BS:ECONOMY:STUD_VALUE:END]


func _retire_oldest() -> void:
	if studs.is_empty():
		return
	var s: Dictionary = studs[0]
	if is_instance_valid(s["node"]):
		s["node"].queue_free()
	studs.remove_at(0)


func clear_all() -> void:
	for s in studs:
		if is_instance_valid(s["node"]):
			s["node"].queue_free()
	studs.clear()

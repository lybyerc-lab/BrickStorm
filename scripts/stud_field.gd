# Loose studs.
#
# Deliberately not physics bodies - a few hundred RigidBody3D studs would eat a
# phone alive. They pop, fall on a hand-rolled arc, settle, spin, and magnet to
# the player. Value is decided at the MOMENT OF COLLECTION from the player's own
# risk band, which is what makes standing close to the funnel the whole game.
class_name StudField
extends Node3D

signal collected(value: int, band: int, at: Vector3)

const MAX_STUDS := 240
const BASE_VALUE := 10
const PICKUP_DIST := 1.05

var studs: Array = []


func spawn_burst(at: Vector3, count: int, colour: Color = BrickLib.C_YELLOW) -> void:
	for i in range(count):
		# At the cap, retire the OLDEST stud rather than refusing the new one.
		# Refusing starves the field: every stud ends up stranded behind the
		# storm and the player walks through an empty world.
		while studs.size() >= MAX_STUDS:
			_retire_oldest()
		var n := BrickLib.stud_visual(colour)
		add_child(n)
		n.global_position = at + Vector3(randf_range(-0.4, 0.4), 0.3, randf_range(-0.4, 0.4))
		studs.append({
			"node": n,
			"vel": Vector3(randf_range(-3.2, 3.2), randf_range(3.0, 6.5), randf_range(-3.2, 3.2)),
			"settled": false,
			"spin": randf_range(2.0, 4.5),
		})


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
		else:
			n.global_position.y = 0.16 + sin(Time.get_ticks_msec() * 0.004 + float(i)) * 0.06

		if player != null and player.tumble_timer <= 0.0:
			var d := n.global_position.distance_to(ppos + Vector3(0, 0.5, 0))
			if d < magnet:
				var pull: float = clampf(1.0 - d / magnet, 0.0, 1.0)
				n.global_position = n.global_position.lerp(
					ppos + Vector3(0, 0.7, 0), delta * (5.0 + pull * 16.0))
				s["settled"] = true
			if d < PICKUP_DIST:
				var band: int = tor.band_of(ppos) if tor != null else 0
				var value: int = BASE_VALUE * Tornado.band_multiplier(band)
				collected.emit(value, band, n.global_position)
				n.queue_free()
				studs.remove_at(i)
		i -= 1


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

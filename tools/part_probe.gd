# Measures every part in BrickLib's library and renders them side by side.
#
# The numbers matter more than the picture. A part can look plausible in a
# screenshot and still be inside-out, open at one end, or spilling outside the
# unit cube every instance is scaled by - and all three of those have actually
# happened in this project. So: triangle count, bounding box, surface area,
# enclosed volume, and the winding of every single triangle against the normal
# the builder gave it.
extends SceneTree

var _out: String = ""


# Screenshots land next to the repo when this runs locally. A CI runner has no
# such directory and cannot create one, so fall back to user:// instead of
# filling the log with write errors for a picture nobody is going to look at.
static func _out_dir(preferred: String) -> String:
	if DirAccess.make_dir_recursive_absolute(preferred) == OK:
		return preferred
	return "user://probe"


func _initialize() -> void:
	_run()


# Vertices, normals and triangle indices for a surface, de-indexed.
static func _tris(m: Mesh) -> Array:
	var a := m.surface_get_arrays(0)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	# SurfaceTool.commit() only produces an index array when it actually shares
	# vertices; with per-face normals nothing is shared and this comes back nil.
	var idx := PackedInt32Array()
	if a[Mesh.ARRAY_INDEX] != null:
		idx = a[Mesh.ARRAY_INDEX]
	var out: Array = []
	if idx.is_empty():
		for i in range(0, verts.size(), 3):
			out.append([verts[i], verts[i + 1], verts[i + 2],
				norms[i], norms[i + 1], norms[i + 2]])
	else:
		for i in range(0, idx.size(), 3):
			out.append([verts[idx[i]], verts[idx[i + 1]], verts[idx[i + 2]],
				norms[idx[i]], norms[idx[i + 1]], norms[idx[i + 2]]])
	return out


static func measure(m: Mesh) -> Dictionary:
	var tris := _tris(m)
	var area := 0.0
	var vol := 0.0
	var backwards := 0
	var degenerate := 0
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for t in tris:
		var v0: Vector3 = t[0]
		var v1: Vector3 = t[1]
		var v2: Vector3 = t[2]
		var g := (v1 - v0).cross(v2 - v0)
		var a := g.length() * 0.5
		if a < 1e-9:
			degenerate += 1
			continue
		area += a
		vol += v0.dot(v1.cross(v2)) / 6.0
		# Godot's front face is CLOCKWISE seen from the front, so the geometric
		# cross product must point AGAINST the outward normal the builder gave
		# these vertices. See BS:BUILD:WINDING.
		var n: Vector3 = (t[3] + t[4] + t[5]).normalized()
		if g.normalized().dot(n) > 0.0:
			backwards += 1
		for v in [v0, v1, v2]:
			lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
			hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))
	return {
		"tris": tris.size(), "area": area, "volume": absf(vol),
		"backwards": backwards, "degenerate": degenerate, "lo": lo, "hi": hi,
	}


func _run() -> void:
	_out = _out_dir("/home/user/brickstorm_shots/wind")
	var bad := 0
	print("part                tris    area   volume  back  degen  bounds")
	for k in range(BrickLib.PART_COUNT):
		var m := BrickLib.part_mesh(k)
		if m == null:
			print("%-18s MISSING" % BrickLib.part_name(k))
			bad += 1
			continue
		var d := measure(m)
		print("%-18s %5d  %6.3f  %6.4f  %4d  %5d  [%.2f,%.2f,%.2f]..[%.2f,%.2f,%.2f]" % [
			BrickLib.part_name(k), d["tris"], d["area"], d["volume"],
			d["backwards"], d["degenerate"],
			d["lo"].x, d["lo"].y, d["lo"].z, d["hi"].x, d["hi"].y, d["hi"].z])
		if d["backwards"] > 0:
			print("   FAIL: %d triangles wound against their own normal" % d["backwards"])
			bad += 1
		if d["volume"] < 0.02:
			print("   FAIL: encloses almost nothing - the part is probably open")
			bad += 1
		var lo: Vector3 = d["lo"]
		var hi: Vector3 = d["hi"]
		if lo.x < -0.501 or lo.y < -0.501 or lo.z < -0.501 \
				or hi.x > 0.501 or hi.y > 0.501 or hi.z > 0.501:
			print("   FAIL: outside the unit cube every instance is scaled by")
			bad += 1
	# The numbers the hand-written brick produced, kept as a golden reference.
	# The generic builder was required to match them exactly before it was
	# allowed to replace that code, and it still has to: a change to the shared
	# chamfer construction that quietly reshapes every brick in the game is the
	# regression this line exists to catch.
	var b := measure(BrickLib.brick_mesh())
	print("brick vs hand-built golden  %d tris  area %.3f  volume %.4f"
		% [b["tris"], b["area"], b["volume"]])
	if b["tris"] != 44 or absf(b["area"] - 5.750) > 1e-3 \
			or absf(b["volume"] - 0.9929) > 1e-4:
		print("   FAIL: the brick no longer matches the mesh it replaced"
			+ " (expected 44 tris, area 5.750, volume 0.9929)")
		bad += 1
	# The rendered half of the tear-mapping check. --selftest can only verify
	# the bookkeeping, because headless Godot returns identity for every
	# MultiMesh instance transform - a read-back test there passes whatever the
	# code does. This probe runs with a real renderer, so it can read the
	# buffer and see which instance actually went away.
	var mixed := Structure.new()
	for i in range(6):
		mixed.add_part(BrickLib.PART_BRICK if i % 2 == 0 else BrickLib.PART_SLOPE,
			2, 2, BrickLib.BRICK_H, BrickLib.C_BLUE, Vector3(float(i) * 1.2, 0.3, 0.0))
	mixed.finish()
	var before: Array = []
	for e in mixed.entries:
		before.append(mixed._part_mmi[e["kind"]].multimesh
			.get_instance_transform(int(e["slot"])).basis.get_scale())
	mixed._hide_instance(3)
	var gone: Array = []
	for i in range(mixed.entries.size()):
		var e: Dictionary = mixed.entries[i]
		var sc: Vector3 = mixed._part_mmi[e["kind"]].multimesh \
			.get_instance_transform(int(e["slot"])).basis.get_scale()
		if sc.length() < 1e-4:
			gone.append(i)
	print("TEAR read-back: scales before=%s  blanked after hiding 3=%s"
		% [str(before[0]), str(gone)])
	if before[0].length() < 1e-4:
		print("   FAIL: the instance buffer reads back empty - this probe cannot"
			+ " see anything and must not be trusted")
		bad += 1
	elif gone != [3]:
		print("   FAIL: hiding part 3 blanked %s - the entry index and the batch"
			% str(gone) + " slot are being confused")
		bad += 1
	mixed.free()
	print("PARTPROBE %s" % ("OK" if bad == 0 else "FAIL (%d)" % bad))
	await _render()
	quit()


func _render() -> void:
	var r := Node3D.new()
	root.add_child(r)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.12, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.60, 0.66)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 1.6
	we.environment = e
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 34, 0)
	sun.light_energy = 0.35
	r.add_child(sun)

	var cols := [BrickLib.C_RED, BrickLib.C_YELLOW, BrickLib.C_BLUE,
		BrickLib.C_LGREEN, BrickLib.C_WHITE, BrickLib.C_LGREY,
		BrickLib.C_TAN, BrickLib.C_BROWN]
	for k in range(BrickLib.PART_COUNT):
		var mi := MeshInstance3D.new()
		mi.mesh = BrickLib.part_mesh(k)
		# Scaled the way the game scales them: two studs wide, one brick tall,
		# two studs deep. A part that only survives at 1:1:1 is not usable.
		mi.scale = Vector3(2.0 * BrickLib.STUD, BrickLib.BRICK_H, 2.0 * BrickLib.STUD)
		mi.position = Vector3(float(k) * 1.35 - 4.7, 0, 0)
		mi.rotation.y = 0.55
		mi.material_override = BrickLib.mat(cols[k])
		r.add_child(mi)

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.global_position = Vector3(0, 1.4, 4.2)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	cam.current = true
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/parts.png" % _out)
	print("wrote %s/parts.png" % _out)

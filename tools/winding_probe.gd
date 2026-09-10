# Settles which way round SurfaceTool triangles must be wound for Godot to
# call them front-facing, under THIS project's renderer (gl_compatibility).
#
# BrickLib._tri derives winding from the supplied outward normal: it orders the
# vertices so (b-a) x (c-a) . n > 0, i.e. counter-clockwise seen from the +n
# side. Nothing has ever checked that this is what Godot wants. The torso print
# landed on the far surface of the part, which is exactly what an inside-out
# mesh looks like, and that was recorded unresolved in the decision log.
#
# Two single quads, both physically in front of the camera, both with outward
# normal pointing AT the camera. One is wound by the project's convention, the
# other by the opposite one. Back-face culling is on (the default). Exactly one
# can be visible, and which one is the answer.
extends SceneTree

const OUT_DIR := "/home/user/brickstorm_shots/wind"
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


# The quad is wound by BrickLib.wind_cw itself, not by a copy of it. A probe
# that reimplements the rule it is testing can only ever agree with itself.
static func _wound(a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> Array:
	var p := [a, b, c]
	var out: Array = []
	for i in BrickLib.wind_cw(a, b, c, n):
		out.append(p[i])
	return out


static func _quad_mesh(n: Vector3, invert: bool, col: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [
		Vector3(-0.5, -0.5, 0.0), Vector3(0.5, -0.5, 0.0),
		Vector3(0.5, 0.5, 0.0), Vector3(-0.5, 0.5, 0.0),
	]
	for tri in [[0, 1, 2], [0, 2, 3]]:
		var v: Array = _wound(corners[tri[0]], corners[tri[1]], corners[tri[2]], n)
		if invert:
			v = [v[0], v[2], v[1]]
		for p in v:
			st.set_normal(n)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# cull_mode stays BACK: the culling IS the experiment.
	mi.material_override = m
	return mi


func _run() -> void:
	_out = _out_dir(OUT_DIR)
	var r := Node3D.new()
	root.add_child(r)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.0
	r.add_child(cam)
	# Default orientation already looks down -Z, so no look_at is needed - and
	# look_at before the node is in the tree silently leaves it unrotated.
	cam.position = Vector3(0, 0, 4)
	cam.current = true

	# Camera sits at +Z looking down -Z, so a face pointing at it has n = +Z.
	var n := Vector3(0, 0, 1)

	var project := _quad_mesh(n, false, Color(1, 0, 0))   # BrickLib.wind_cw
	project.position = Vector3(-0.7, 0, 0)
	r.add_child(project)

	var opposite := _quad_mesh(n, true, Color(0, 1, 0))   # deliberately reversed
	opposite.position = Vector3(0.7, 0, 0)
	r.add_child(opposite)

	for i in range(14):
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/winding_probe.png" % _out)

	var w := img.get_width()
	var h := img.get_height()
	# Sample each quad's centre. Camera size is the VERTICAL extent, so a
	# world unit is h/3.0 pixels - guessing at fractions of the WIDTH missed
	# both quads on the first run and reported a clean "inconclusive".
	var ppu := float(h) / 3.0
	var left := img.get_pixel(int(float(w) * 0.5 - 0.7 * ppu), int(h * 0.5))
	var right := img.get_pixel(int(float(w) * 0.5 + 0.7 * ppu), int(h * 0.5))
	print("left (BrickLib.wind_cw, red if visible)   = ", left)
	print("right(reversed, green if visible)         = ", right)
	var proj_visible := left.r > 0.5 and left.g < 0.4
	var opp_visible := right.g > 0.5 and right.r < 0.4
	_report(proj_visible, opp_visible)
	await _occlusion_test()
	print("PROJECT CONVENTION VISIBLE : ", proj_visible)
	print("OPPOSITE CONVENTION VISIBLE: ", opp_visible)
	quit()


func _report(proj_visible: bool, opp_visible: bool) -> void:
	if proj_visible and not opp_visible:
		print("WINDING RESULT: OK - BrickLib.wind_cw survives back-face culling,"
			+ " so generated parts show the surface nearest the camera.")
	elif opp_visible and not proj_visible:
		print("WINDING RESULT: INSIDE-OUT - BrickLib.wind_cw is culled and the"
			+ " reversed quad is not. Every generated mesh draws its far side.")
	else:
		print("WINDING RESULT: INCONCLUSIVE - culling may be off,"
			+ " or the probe is aimed wrong.")


# The consequence test. A marker sits at the DEAD CENTRE of a real BrickLib
# brick. If the brick draws its near surface, as a solid part must, the marker
# is hidden. If the brick is inside-out the near surface is culled away, the
# camera is looking at the FAR surface, and the marker - which is nearer than
# that - draws straight through the part.
func _occlusion_test() -> void:
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	var r := Node3D.new()
	root.add_child(r)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.0
	r.add_child(cam)
	cam.position = Vector3(0, 0, 4)
	cam.current = true

	var brick := MeshInstance3D.new()
	brick.mesh = BrickLib.brick_mesh()
	brick.scale = Vector3(2.0, 2.0, 2.0)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0, 0, 1)
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brick.material_override = bm
	r.add_child(brick)

	var marker := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.35
	sp.height = 0.7
	marker.mesh = sp
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(1, 0, 1)
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mm
	r.add_child(marker)          # at the origin: inside the brick

	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/winding_occlusion.png" % _out)
	var magenta := 0
	var blue := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.r > 0.5 and c.b > 0.5 and c.g < 0.3:
				magenta += 1
			elif c.b > 0.5 and c.r < 0.3:
				blue += 1
	print("OCCLUSION brick_px=%d marker_px=%d" % [blue, magenta])
	if magenta == 0 and blue > 0:
		print("OCCLUSION RESULT: OK - the brick is solid from the front.")
	elif magenta > 0:
		print("OCCLUSION RESULT: SEE-THROUGH - the marker inside the brick is"
			+ " visible, so the near surface is being culled.")
	else:
		print("OCCLUSION RESULT: INCONCLUSIVE - nothing in frame.")

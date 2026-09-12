# Does the GPU's ground agree with the CPU's?
#
# The ground MESH is displaced by shaders/ground_height.gdshaderinc; the
# COLLIDER, the props and the studs are placed from scripts/terrain.gd. The
# two are the same formula written twice, in two languages, and nothing in the
# game can tell you when they drift - the world simply stops matching itself,
# props sink into hillsides and the player walks on air.
#
# IT MEASURES THE RESIDUAL, NOT THE VALUE. The first version rendered absolute
# height as greyscale across a 16m range, which is 0.063m per code at best and
# 0.25m once the framebuffer's transfer curve is accounted for. Dropping an
# ENTIRE TERM from the height function moved the worst sample 0.672m and passed
# a 0.75m tolerance - a gate that could not see the very failure it existed
# for. Rendering (gpu - cpu) * gain instead makes the encoding's precision
# irrelevant: the interesting number is centred at mid-grey and amplified.
#
# AND THE SCALE IS MEASURED. Before comparing anything the probe feeds itself
# known offsets at a known point and records what comes back, so the grey ->
# metres mapping is characterised rather than assumed. A naive linear decode
# was wrong by 0.157m on a ramp the CPU could predict exactly. This project has
# been fooled by a rendered read-back before: headless Godot returns identity
# for every MultiMesh transform, and a gate built on that passed vacuously for
# weeks.
extends SceneTree

const GAIN := 20.0
# Agreement we require, in metres. Two implementations of the same trigonometry
# in different languages differ only by float precision, so this is generous
# already; a dropped or mistyped term shows up as tenths of a metre.
const TOL := 0.02

var _sm: ShaderMaterial = null
# offset in metres -> grey that came back, built at run time
var _cal_d: Array[float] = []
var _cal_g: Array[float] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	var r := Node3D.new()
	root.add_child(r)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = e
	r.add_child(we)

	var qm := QuadMesh.new()
	qm.size = Vector2(4.0, 4.0)
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	_sm = ShaderMaterial.new()
	_sm.shader = load("res://shaders/terrain_check.gdshader")
	_sm.set_shader_parameter("gain", GAIN)
	mi.material_override = _sm
	r.add_child(mi)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.position = Vector3(0, 0, 2)
	r.add_child(cam)
	await process_frame
	cam.current = true

	# ---- 0. coarse magnitude first --------------------------------------
	# At low gain the whole plausible error range fits inside the encoding, so
	# a GROSS disagreement is measured here rather than saturating the fine
	# calibration below and reporting itself as a broken instrument. Dropping a
	# whole term from the height function did exactly that: a 0.67m error made
	# the calibration sweep flat, and the probe blamed its own read-back.
	var cal_pt := Vector2(37.0, 61.0)
	var true_h: float = Terrain.height(cal_pt.x, cal_pt.y)
	_sm.set_shader_parameter("gain", 0.5)
	var coarse_g := await _sample(cal_pt, true_h)
	var coarse: float = absf((coarse_g - 0.5) / 0.5)
	print("coarse       disagreement at the calibration point ~%.3f m" % coarse)
	if coarse > 0.10:
		print("TERRAINPROBE FAILED: the shader's ground and terrain.gd disagree")
		print("  by roughly %.2f m - far past a float-precision difference." % coarse)
		print("  A term has been dropped, mistyped, or edited in only one file.")
		quit(1)
		return
	_sm.set_shader_parameter("gain", GAIN)

	# ---- 1. characterise grey -> metres at a fixed point ----------------
	for d in [-0.030, -0.015, -0.005, 0.0, 0.005, 0.015, 0.030]:
		# Feed a deliberately WRONG cpu height by exactly d, so the shader's
		# residual is known, and record what the framebuffer gives back.
		var g := await _sample(cal_pt, true_h - d)
		_cal_d.append(d)
		_cal_g.append(g)
	var mono := true
	for i in range(1, _cal_g.size()):
		if _cal_g[i] < _cal_g[i - 1] - 0.002:
			mono = false
	var swing: float = _cal_g[_cal_g.size() - 1] - _cal_g[0]
	print("calibration  swing %.3f grey over %.3f m, monotonic=%s"
		% [swing, _cal_d[_cal_d.size() - 1] - _cal_d[0], str(mono)])
	if not mono or swing < 0.30:
		print("TERRAINPROBE FAILED: a 60mm error moves the read-back by only")
		print("  %.3f grey, so this instrument cannot see the disagreements it" % swing)
		print("  exists to find. Fix the instrument before trusting a number.")
		quit(1)
		return
	var residual := absf(_invert(_cal_g[3]))
	print("calibration  zero reads as %.4f m (should be ~0)" % residual)
	if residual > TOL:
		print("TERRAINPROBE FAILED: a known-zero residual decodes as %.4f m"
			% residual)
		quit(1)
		return

	# ---- 2. compare the two implementations -----------------------------
	var worst := 0.0
	var worst_at := Vector2.ZERO
	var n := 0
	for iz in range(7):
		for ix in range(5):
			var p := Vector2(-92.0 + 46.0 * float(ix), -300.0 + 150.0 * float(iz))
			var cpu: float = Terrain.height(p.x, p.y)
			var g2 := await _sample(p, cpu)
			var d2: float = absf(_invert(g2))
			n += 1
			if d2 > worst:
				worst = d2
				worst_at = p
	print("compared %d points; worst disagreement %.4f m at (%.0f, %.0f)"
		% [n, worst, worst_at.x, worst_at.y])
	if worst > TOL:
		print("TERRAINPROBE FAILED: the shader's ground and terrain.gd disagree")
		print("  by %.4f m. The world drawn is not the world stood on." % worst)
		quit(1)
		return
	print("TERRAINPROBE OK")
	quit()


func _sample(p: Vector2, cpu_h: float) -> float:
	_sm.set_shader_parameter("probe_point", p)
	_sm.set_shader_parameter("cpu_h", cpu_h)
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	return img.get_pixel(img.get_width() / 2, img.get_height() / 2).r


# Grey back to metres, through the measured curve rather than an assumed one.
func _invert(g: float) -> float:
	if _cal_g.size() < 2:
		return (g - 0.5) / GAIN
	if g <= _cal_g[0]:
		return _cal_d[0]
	for i in range(1, _cal_g.size()):
		if g <= _cal_g[i]:
			var span: float = _cal_g[i] - _cal_g[i - 1]
			var t: float = 0.5 if span < 1.0e-6 else (g - _cal_g[i - 1]) / span
			return lerpf(_cal_d[i - 1], _cal_d[i], t)
	return _cal_d[_cal_d.size() - 1]

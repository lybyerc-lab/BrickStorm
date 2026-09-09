# Anchor verifier.
#
# Checks that Docs/CODE_ANCHORS.md and the source agree, in BOTH directions:
# every anchor in the code is registered, every registered anchor exists in the
# code and in the file the registry claims, every start marker has exactly one
# matching :END, no anchor is used twice, and no anchor nests inside another.
#
# WHAT THIS CANNOT DO, stated plainly because pretending otherwise is how a
# project ends up with checks that only ever pass: this verifies STRUCTURE. It
# cannot tell you whether the code under an anchor still upholds the invariant
# written above it. Only --selftest, a screenshot, or a human can do that.
# See Docs/NO_DRIFT_POLICY.md, "What the checks can and cannot see".
#
# Run: godot --headless --path . --script res://tools/verify_anchors.gd
extends SceneTree

const REGISTRY := "res://Docs/CODE_ANCHORS.md"
const SCAN_DIRS: Array[String] = ["res://scripts", "res://tools", "res://shaders"]

var _errors: Array[String] = []


func _initialize() -> void:
	var registered := _read_registry()
	if registered.is_empty():
		_errors.append("registry %s produced no anchors - is the format still right?" % REGISTRY)

	var found := _scan_sources()

	for anchor in registered:
		if not found.has(anchor):
			_errors.append("registered but MISSING FROM CODE: [%s] (expected in %s)"
				% [anchor, registered[anchor]])
		else:
			var want: String = registered[anchor]
			var got: String = found[anchor]
			if want != got:
				_errors.append("[%s] registered under '%s' but found in '%s'"
					% [anchor, want, got])

	for anchor in found:
		if not registered.has(anchor):
			_errors.append("in code but NOT REGISTERED: [%s] (%s) - add it to %s"
				% [anchor, found[anchor], REGISTRY])

	print("")
	print("anchor registry : %d" % registered.size())
	print("anchors in code : %d" % found.size())
	if _errors.is_empty():
		print("ANCHORS OK")
		quit(0)
		return
	print("")
	for e in _errors:
		print("  FAIL  %s" % e)
	print("")
	print("ANCHORS FAILED (%d)" % _errors.size())
	quit(1)


func _read_registry() -> Dictionary:
	var out: Dictionary = {}
	var f := FileAccess.open(REGISTRY, FileAccess.READ)
	if f == null:
		_errors.append("cannot open %s" % REGISTRY)
		return out
	var re := RegEx.new()
	re.compile("^- `\\[(BS:[A-Z0-9_]+:[A-Z0-9_]+)\\]`[^`]*`([^`]+)`")
	var n := 0
	while not f.eof_reached():
		var line := f.get_line()
		n += 1
		var m := re.search(line)
		if m == null:
			continue
		var anchor := m.get_string(1)
		if out.has(anchor):
			_errors.append("registry lists [%s] twice (line %d)" % [anchor, n])
		out[anchor] = m.get_string(2)
	return out


func _scan_sources() -> Dictionary:
	var out: Dictionary = {}
	var re_start := RegEx.new()
	re_start.compile("^(?:#|//)\\s*\\[(BS:[A-Z0-9_]+:[A-Z0-9_]+)\\]\\s*$")
	var re_end := RegEx.new()
	re_end.compile("^(?:#|//)\\s*\\[(BS:[A-Z0-9_]+:[A-Z0-9_]+):END\\]\\s*$")

	for dir_path in SCAN_DIRS:
		var d := DirAccess.open(dir_path)
		if d == null:
			continue
		for fname in d.get_files():
			# Shaders too. A .gdshader now carries load-bearing invariants - the
			# wind field has to agree with the physics - and a rule the
			# verifier cannot see is a rule that quietly rots.
			if not (fname.ends_with(".gd") or fname.ends_with(".gdshader")):
				continue
			var rel := "%s/%s" % [dir_path.replace("res://", ""), fname]
			_scan_one("%s/%s" % [dir_path, fname], rel, re_start, re_end, out)
	return out


func _scan_one(path: String, rel: String, re_start: RegEx, re_end: RegEx, out: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_errors.append("cannot open %s" % path)
		return
	var open_anchor := ""
	var open_line := 0
	var n := 0
	while not f.eof_reached():
		var line := f.get_line()
		n += 1

		var me := re_end.search(line)
		if me != null:
			var a := me.get_string(1)
			if open_anchor == "":
				_errors.append("%s:%d end marker [%s:END] with no open anchor" % [rel, n, a])
			elif open_anchor != a:
				_errors.append("%s:%d [%s:END] closes [%s]" % [rel, n, a, open_anchor])
			else:
				open_anchor = ""
			continue

		var ms := re_start.search(line)
		if ms != null:
			var a := ms.get_string(1)
			if open_anchor != "":
				_errors.append("%s:%d [%s] nests inside [%s] (opened line %d)"
					% [rel, n, a, open_anchor, open_line])
			if out.has(a):
				_errors.append("%s:%d [%s] already defined in %s" % [rel, n, a, out[a]])
			out[a] = rel
			open_anchor = a
			open_line = n

	if open_anchor != "":
		_errors.append("%s: [%s] opened line %d and never closed" % [rel, open_anchor, open_line])

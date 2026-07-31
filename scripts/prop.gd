class_name Prop
extends Node2D
## Code-drawn scenery. `type` selects the drawing; params in `p`.
## Origin convention: props sit on the ground at local (0,0).

var type := "rock"
var p := {}
var _t := 0.0


func setup(def: Dictionary) -> void:
	type = def.get("type", "rock")
	p = def
	position = def.get("pos", Vector2.ZERO)
	z_index = def.get("z", -1)


func _process(delta: float) -> void:
	if type in ["beam", "torch", "wave", "bellstand", "banner"]:
		_t += delta
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	match type:
		"house":
			_house()
		"stall":
			_stall()
		"lamppost":
			_lamppost()
		"sign":
			_sign()
		"boat":
			_boat()
		"lighthouse":
			_lighthouse()
		"beam":
			_beam()
		"rock":
			_rock()
		"tree":
			_tree()
		"crate":
			_crate()
		"snowman":
			_snowman()
		"bellstand":
			_bellstand()
		"crystal":
			_crystal()
		"seaweed":
			_seaweed()
		"fence":
			_fence()
		"banner":
			_banner()
		"stalactite":
			_stalactite()
		"chest":
			_chest()


func _house() -> void:
	var w: float = p.get("w", 260.0)
	var h: float = p.get("h", 200.0)
	var body: Color = p.get("body", Color("#e8d9b0"))
	var roof: Color = p.get("roof", Color("#c0504a"))
	draw_rect(Rect2(-w / 2, -h, w, h), body)
	draw_rect(Rect2(-w / 2, -h, w, h), body.darkened(0.25), false, 3.0)
	# flat-topped roof, so there's somewhere to stand
	var ridge := roof_top_y()
	var flat := w * 0.22
	var rr := PackedVector2Array([
		Vector2(-w / 2 - 18, -h), Vector2(w / 2 + 18, -h),
		Vector2(flat, ridge), Vector2(-flat, ridge),
	])
	draw_polygon(rr, PackedColorArray([roof, roof, roof, roof]))
	draw_rect(Rect2(-flat - 4, ridge - 5, flat * 2 + 8, 7), roof.darkened(0.25))
	# climbing ledge (awning board under the windows)
	var ly := ledge_y()
	draw_rect(Rect2(-w * 0.42, ly - 7, w * 0.84, 9), roof.darkened(0.15))
	for i in range(3):
		var bx := -w * 0.3 + i * w * 0.3
		draw_line(Vector2(bx, ly), Vector2(bx, ly + 12), body.darkened(0.35), 3.0)
	# door
	var dw := w * 0.22
	draw_rect(Rect2(-dw / 2, -dw * 2.0, dw, dw * 2.0), body.darkened(0.5))
	draw_circle(Vector2(dw * 0.28, -dw * 0.9), 3.0, Color("#d8a12c"))
	# windows
	for wx in [-w * 0.3, w * 0.3]:
		draw_rect(Rect2(wx - w * 0.09, -h * 0.78, w * 0.18, w * 0.18), Color("#9ad8f0"))
		draw_rect(Rect2(wx - w * 0.09, -h * 0.78, w * 0.18, w * 0.18), body.darkened(0.4), false, 2.5)


func roof_top_y() -> float:
	return -(p.get("h", 200.0) + p.get("w", 260.0) * 0.28)


func ledge_y() -> float:
	return -p.get("h", 200.0) * 0.62


func solid_shapes() -> Array:
	## One-way platforms let you walk in front of a prop and land on top of it,
	## so nothing can ever trap the player inside scenery.
	if not p.get("solid", true):
		return []
	match type:
		"house":
			var w: float = p.get("w", 260.0)
			return [
				{"rect": Rect2(-w * 0.22 - 4, roof_top_y() - 5, w * 0.44 + 8, 12), "one_way": true},
				{"rect": Rect2(-w * 0.42, ledge_y() - 7, w * 0.84, 11), "one_way": true},
			]
		"stall":
			var w: float = p.get("w", 220.0)
			return [
				{"rect": Rect2(-w / 2 - 20, -200, w + 40, 12), "one_way": true},
				{"rect": Rect2(-w / 2, -78, w, 12), "one_way": true},
			]
		"crate":
			var s: float = p.get("s", 56.0)
			return [{"rect": Rect2(-s / 2, -s, s, 12), "one_way": true}]
		"boat":
			return [{"rect": Rect2(-88, -32, 176, 12), "one_way": true}]
		"rock":
			var s: float = p.get("s", 50.0)
			return [{"rect": Rect2(-s * 0.72, -s * 0.74, s * 1.44, 12), "one_way": true}]
		"lighthouse":
			var hh: float = p.get("h", 420.0)
			return [{"rect": Rect2(-56, -hh - 14, 112, 14), "one_way": true}]
		"bellstand":
			return [{"rect": Rect2(-80, -196, 160, 12), "one_way": true}]
	return []


func _stall() -> void:
	var w: float = p.get("w", 220.0)
	var c1: Color = p.get("c1", Color("#d9483b"))
	var c2: Color = p.get("c2", Color("#f4f1e8"))
	# counter
	draw_rect(Rect2(-w / 2, -70, w, 70), Color("#8a5a2b"))
	draw_rect(Rect2(-w / 2, -76, w, 10), Color("#6e4522"))
	# poles
	draw_rect(Rect2(-w / 2, -170, 8, 100), Color("#6e4522"))
	draw_rect(Rect2(w / 2 - 8, -170, 8, 100), Color("#6e4522"))
	# striped awning
	var n := 6
	var seg := (w + 40.0) / n
	for i in range(n):
		var col := c1 if i % 2 == 0 else c2
		draw_rect(Rect2(-w / 2 - 20 + i * seg, -196, seg, 30), col)
	draw_rect(Rect2(-w / 2 - 20, -200, w + 40, 6), Color("#6e4522"))
	# goods
	draw_circle(Vector2(-w * 0.25, -86), 10, Color("#e88f2a"))
	draw_circle(Vector2(-w * 0.1, -86), 10, Color("#4ca64c"))
	draw_circle(Vector2(-w * 0.18, -98), 10, Color("#d9483b"))


func _lamppost() -> void:
	draw_rect(Rect2(-4, -180, 8, 180), Color("#3a4048"))
	draw_rect(Rect2(-14, -6, 28, 6), Color("#3a4048"))
	draw_circle(Vector2(0, -188), 12, Color("#ffe08a"))
	draw_circle(Vector2(0, -188), 16, Color(1, 0.9, 0.5, 0.18))
	draw_arc(Vector2(0, -188), 13, 0, TAU, 16, Color("#3a4048"), 2.5)


func _sign() -> void:
	var text: String = p.get("text", "")
	draw_rect(Rect2(-5, -90, 10, 90), Color("#6e4522"))
	draw_rect(Rect2(-70, -130, 140, 44), Color("#8a5a2b"))
	draw_rect(Rect2(-70, -130, 140, 44), Color("#5c3a1c"), false, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-66, -100), text, HORIZONTAL_ALIGNMENT_CENTER, 132, 17, Color("#f4f1e8"))


func _boat() -> void:
	var col: Color = p.get("color", Color("#c0504a"))
	var pts := PackedVector2Array([
		Vector2(-90, -30), Vector2(90, -30), Vector2(60, 10), Vector2(-60, 10),
	])
	draw_polygon(pts, PackedColorArray([col, col, col, col]))
	draw_rect(Rect2(-4, -100, 8, 70), Color("#6e4522"))
	var sail := PackedVector2Array([Vector2(4, -100), Vector2(58, -40), Vector2(4, -40)])
	draw_polygon(sail, PackedColorArray([Color("#f4f1e8"), Color("#f4f1e8"), Color("#f4f1e8")]))


func _lighthouse() -> void:
	var h: float = p.get("h", 420.0)
	var lit: bool = p.get("lit", false)
	var w := 74.0
	# tapered striped tower
	var n := 5
	for i in range(n):
		var y0 := -h * i / n
		var y1 := -h * (i + 1) / n
		var w0 := w * (1.0 - 0.35 * i / n)
		var w1 := w * (1.0 - 0.35 * (i + 1) / n)
		var col := Color("#e84a4a") if i % 2 == 0 else Color("#f4f1e8")
		draw_polygon(
			PackedVector2Array([Vector2(-w0, y0), Vector2(w0, y0), Vector2(w1, y1), Vector2(-w1, y1)]),
			PackedColorArray([col, col, col, col])
		)
	# gallery + lamp room
	var top := -h
	draw_rect(Rect2(-w * 0.75, top - 12, w * 1.5, 12), Color("#3a4048"))
	var lamp_col := Color("#ffe08a") if lit else Color("#5a6572")
	draw_rect(Rect2(-w * 0.42, top - 58, w * 0.84, 46), lamp_col)
	for i in range(3):
		var x := -w * 0.42 + w * 0.84 * (i + 1) / 4.0
		draw_line(Vector2(x, top - 58), Vector2(x, top - 12), Color("#3a4048"), 3.0)
	# dome
	var dome := PackedVector2Array()
	for i in range(13):
		var ang := PI + i * PI / 12.0
		dome.append(Vector2(cos(ang) * w * 0.5, top - 58 + sin(ang) * 26))
	draw_polygon(dome, _solid(dome.size(), Color("#c0504a")))
	if lit:
		draw_circle(Vector2(0, top - 35), 34, Color(1, 0.9, 0.5, 0.25))
	# door
	draw_rect(Rect2(-20, -56, 40, 56), Color("#5c3a1c"))
	draw_arc(Vector2(0, -56), 20, PI, TAU, 12, Color("#5c3a1c"), 6.0)


func _beam() -> void:
	# rotating light beam, drawn from origin (place at lamp room)
	var ang := sin(_t * 0.8) * 0.5 - 0.2
	for k in range(2):
		var a := ang + (PI if k == 1 else 0.0)
		var d := Vector2(cos(a), sin(a) * 0.25)
		var perp := Vector2(-d.y, d.x)
		var far := d * 900.0
		var pts := PackedVector2Array([
			perp * 8.0, far + perp * 90.0, far - perp * 90.0, -perp * 8.0,
		])
		draw_polygon(pts, PackedColorArray([
			Color(1, 0.95, 0.6, 0.5), Color(1, 0.95, 0.6, 0.0),
			Color(1, 0.95, 0.6, 0.0), Color(1, 0.95, 0.6, 0.5),
		]))


func _rock() -> void:
	var s: float = p.get("s", 50.0)
	var col: Color = p.get("color", Color("#7a8288"))
	var pts := PackedVector2Array([
		Vector2(-s, 0), Vector2(-s * 0.7, -s * 0.7), Vector2(-s * 0.1, -s),
		Vector2(s * 0.6, -s * 0.75), Vector2(s, 0),
	])
	draw_polygon(pts, _solid(pts.size(), col))
	draw_polyline(pts, col.darkened(0.3), 3.0)


func _tree() -> void:
	var kind: String = p.get("kind", "pine")
	var s: float = p.get("s", 1.0)
	match kind:
		"palm":
			draw_rect(Rect2(-7 * s, -150 * s, 14 * s, 150 * s), Color("#8a5a2b"))
			for i in range(5):
				var ang := -PI + i * PI / 4.0
				var tip := Vector2(0, -150 * s) + Vector2(cos(ang), sin(ang) * 0.6) * 80 * s
				_frond(Vector2(0, -150 * s), tip, Color("#3f9b57"))
		"pine":
			draw_rect(Rect2(-8 * s, -40 * s, 16 * s, 40 * s), Color("#6e4522"))
			var green := Color(p.get("leaf", Color("#2e6b45")))
			for i in range(3):
				var y := -40.0 * s - i * 55.0 * s
				var w := (90.0 - i * 22.0) * s
				draw_polygon(
					PackedVector2Array([Vector2(-w, y), Vector2(w, y), Vector2(0, y - 85 * s)]),
					_solid(3, green)
				)
		"snowy":
			draw_rect(Rect2(-8 * s, -40 * s, 16 * s, 40 * s), Color("#5c4a3a"))
			for i in range(3):
				var y := -40.0 * s - i * 55.0 * s
				var w := (90.0 - i * 22.0) * s
				draw_polygon(
					PackedVector2Array([Vector2(-w, y), Vector2(w, y), Vector2(0, y - 85 * s)]),
					_solid(3, Color("#3a5a50"))
				)
				draw_polygon(
					PackedVector2Array([Vector2(-w * 0.8, y - 18 * s), Vector2(w * 0.8, y - 18 * s), Vector2(0, y - 80 * s)]),
					_solid(3, Color("#eef4f8"))
				)
		"bare":
			draw_rect(Rect2(-6 * s, -120 * s, 12 * s, 120 * s), Color("#5c4a3a"))
			draw_line(Vector2(0, -100 * s), Vector2(-50 * s, -160 * s), Color("#5c4a3a"), 8 * s)
			draw_line(Vector2(0, -80 * s), Vector2(48 * s, -140 * s), Color("#5c4a3a"), 7 * s)
			draw_line(Vector2(0, -120 * s), Vector2(14 * s, -180 * s), Color("#5c4a3a"), 6 * s)


func _frond(base: Vector2, tip: Vector2, col: Color) -> void:
	var mid := (base + tip) / 2.0 + Vector2(0, -14)
	var perp := (tip - base).normalized().orthogonal() * 10.0
	draw_polygon(PackedVector2Array([base, mid + perp, tip, mid - perp]), _solid(4, col))


func _crate() -> void:
	var s: float = p.get("s", 56.0)
	draw_rect(Rect2(-s / 2, -s, s, s), Color("#a8743d"))
	draw_rect(Rect2(-s / 2, -s, s, s), Color("#6e4522"), false, 4.0)
	draw_line(Vector2(-s / 2, -s), Vector2(s / 2, 0), Color("#6e4522"), 4.0)
	draw_line(Vector2(s / 2, -s), Vector2(-s / 2, 0), Color("#6e4522"), 4.0)


func _snowman() -> void:
	draw_circle(Vector2(0, -30), 30, Color("#f4f7fa"))
	draw_circle(Vector2(0, -74), 22, Color("#f4f7fa"))
	draw_circle(Vector2(0, -108), 16, Color("#f4f7fa"))
	draw_circle(Vector2(-5, -112), 2.5, Color.BLACK)
	draw_circle(Vector2(5, -112), 2.5, Color.BLACK)
	draw_polygon(
		PackedVector2Array([Vector2(0, -108), Vector2(16, -104), Vector2(0, -102)]),
		_solid(3, Color("#e88f2a"))
	)
	draw_line(Vector2(-20, -80), Vector2(-44, -96), Color("#5c4a3a"), 4.0)
	draw_line(Vector2(20, -80), Vector2(44, -96), Color("#5c4a3a"), 4.0)


func _bellstand() -> void:
	var has_bell: bool = p.get("has_bell", false)
	# wooden arch
	draw_rect(Rect2(-70, -180, 14, 180), Color("#6e4522"))
	draw_rect(Rect2(56, -180, 14, 180), Color("#6e4522"))
	draw_rect(Rect2(-80, -196, 160, 18), Color("#8a5a2b"))
	if has_bell:
		var sway := sin(_t * 2.0) * 0.06
		draw_set_transform(Vector2(0, -178), sway, Vector2.ONE)
		IconLib.draw_icon(self, "bell", Vector2(0, 40), 80.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# empty hook + frayed rope
		draw_line(Vector2(0, -178), Vector2(0, -160), Color("#c9b98a"), 4.0)
		draw_circle(Vector2(0, -158), 4.0, Color("#c9b98a"))


func _crystal() -> void:
	var s: float = p.get("s", 40.0)
	var col: Color = p.get("color", Color("#9ad8f0"))
	for off in [Vector2(-s * 0.5, 0), Vector2(s * 0.4, 0), Vector2.ZERO]:
		var hh := s if off == Vector2.ZERO else s * 0.6
		var pts := PackedVector2Array([
			off + Vector2(-s * 0.22, 0), off + Vector2(-s * 0.1, -hh),
			off + Vector2(s * 0.1, -hh * 0.9), off + Vector2(s * 0.22, 0),
		])
		draw_polygon(pts, _solid(4, Color(col, 0.85)))
		draw_polyline(pts, col.lightened(0.4), 2.0)
	draw_circle(Vector2(0, -s * 0.5), s * 0.9, Color(col, 0.10))


func _seaweed() -> void:
	var s: float = p.get("s", 1.0)
	for i in range(3):
		var x := (i - 1) * 16.0 * s
		var col := Color("#2e8b57") if i % 2 == 0 else Color("#3fa06a")
		var pts := PackedVector2Array()
		for k in range(8):
			var yy := -k * 14.0 * s
			pts.append(Vector2(x + sin(k * 0.9 + i) * 8.0 * s, yy))
		draw_polyline(pts, col, 7.0 * s)


func _fence() -> void:
	var w: float = p.get("w", 200.0)
	var n := int(w / 34.0)
	for i in range(n + 1):
		var x := -w / 2 + i * w / n
		draw_rect(Rect2(x - 4, -56, 8, 56), Color("#8a5a2b"))
		draw_polygon(
			PackedVector2Array([Vector2(x - 4, -56), Vector2(x + 4, -56), Vector2(x, -64)]),
			_solid(3, Color("#8a5a2b"))
		)
	draw_rect(Rect2(-w / 2, -46, w, 7), Color("#a8743d"))
	draw_rect(Rect2(-w / 2, -26, w, 7), Color("#a8743d"))


func _banner() -> void:
	var w: float = p.get("w", 300.0)
	var cols := [Color("#d9483b"), Color("#e8c930"), Color("#4ca64c"), Color("#2e8bc0"), Color("#8a4fb0")]
	draw_line(Vector2(-w / 2, 0), Vector2(w / 2, 14), Color("#f4f1e8"), 3.0)
	var n := int(w / 36.0)
	for i in range(n):
		var t := float(i) / (n - 1)
		var x := -w / 2 + t * w
		var y := 14.0 * t + sin(t * PI) * 10.0
		var col: Color = cols[i % cols.size()]
		var sway := sin(_t * 2.0 + i) * 2.0
		draw_polygon(
			PackedVector2Array([
				Vector2(x - 9, y), Vector2(x + 9, y), Vector2(x + sway, y + 22),
			]),
			_solid(3, col)
		)


func _stalactite() -> void:
	var s: float = p.get("s", 60.0)
	var col := Color("#4a5258")
	draw_polygon(
		PackedVector2Array([Vector2(-s * 0.3, 0), Vector2(s * 0.3, 0), Vector2(0, s)]),
		_solid(3, col)
	)


func _chest() -> void:
	var open: bool = p.get("open", false)
	draw_rect(Rect2(-40, -36, 80, 36), Color("#8a5a2b"))
	draw_rect(Rect2(-40, -36, 80, 36), Color("#5c3a1c"), false, 4.0)
	if open:
		draw_rect(Rect2(-40, -78, 80, 16), Color("#6e4522"))
		draw_circle(Vector2(0, -40), 12, Color("#ffe08a"))
	else:
		var lid := PackedVector2Array()
		for i in range(13):
			var ang := PI + i * PI / 12.0
			lid.append(Vector2(cos(ang) * 40, -36 + sin(ang) * 22))
		draw_polygon(lid, _solid(lid.size(), Color("#6e4522")))
		draw_rect(Rect2(-6, -44, 12, 14), Color("#d8a12c"))


func _solid(n: int, col: Color) -> PackedColorArray:
	var cols := PackedColorArray()
	for i in range(n):
		cols.append(col)
	return cols

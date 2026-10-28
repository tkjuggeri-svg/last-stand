class_name GatePainter
## The gates where the roads begin on each map (M15 P4), 96x96 world cells, the feet at (0, 0): the Ember Orchard's burnt
## arch, the Bone Quarry's cut-stone mouth, the Frostbound Pass's ice-hung arch, the Gloam Wood's root arch, the Ashen Keep's
## broken gate, the Sunless Mines' timbered adit, the Pale Cathedral's white doorway, and the marsh's flooded chapel. Each has a
## dark mouth lit from inside (the level adds a PointLight2D on top); the lit colour is baked in as a halo.

const MOUTH: Color = Color("0b0a10")


static func paint(ci: CanvasItem, biome: String) -> void:
	VectorStyle.shadow(ci, Vector2(0, 2), 40.0, 8.0)
	match biome:
		"ember_orchard":
			_orchard(ci)
		"bone_quarry":
			_quarry(ci)
		"frostbound_pass":
			_frost(ci)
		"gloam_wood":
			_roots(ci)
		"ashen_keep":
			_keep(ci)
		"sunless_mines":
			_adit(ci)
		"pale_cathedral":
			_cathedral(ci)
		"drowned_marsh":
			_chapel(ci)


## A rounded-top doorway opening, `w` wide and `h` tall, filled dark.
static func _opening(ci: CanvasItem, w: float, h: float, glow: Color, round_top: bool = true) -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-w, 0), Vector2(-w, -h + w)])
	if round_top:
		for i: int in 9:
			var a: float = PI + i * PI / 8.0
			pts.append(Vector2(cos(a) * w, -h + w + sin(a) * w))
	else:
		pts.append(Vector2(-w, -h))
		pts.append(Vector2(w, -h))
	pts.append(Vector2(w, -h + w))
	pts.append(Vector2(w, 0))
	VectorPaint.fill(ci, pts, MOUTH)
	VectorStyle.draw_glow(ci, glow, Vector2(0, -h * 0.4), h * 0.9, 0.5)
	VectorStyle.draw_glow(ci, glow, Vector2(0, -h * 0.25), h * 0.4, 0.4)


static func _blocks(ci: CanvasItem, rect: Rect2, color: Color, seed_value: int) -> void:
	VectorPaint.painted(ci, PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), color, 3.4, 0.5, 1.4)
	var rows: int = int(rect.size.y / 8.0)
	for row: int in rows:
		var y: float = rect.end.y - 4.0 - row * 8.0
		VectorPaint.line(ci, Vector2(rect.position.x + 1, y), Vector2(rect.end.x - 1, y), Color(PropKit.INK, 0.4), 0.9)
		var off: float = 4.0 if (row + seed_value) % 2 == 0 else -2.0
		VectorPaint.line(ci, Vector2(rect.position.x + rect.size.x * 0.5 + off, y), Vector2(rect.position.x + rect.size.x * 0.5 + off, y - 8.0), Color(PropKit.INK, 0.3), 0.8)


static func _orchard(ci: CanvasItem) -> void:
	_opening(ci, 16.0, 46.0, Color("ff8a30"))
	for x: float in [-22.0, 22.0]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 5, 0), Vector2(x + 5, 0), Vector2(x + 4, -62), Vector2(x - 4, -62)]), Color("2b2420"), 3.0, 0.4, 1.4)
		VectorPaint.line(ci, Vector2(x - 3, -2), Vector2(x - 2, -60), Color(1, 1, 1, 0.1), 1.2)
	PropKit.beam(ci, Vector2(-28, -60), Vector2(28, -60), 5.0, Color("2b2420"))
	PropKit.beam(ci, Vector2(-26, -50), Vector2(-14, -60), 3.0, Color("2b2420"))
	PropKit.beam(ci, Vector2(26, -50), Vector2(14, -60), 3.0, Color("2b2420"))
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-9, -60), Vector2(9, -60), Vector2(9, -50), Vector2(-9, -50)]), Color("5a3a22"), 1.4, 0.3, 1.1)
	for p: Vector2 in [Vector2(-30, -64), Vector2(26, -66), Vector2(8, -70), Vector2(-14, -68)]:
		VectorStyle.draw_glow(ci, PropKit.EMBER, p, 5.0, 0.7)
		ci.draw_circle(p, 1.7, Color("ff5a20"), true, -1.0, true)
	for k: int in 5:
		VectorStyle.draw_glow(ci, PropKit.EMBER, Vector2(-8 + k * 4.0, -4 - (k % 2) * 2.0), 3.0, 0.8)


static func _quarry(ci: CanvasItem) -> void:
	_blocks(ci, Rect2(-40, -50, 80, 50), Color("8b8170"), 1)
	_opening(ci, 17.0, 36.0, Color("ffb060"), false)
	for k: int in 6:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-19 + k * 6.4, -37), Vector2(-13 + k * 6.4, -37), Vector2(-14 + k * 6.4, -43), Vector2(-18 + k * 6.4, -43)]), Color("a09680").darkened((k % 2) * 0.1), 0.8, 0.3, 0.8)
	PropKit.post(ci, 34.0, 78.0, 3.4)
	PropKit.beam(ci, Vector2(34, -76), Vector2(-14, -70), 3.6)
	VectorPaint.line(ci, Vector2(-10, -70), Vector2(-10, -56), PropKit.IRON_LIGHT, 1.2)
	PropKit.bones(ci, Vector2(-30, 0), 0.9)
	PropKit.bones(ci, Vector2(30, -1), 0.8)


static func _frost(ci: CanvasItem) -> void:
	for x: float in [-26.0, 26.0]:
		_blocks(ci, Rect2(x - 9, -62, 18, 62), Color("7d8794"), 2)
	_opening(ci, 18.0, 46.0, Color("8fd0f0"))
	var arch: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var a: float = PI + i * PI / 12.0
		arch.append(Vector2(cos(a) * 28.0, -52.0 + sin(a) * 26.0))
	for i: int in range(12, -1, -1):
		var a: float = PI + i * PI / 12.0
		arch.append(Vector2(cos(a) * 18.0, -52.0 + sin(a) * 16.0))
	VectorPaint.painted(ci, arch, Color("8a94a2"), 3.0, 0.5, 1.4)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-32, -62), Vector2(-16, -76), Vector2(16, -76), Vector2(32, -62), Vector2(22, -60), Vector2(0, -68), Vector2(-22, -60)]), PropKit.SNOW, 2.0, 0.4, 1.0)
	for k: int in 8:
		var x: float = -20.0 + k * 5.6
		_icicle(ci, x, -60.0 + absf(x) * 0.18, 9.0 + (k % 3) * 5.0)


static func _icicle(ci: CanvasItem, x: float, y: float, length: float) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 2.0, y), Vector2(x + 2.0, y), Vector2(x, y + length)]), Color("cfeeff"), 0.8, 0.5, 0.8)


static func _roots(ci: CanvasItem) -> void:
	_opening(ci, 18.0, 46.0, Color("a8f0c8"))
	for side: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(side * 24, 0), Vector2(side * 28, -34), Vector2(side * 14, -64), 11.0, Color("3d2e22"))
		VectorPaint.strand(ci, Vector2(side * 34, 0), Vector2(side * 36, -22), Vector2(side * 24, -44), 6.0, Color("4a3a2c"))
		VectorPaint.strand(ci, Vector2(side * 14, -62), Vector2(side * 4, -72), Vector2(side * -8, -66), 8.0, Color("3d2e22"))
	for k: int in 7:
		VectorPaint.strand(ci, Vector2(-16 + k * 5.4, -62), Vector2(-16 + k * 5.4 + 1, -54), Vector2(-16 + k * 5.4, -44 - (k % 3) * 5.0), 2.2, Color("2f5a3c"))
	for p: Vector2 in [Vector2(-30, -6), Vector2(32, -4), Vector2(-22, -10)]:
		PropKit.glow_mushroom(ci, p, 6.0, Color("57e0b8"))


static func _keep(ci: CanvasItem) -> void:
	for x: float in [-30.0, 30.0]:
		var h: float = 66.0 if x < 0 else 48.0
		_blocks(ci, Rect2(x - 12, -h, 24, h), Color("5e5750"), 3)
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 14, -h), Vector2(x + 14, -h), Vector2(x + 10, -h - 4), Vector2(x - 12, -h - 6)]), Color("4a443e"), 1.2, 0.3, 1.0)
	_opening(ci, 17.0, 44.0, Color("ff6a30"))
	for k: int in 5:
		VectorPaint.line(ci, Vector2(-14 + k * 7.0, -44), Vector2(-14 + k * 7.0, -22 - (k % 2) * 8.0), PropKit.IRON_LIGHT, 2.0)
	PropKit.pile(ci, Vector2(-8, 0), 14.0, 8.0, Color("5e5750"), 14)
	VectorStyle.draw_glow(ci, PropKit.EMBER, Vector2(0, -26), 30.0, 0.35)


static func _adit(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-44, 0), Vector2(-40, -44), Vector2(-20, -64), Vector2(20, -64), Vector2(40, -44), Vector2(44, 0)]), Color("45414f"), 4.0, 0.45, 1.4)
	_opening(ci, 18.0, 44.0, Color("b58cff"), false)
	PropKit.post(ci, -21.0, 48.0, 3.4)
	PropKit.post(ci, 21.0, 48.0, 3.4)
	PropKit.beam(ci, Vector2(-25, -46), Vector2(25, -46), 4.4)
	_hung_lamp(ci)
	for x: float in [-9.0, 9.0]:
		VectorPaint.line(ci, Vector2(x, 2), Vector2(x * 1.4, 10), PropKit.IRON_LIGHT, 1.6)
	VectorPaint.line(ci, Vector2(-18, 8), Vector2(18, 8), PropKit.IRON_LIGHT, 1.2)


static func _hung_lamp(ci: CanvasItem) -> void:
	VectorPaint.line(ci, Vector2(0, -46), Vector2(0, -38), PropKit.IRON, 1.2)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-3.4, -38), Vector2(3.4, -38), Vector2(3, -30), Vector2(-3, -30)]), PropKit.IRON, 0.8, 0.3, 1.0)
	VectorPaint.fill(ci, PackedVector2Array([Vector2(-2, -37), Vector2(2, -37), Vector2(1.6, -31), Vector2(-1.6, -31)]), Color("ffc96a"))
	VectorStyle.draw_glow(ci, Color("ffc96a"), Vector2(0, -34), 16.0, 0.5)


static func _cathedral(ci: CanvasItem) -> void:
	for x: float in [-30.0, 30.0]:
		PropKit.pillar(ci, Vector2(x, 0), 8.0, 62.0, Color("c8c6d6"))
	_blocks(ci, Rect2(-24, -66, 48, 66), Color("b8b6c8"), 4)
	_opening(ci, 15.0, 46.0, Color("e4d4ff"))
	var arch: PackedVector2Array = PackedVector2Array([Vector2(-34, -62), Vector2(-18, -80), Vector2(0, -92), Vector2(18, -80), Vector2(34, -62), Vector2(24, -62), Vector2(0, -80), Vector2(-24, -62)])
	VectorPaint.painted(ci, arch, Color("d8d6e6"), 3.0, 0.5, 1.4)
	var rose: Vector2 = Vector2(0, -68)
	ci.draw_circle(rose, 8.0, Color("2a2540"), true, -1.0, true)
	for k: int in 8:
		var a: float = k * TAU / 8.0
		ci.draw_line(rose, rose + Vector2.from_angle(a) * 7.0, Color("b58cff") if k % 2 else Color("57b8e0"), 1.4, true)
	ci.draw_arc(rose, 8.0, 0.0, TAU, 20, Color("d8d6e6"), 1.4, true)
	VectorStyle.draw_glow(ci, Color("b58cff"), rose, 16.0, 0.4)


static func _chapel(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(34, -48), Vector2(-34, -48)]), Color("6a7a78"), 4.0, 0.45, 1.4)
	for row: int in 5:
		VectorPaint.line(ci, Vector2(-33, -8 - row * 8.0), Vector2(33, -8 - row * 8.0), Color(PropKit.INK, 0.4), 0.9)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-38, -48), Vector2(38, -48), Vector2(0, -74)]), Color("4a5a58"), 4.0, 0.5, 1.4)
	_opening(ci, 13.0, 36.0, Color("7affc8"))
	PropKit.post(ci, 26.0, 78.0, 2.4)
	ci.draw_circle(Vector2(26, -80), 3.0, Color("c9a74a"), true, -1.0, true)
	for k: int in 5:
		PropKit.moss_tuft(ci, Vector2(-30 + k * 14.0, -1), 1.6, Color("4a8a58"))
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -1), 40.0, 5.0, 20), Color(0.16, 0.3, 0.3, 0.55), 1.0, 0.2, 0.0)

class_name TowerPainter
## Paints a base tower's sheet frames (M15, sheet_layouts.gd TOWERS): the animation name is "<tower>_<state>[_<level>]"
## with the state idle, fire, build or sell; level 1 has no suffix. Each tower has its own painter (paint(ci, level, t,
## fire)); this routes to it and adds the two shared states: build (the tower rises on a wooden scaffold, dust at its
## foot) and sell (it crumbles into a pile of stone and timber). Display only.

const SCALE: float = 1.0
const PAINTERS: Dictionary = {
	"archer": "ArcherPainter", "cannon": "CannonTowerPainter", "frost": "FrostTowerPainter",
	"brazier": "BrazierTowerPainter", "ballista": "BallistaTowerPainter",
}
const WOOD: Color = Color("86592f")
const WOOD_DARK: Color = Color("4a2e1c")
const RUBBLE: Color = Color("847a6e")
const DUST: Color = Color("cdbfa8")


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	# "trap_layer_fire_2": the id may hold underscores, a trailing number is the level and the word before it the state.
	var parts: PackedStringArray = anim.split("_")
	var level: int = 1
	if parts[parts.size() - 1].is_valid_int():
		level = int(parts[parts.size() - 1])
		parts.remove_at(parts.size() - 1)
	var state: String = parts[parts.size() - 1]
	parts.remove_at(parts.size() - 1)
	var id: String = "_".join(parts)
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	match state:
		"idle":
			_paint(id, ci, level, cycle, -1.0)
		"fire":
			_paint(id, ci, level, 0.25, progress)
		"build":
			_build(id, ci, progress)
		"sell":
			_sell(id, ci, progress)


static func _paint(id: String, ci: CanvasItem, level: int, t: float, fire: float) -> void:
	match id:
		"archer":
			ArcherPainter.paint(ci, level, t, fire)
		"cannon":
			CannonTowerPainter.paint(ci, level, t, fire)
		"frost":
			FrostTowerPainter.paint(ci, level, t, fire)
		"brazier":
			BrazierTowerPainter.paint(ci, level, t, fire)
		"ballista":
			BallistaTowerPainter.paint(ci, level, t, fire)
		"trap_layer":
			HuntressTowerPainter.paint_trap_layer(ci, level, t, fire)
		"hawk_perch":
			HuntressTowerPainter.paint_hawk_perch(ci, level, t, fire)
		"watchtower":
			HuntressTowerPainter.paint_watchtower(ci, level, t, fire)
		"bone_pit":
			NecroTowerPainter.paint_bone_pit(ci, level, t, fire)
		"soul_siphon":
			NecroTowerPainter.paint_soul_siphon(ci, level, t, fire)
		"ossuary":
			NecroTowerPainter.paint_ossuary(ci, level, t, fire)


## The tower grows up from its foot (eased, slightly overshooting) inside a scaffold; the scaffold comes down at the end.
static func _build(id: String, ci: CanvasItem, progress: float) -> void:
	var grow: float = clampf(VectorStyle.ease_out_back(clampf(progress / 0.85, 0.0, 1.0)), 0.0, 1.06)
	VectorStyle.shadow(ci, Vector2(3, 5), 28, 10.5)
	if grow > 0.04:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, grow))
		ci.modulate = Color(1, 1, 1, clampf(progress * 6.0, 0.0, 1.0))
		_paint(id, ci, 1, 0.0, -1.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ci.modulate = Color.WHITE
	var scaffold: float = 1.0 - smoothstep(0.78, 1.0, progress)
	if scaffold > 0.0:
		_scaffold(ci, maxf(grow, 0.25) * 58.0, scaffold)
	if progress < 0.9:
		_dust(ci, Vector2(0, 2), progress, 1.0)


static func _scaffold(ci: CanvasItem, height: float, alpha: float) -> void:
	var color: Color = Color(WOOD, alpha)
	for x: float in [-22.0, 22.0]:
		ci.draw_line(Vector2(x, 2), Vector2(x * 0.92, -height), Color(WOOD_DARK, alpha), 2.6, true)
		ci.draw_line(Vector2(x, 2), Vector2(x * 0.92, -height), color, 1.6, true)
	var rungs: int = int(height / 16.0)
	for k: int in rungs:
		var y: float = -8.0 - k * 16.0
		ci.draw_line(Vector2(-22.0 * 0.96, y), Vector2(22.0 * 0.96, y), Color(WOOD_DARK, alpha), 2.2, true)
		ci.draw_line(Vector2(-22.0 * 0.96, y), Vector2(22.0 * 0.96, y), color, 1.2, true)
	if height > 18.0:
		ci.draw_line(Vector2(-22, 2), Vector2(18, -height * 0.7), Color(color, alpha * 0.7), 1.0, true)


## The tower collapses: it sinks and breaks apart into a pile of blocks, dust rolling out.
static func _sell(id: String, ci: CanvasItem, progress: float) -> void:
	var fall: float = smoothstep(0.0, 0.6, progress)
	VectorStyle.shadow(ci, Vector2(3, 5), 28, 10.5)
	if fall < 0.98:
		ci.draw_set_transform(Vector2(0, fall * 6.0), 0.0, Vector2(1.0 + fall * 0.12, 1.0 - fall))
		ci.modulate = Color(1, 1, 1, 1.0 - smoothstep(0.35, 0.7, progress))
		_paint(id, ci, 1, 0.0, -1.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ci.modulate = Color.WHITE
	_rubble(ci, smoothstep(0.1, 0.8, progress))
	_dust(ci, Vector2(0, -2), progress, 1.4)


static func _rubble(ci: CanvasItem, amount: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	for i: int in 14:
		var spread: float = rng.randf_range(-24.0, 24.0)
		var at: Vector2 = Vector2(spread * (0.4 + amount * 0.6), rng.randf_range(-3.0, 5.0) - amount * rng.randf_range(0.0, 7.0))
		var size: float = rng.randf_range(2.2, 5.4)
		var a: float = rng.randf() * TAU
		var block: PackedVector2Array = PackedVector2Array([at + Vector2(-size, -size * 0.6).rotated(a), at + Vector2(size, -size * 0.7).rotated(a),
			at + Vector2(size * 0.8, size * 0.6).rotated(a), at + Vector2(-size * 0.9, size * 0.7).rotated(a)])
		VectorPaint.painted(ci, block, RUBBLE.lerp(Color("5a5149"), rng.randf() * 0.5), size * 0.4, 0.4, 0.8)
	for i: int in 3:
		var x: float = -14.0 + i * 14.0
		VectorPaint.line(ci, Vector2(x, 2), Vector2(x + 6.0, -4.0 - amount * 3.0), WOOD, 2.2)


static func _dust(ci: CanvasItem, at: Vector2, progress: float, spread: float) -> void:
	for i: int in 8:
		var a: float = i * TAU / 8.0 + 0.3
		var k: float = clampf(progress * 1.3 - i * 0.04, 0.0, 1.0)
		var p: Vector2 = at + Vector2(cos(a) * 26.0 * k * spread, sin(a) * 9.0 * k * spread - k * 8.0)
		ci.draw_circle(p, 3.0 + k * 6.0, Color(DUST, 0.35 * (1.0 - k)), true, -1.0, true)

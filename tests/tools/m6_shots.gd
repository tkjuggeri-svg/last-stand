extends RefCounted
## The "m6" screenshot scenario of capture_screenshots.gd (kept apart so that script stays short):
## the dash (afterimages, the HUD cooldown row, the Cinder Dash trail).
## `--only=dash` (comma-separated) runs just some parts.

const CINDER_DASH: UpgradeData = preload("res://data/upgrades/cinder_dash.tres")

## The capture tool (a SceneTree script): its _shot(), _frames() and _frame_camera().
var _tool: SceneTree
var _only: PackedStringArray


func _init(tool: SceneTree, only: PackedStringArray) -> void:
	_tool = tool
	_only = only


func run(level: Level) -> void:
	WaveFixtures.no_upgrades(level)
	if _wants("dash"):
		await _dash(level)


func _wants(part: String) -> bool:
	return _only.is_empty() or _only.has(part)


func _dash(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	hero.global_position = Vector2(-260, 110)
	_tool.call("_frame_camera", camera, Vector2(-200, 90), 2.0, true)
	await _tool.call("_frames", 20)
	hero.dash(Vector2.RIGHT)
	await _tool.call("_frames", 7)
	await _tool.call("_shot", "m6_01_dash_afterimages")
	_tool.call("_frame_camera", camera, Vector2.ZERO, 1.0, false)
	await _tool.call("_frames", 20)
	await _tool.call("_shot", "m6_02_hud_dash_cooldown")
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(CINDER_DASH)
	await _tool.call("_frames", 130)
	hero.global_position = Vector2(-300, 110)
	_tool.call("_frame_camera", camera, Vector2(-220, 90), 2.0, true)
	hero.dash(Vector2.RIGHT)
	await _tool.call("_frames", 16)
	await _tool.call("_shot", "m6_03_cinder_dash_trail")

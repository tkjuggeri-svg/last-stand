extends SceneTree
## The vector art lineup (M15): each enemy in a row on the graveyard at game scale (the sprite where the game puts it:
## the enemy's data sprite_offset): idle facing down, up and side, a walk step, mid-attack, and the death's last frame.
## --towers=archer,cannon,... shows the base towers instead (level 1-3 idle, a shot, a build step, a sell step), at the
## sprite position the tower scene uses.
## godot --path . --resolution 1280x720 --script res://tests/tools/m15_lineup.gd -- [--out=dev_screenshots/m15] [--enemies=ghoul,hound,brute,cultist] [--towers=archer,cannon] [--zoom=2]
## Needs a window (the level draws). Display only.

const ARENA: String = "res://levels/prototype_arena.tscn"
const COLUMN_WIDTH: float = 78.0
const ROW_HEIGHT: float = 86.0
## Per column: the animation, the share of it shown (0..1), and a label.
const CELLS: Array = [["idle_down", 0.0], ["idle_up", 0.0], ["idle_side", 0.0], ["walk_side", 0.3], ["attack_side", 0.7], ["death", 1.0]]
## The tower row: the animation name pattern ("%s" is the tower id) and the share of it shown.
const TOWER_CELLS: Array = [["%s_idle", 0.0], ["%s_idle_2", 0.0], ["%s_idle_3", 0.0], ["%s_fire", 0.3], ["%s_fire_3", 0.5], ["%s_build", 0.5], ["%s_sell", 0.45]]
const TOWER_SPRITE_OFFSET: Vector2 = Vector2(0, -44)
const TOWER_COLUMN_WIDTH: float = 100.0
const TOWER_ROW_HEIGHT: float = 110.0

var _out: String = "dev_screenshots/m15"
var _enemies: PackedStringArray = PackedStringArray(["ghoul", "hound", "brute", "cultist"])
var _zoom: float = 2.0
var _towers: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--enemies="):
			_enemies = arg.trim_prefix("--enemies=").split(",")
		elif arg.begins_with("--zoom="):
			_zoom = float(arg.trim_prefix("--zoom="))
		elif arg.begins_with("--towers="):
			_towers = arg.trim_prefix("--towers=").split(",")
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	root.add_child(level)
	await _wait(3)
	(level.get_node("WaveSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var hero: Hero = level.get_node("Hero")
	hero.hide()
	var origin: Vector2 = Vector2(-330, -90)
	if not _towers.is_empty():
		_enemies = PackedStringArray()
		origin = Vector2(-380, -150)
		hero.position = origin + Vector2(TOWER_COLUMN_WIDTH * TOWER_CELLS.size() * 0.5, TOWER_ROW_HEIGHT * _towers.size() * 0.5)
		for row: int in _towers.size():
			var frames: SpriteFrames = load("res://entities/towers/tower_frames.tres")
			for column: int in TOWER_CELLS.size():
				var sprite: SheetSprite = SheetSprite.new()
				sprite.sprite_frames = frames
				var anim: StringName = StringName(String(TOWER_CELLS[column][0]) % _towers[row])
				sprite.animation = anim
				var count: int = frames.get_frame_count(anim)
				sprite.frame = clampi(int(float(TOWER_CELLS[column][1]) * (count - 1)), 0, count - 1)
				sprite.position = origin + Vector2(TOWER_COLUMN_WIDTH * (column + 0.5), TOWER_ROW_HEIGHT * (row + 0.5) + 12.0) + TOWER_SPRITE_OFFSET
				level.add_child(sprite)
				sprite.pause()
	else:
		hero.position = origin + Vector2(COLUMN_WIDTH * CELLS.size() * 0.5, ROW_HEIGHT * _enemies.size() * 0.5)
	for row: int in _enemies.size():
		var data: EnemyData = load("res://data/enemies/%s.tres" % _enemies[row])
		for column: int in CELLS.size():
			var sprite: DirectionalSprite = DirectionalSprite.new()
			sprite.sprite_frames = data.sprite_frames
			var cell: Array = CELLS[column]
			var anim: StringName = StringName(cell[0])
			sprite.animation = anim
			var count: int = data.sprite_frames.get_frame_count(anim)
			sprite.frame = clampi(int(float(cell[1]) * (count - 1)), 0, count - 1)
			sprite.position = origin + Vector2(COLUMN_WIDTH * (column + 0.5), ROW_HEIGHT * (row + 0.5)) + data.sprite_offset
			level.add_child(sprite)
			sprite.pause()
			if cell[0] == "idle_side" or String(cell[0]).ends_with("_side"):
				sprite.flip_h = false
	var camera: Camera2D = hero.get_node("Camera2D")
	camera.zoom = Vector2(_zoom, _zoom)
	await _wait(4)
	var path: String = "%s/lineup_%s.png" % [_out, "_".join(_enemies if _towers.is_empty() else _towers)]
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
	quit()


func _wait(count: int) -> void:
	for i: int in count:
		await process_frame

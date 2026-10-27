extends SceneTree
## The vector look test (branch vector-test, never merge): plays the same scripted moment in the graveyard twice,
## once in today's pixel art and once with VectorSkin (the Knight, Ghouls, Archer towers and the ground in the
## style of docs/reference/web_td/), and saves both side by side: the whole view, and a 2x close-up at the Knight.
## godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/vector_style_compare.gd -- [--out=dev_screenshots/vector_test] [--parts=ground,knight,ghoul,archer] [--live-ground]

const ARENA: String = "res://levels/prototype_arena.tscn"
const GHOUL: String = "res://data/enemies/ghoul.tres"
## Where the Knight waits: this share of the west road's length, this far beside it.
const LANE_SHARE: float = 0.38
const HERO_OFFSET: float = 34.0
const ARCHERS: int = 4
const GHOUL_TOUGHNESS: float = 25.0
const REACH: float = 60.0
## Frames after the swing starts when the shots are taken (mid-swing), and the longest the moment may take.
const SWING_FRAMES: int = 5
const MAX_FRAMES: int = 2400
const MEASURE_FRAMES: int = 600

var _out: String = "dev_screenshots/vector_test"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--live-ground":
			VectorSkin.bake_ground = false
		elif arg.begins_with("--parts="):
			VectorSkin.parts.assign(arg.trim_prefix("--parts=").split(","))
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	var pixel: Array[Image] = await _play(false)
	var vector: Array[Image] = await _play(true)
	_save_pair(pixel[0], vector[0], "compare_view")
	_save_pair(pixel[1], vector[1], "compare_closeup")
	print("saved %s/compare_view.png and compare_closeup.png" % _out)
	quit()


## One run of the scripted moment; returns [the whole view, the close-up]. The Knight stands beside the west road
## (LANE_SHARE of the way along it) with a few Archers near; when the first Ghoul comes within reach he walks in a
## step and swings, and the shots are taken mid-swing. The same seed and fixed frame rate make both runs alike.
func _play(vector: bool) -> Array[Image]:
	seed(4242)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [_ghoul_wave(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	if vector:
		VectorSkin.apply(level)
	var label: CanvasLayer = _label("Vector test (shapes, gradients, glow)" if vector else "Pixel art (current)")
	await _wait(3)
	(level.get_node("Fortress") as Fortress).health.setup(100000)
	var lane: PackedVector2Array = (level.get_node("Lane") as Path2D).curve.get_baked_points()
	var at: int = int(lane.size() * LANE_SHARE)
	var road: Vector2 = level.to_global(lane[at])
	var normal: Vector2 = (lane[at + 1] - lane[at - 1]).normalized().orthogonal()
	var hero: Hero = level.get_node("Hero")
	hero.health.setup(100000)
	hero.global_position = road + normal * HERO_OFFSET
	(level.get_node("%Economy") as Economy).earn(100000, Economy.Source.KILL)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var archer: TowerData = null
	for data: TowerData in builder.catalog:
		if data.id == &"archer":
			archer = data
	var slots: Array[BuildSlot] = builder.get_slots().duplicate()
	slots.sort_custom(func(x: BuildSlot, y: BuildSlot) -> bool: return x.global_position.distance_to(road) < y.global_position.distance_to(road))
	var built: int = 0
	for slot: BuildSlot in slots.slice(0, ARCHERS):
		if builder.build(slot, archer):
			built += 1
	await _wait(60)
	for i: int in built:
		for _u: int in i % 3:
			builder.upgrade(slots[i])
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	var capture_at: int = -1
	for frame: int in MAX_FRAMES:
		var target: Enemy = _nearest(level, hero.global_position)
		if capture_at < 0 and target != null:
			hero.attack(target.global_position)
			capture_at = frame + SWING_FRAMES
		if frame == capture_at:
			break
		await physics_frame
	await process_frame
	var shots: Array[Image] = [get_root().get_texture().get_image()]
	var camera: Camera2D = hero.get_node("Camera2D")
	camera.zoom = Vector2(2, 2)
	await _wait(1)
	shots.append(get_root().get_texture().get_image())
	camera.zoom = Vector2.ONE
	var ms: float = await _frame_time()
	print("%s: %d archers, %d ghouls on the field, captured at frame %d; %.2f ms a frame (vsync off, %d frames after)" % [
		"vector" if vector else "pixel", built, _count_ghouls(level), capture_at, ms, MEASURE_FRAMES])
	label.queue_free()
	level.queue_free()
	await _wait(2)
	return shots


## Average real time per frame over MEASURE_FRAMES frames of the fight going on (vsync off), in ms.
func _frame_time() -> float:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _wait(10)
	var start: int = Time.get_ticks_usec()
	await _wait(MEASURE_FRAMES)
	return (Time.get_ticks_usec() - start) / 1000.0 / MEASURE_FRAMES


func _ghoul_wave() -> WaveData:
	var wave: WaveData = WaveData.new()
	var ghoul: EnemyData = load(GHOUL)
	for lane: int in 3:
		var group: SpawnGroup = SpawnGroup.new()
		group.enemy = ghoul
		group.count = 14
		group.interval = 0.7
		group.lane = lane
		group.health_scale = GHOUL_TOUGHNESS  # the staged moment needs Ghouls alive near the Knight, past the Archers
		group.delay = lane * 0.3
		wave.groups.append(group)
	return wave


func _nearest(level: Level, at: Vector2) -> Enemy:
	var best: Enemy = null
	for node: Node in level.get_node("WaveSpawner").get_children():
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(at) < REACH and (best == null or enemy.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = enemy
	return best


func _count_ghouls(level: Level) -> int:
	var count: int = 0
	for node: Node in level.get_node("WaveSpawner").get_children():
		if node is Enemy and not node.is_queued_for_deletion():
			count += 1
	return count


func _label(text: String) -> CanvasLayer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 60
	var box: Label = Label.new()
	box.text = text
	box.theme_type_variation = &"HeaderLabel"
	box.position = Vector2(440, 12)
	layer.add_child(box)
	root.add_child(layer)
	return layer


func _save_pair(left: Image, right: Image, file: String) -> void:
	left.save_png("%s/%s_pixel.png" % [_out, file])
	right.save_png("%s/%s_vector.png" % [_out, file])
	var pair: Image = Image.create(left.get_width() + right.get_width() + 8, left.get_height(), false, left.get_format())
	pair.fill(Color("1a141f"))
	pair.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
	pair.blit_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(left.get_width() + 8, 0))
	pair.save_png("%s/%s.png" % [_out, file])


func _wait(count: int) -> void:
	for i: int in count:
		await process_frame

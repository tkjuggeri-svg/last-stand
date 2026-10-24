extends SceneTree
## Screenshots for reviewing world art in play (the art pack integration, docs/ART_HANDOFF.md): a
## Crypt Road fight with every tower type (levels 1-3 and evolutions), a late wave and the four
## bosses; then the Drowned Marsh. Run at several window sizes to see the scaling:
## godot --path . --resolution 1920x1080 --script res://tests/tools/art_review_shots.gd -- --out=<dir> [--tag=1080p]

const TOWERS: Array[String] = ["archer", "cannon", "frost", "brazier", "ballista"]
const BOSSES: Array[String] = ["gravelord", "colossus", "lich", "tollkeeper"]

var _out: String = "user://art_review"
var _tag: String = ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = "_" + arg.trim_prefix("--tag=")
	DirAccess.make_dir_recursive_absolute(_out)
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	var waves: Array[WaveData] = [load("res://data/waves/wave_12.tres")]
	(level.get_node("WaveSpawner") as WaveSpawner).waves = waves
	root.add_child(level)
	await _frames(5)
	level.economy.earn(50000, Economy.Source.REFUND)
	var slots: Array[BuildSlot] = level.builder.get_slots()
	for i: int in slots.size():
		var data: TowerData = load("res://data/towers/%s.tres" % TOWERS[i % TOWERS.size()])
		level.builder.build(slots[i], data)
	await _frames(120)
	for i: int in slots.size():
		if slots[i].tower == null:
			continue
		for _u: int in mini(i % 4, 2):
			level.builder.upgrade(slots[i])
			await _frames(2)
		if i >= 5:
			level.builder.upgrade(slots[i])
			await _frames(2)
			level.builder.upgrade(slots[i])
			await _frames(2)
			level.builder.evolve(slots[i], i % 2)
	var hero: Hero = level.get_node("Hero")
	hero.global_position = Vector2(-240, -40)
	level.run_cycle.start_wave()
	await _frames(60 * 9)
	await _shot("fight_crypt_road")
	for i: int in BOSSES.size():
		var boss: Enemy = level.spawner.spawn_extra(load("res://data/enemies/%s.tres" % BOSSES[i]), i % 3)
		boss.global_position = hero.global_position + Vector2(-260 + i * 170, -120)
	await _frames(40)
	await _shot("bosses")
	level.queue_free()
	await _frames(3)
	var marsh: Level = (load("res://levels/drowned_marsh.tscn") as PackedScene).instantiate()
	(marsh.get_node("WaveSpawner") as WaveSpawner).waves = [load("res://data/waves/chapter_2/wave_10.tres")]
	root.add_child(marsh)
	await _frames(5)
	(marsh.get_node("Hero") as Node2D).global_position = Vector2(-300, 0)
	marsh.run_cycle.start_wave()
	await _frames(60 * 14)
	await _shot("fight_drowned_marsh")
	quit()


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(shot_name + _tag + ".png"))
	print("saved ", shot_name + _tag)

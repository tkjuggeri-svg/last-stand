extends SceneTree
## Screenshots of the three ultimates in a real window: the HUD row (charging, then ready), and each effect a moment after use,
## with a crowd of ghouls in front of the hero.
## godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/ultimate_shots.gd -- --out=<dir>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const HEROES: Array[HeroData] = [preload("res://data/heroes/knight.tres"), preload("res://data/heroes/huntress.tres"), preload("res://data/heroes/necromancer.tres")]

var _out: String = "user://shots"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	for hero_data: HeroData in HEROES:
		await _hero(hero_data)
	quit()


func _hero(hero_data: HeroData) -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var hero: Hero = level.get_node("Hero")
	hero.data = hero_data
	root.add_child(level)
	level.apply_hero(hero_data, HEROES)
	await _frames(10)
	var key: String = String(hero_data.id)
	var origin: Vector2 = hero.global_position
	for i: int in 10:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.data = GHOUL
		enemy.position = origin + Vector2(90 + (i % 5) * 38, (floori(i / 5.0) - 0.5) * 60 + 80)
		level.add_child(enemy)
		enemy.get_health().max_health = 400
		enemy.get_health().current_health = 400
		enemy.set_physics_process(false)
	await _frames(20)
	await _shot(key + "_1_charging")
	hero.get_ultimate().add_charge(1000.0)
	await _frames(15)
	await _shot(key + "_2_ready")
	level.get_node("UltimateRunner").aim_override = Vector2(1, 0.5)
	hero.get_ultimate().use()
	await _frames(8)
	await _shot(key + "_3_used")
	await _frames(60)
	await _shot(key + "_4_after")
	level.queue_free()
	await _frames(5)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(shot_name + ".png"))
	print("saved ", shot_name)

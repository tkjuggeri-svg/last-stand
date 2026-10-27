extends SceneTree
## Plays the trailer's montage (M13) in the real game window and saves PNG frames plus a text storyboard
## (docs/TRAILER.md is the shot list). Needs a display (not --headless):
##   godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/trailer_capture.gd -- --out=<dir> [--only=title,knight,boss,ending]
## Shots: the title; each hero's towers in a late wave of a biome (three frames over the fight); a boss
## fight; an ending. Everything is played on throwaway levels with an unbreakable fortress, so the frames
## show the game at its fullest. Frames are numbered in storyboard order (01_title.png, ...).

const SETS: Array = [
	["knight", "crypt_road", "The Knight on the Crypt Road: the dead pour down the lane."],
	["huntress", "frostbound_pass", "The Huntress in the Frostbound Pass: snares and arrows in the blizzard."],
	["necromancer", "pale_cathedral", "The Necromancer in the Pale Cathedral: skeletons against the choir."],
]
const BOSS_BIOME: String = "ashen_keep"
## Frames to wait before each frame of a fight is saved (at 60 fps: 3, 7 and 11 seconds in).
const FIGHT_FRAMES: Array[int] = [180, 240, 240]
const TOWERS: Array[int] = [0, 2, 3, 0, 4, 2, 0, 1, 2, 4]  # catalog index per slot, as perf_report.gd

var _out: String = "user://trailer"
var _only: PackedStringArray = PackedStringArray()
var _number: int = 0
var _storyboard: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	if _wants("title"):
		await _title()
	var run: RunData = load("res://data/run/run.tres")
	for entry: Array in SETS:
		if _wants(entry[0]):
			await _fight(run, run.get_hero(entry[0]), run.find_chapter(StringName(entry[1])), false, entry[2])
	if _wants("boss"):
		await _fight(run, run.get_hero("knight"), run.find_chapter(StringName(BOSS_BIOME)), true, "The Fallen Marshal holds the keep.")
	if _wants("ending"):
		await _ending()
	var file: FileAccess = FileAccess.open(ProjectSettings.globalize_path(_out.path_join("storyboard.txt")), FileAccess.WRITE)
	file.store_string("\n".join(_storyboard) + "\n")
	file.close()
	print("saved %d frames and storyboard.txt in %s" % [_number, _out])
	quit()


func _wants(part: String) -> bool:
	return _only.is_empty() or _only.has(part)


func _title() -> void:
	var title: TitleScreen = (load("res://ui/menus/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _frames(10)
	title.open(false, "")
	await _frames(30)
	_shot("title", "LAST STAND: the title over the fortress at night.")
	title.queue_free()
	await _frames(2)


## A late wave (or a boss's) on `chapter`'s level with `hero`'s towers built and upgraded.
func _fight(run: RunData, hero: HeroData, chapter: ChapterData, boss: bool, caption: String) -> void:
	var level: Level = chapter.level_scene.instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var source: WaveData = spawner.waves.back()
	if chapter.boss != null:
		source = chapter.boss.waves.back()
	var wave: WaveData = source.duplicate()
	wave.health_multiplier *= chapter.fight_health_scale
	spawner.waves = [wave, WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Hero).data = hero
	root.add_child(level)
	await _frames(3)
	level.apply_hero(hero, run.heroes)
	(level.get_node("Fortress") as Fortress).health.setup(100000)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(100000, Economy.Source.KILL)
	for i: int in builder.get_slots().size():
		builder.build(builder.get_slots()[i], builder.catalog[TOWERS[i % TOWERS.size()] % builder.catalog.size()])
	await _frames(60)
	for slot: BuildSlot in builder.get_slots():
		builder.upgrade(slot)
		builder.upgrade(slot)
	await _frames(30)
	_shot("%s_build" % hero.id, "%s: the towers stand ready." % hero.display_name)
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	for i: int in FIGHT_FRAMES.size():
		await _frames(FIGHT_FRAMES[i])
		_shot("%s_%s_fight_%d" % [hero.id, "boss" if boss else String(chapter.id), i + 1], caption)
	level.queue_free()
	await _frames(3)


func _ending() -> void:
	var book: StoryBook = load("res://data/story/story_book.tres")
	var screen: EndingScreen = (load("res://ui/menus/ending_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await _frames(10)
	screen.open(book.endings[0], true)
	await _frames(20)
	_shot("ending", "The Marshal Rests: an ending, and the choice to descend.")
	screen.queue_free()
	await _frames(2)


func _shot(name: String, caption: String) -> void:
	_number += 1
	var file_name: String = "%02d_%s.png" % [_number, name]
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(_out.path_join(file_name)))
	_storyboard.append("%s  %s" % [file_name, caption])
	print("saved ", file_name)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame

extends SceneTree
## Automated check for the run map's look (M13 playtest: "the run map is super boring"): every biome has a
## MapLook with a seamless ground tile; the map screen hands it to its view, which draws every chapter's
## map (ground, roads, frames, weather) without errors, keeps its weather inside the panel and gives each
## node a frame by state (idle, choice, done; the boss's is bigger).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")

var _failures: int = 0


func _initialize() -> void:
	var chapters: Array[ChapterData] = []
	for tier: int in range(1, RUN.tier_count() + 1):
		for chapter: ChapterData in RUN.biomes_of_tier(tier):
			if not chapters.has(chapter):
				chapters.append(chapter)
	_check("nine biomes across the three tiers (%d)" % chapters.size(), chapters.size() == 9)
	var grounds: Dictionary = {}
	for chapter: ChapterData in chapters:
		var look: MapLook = chapter.map_look
		_check("%s has a map look with a 256 px ground tile" % chapter.id, look != null and look.ground != null and look.ground.get_size() == Vector2(256, 256))
		if look != null and look.ground != null:
			grounds[look.ground.resource_path] = true
	_check("each biome has its own ground", grounds.size() == chapters.size())

	var screen: MapScreen = (load("res://ui/map/map_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	var view: MapView = screen.get_node("%MapView")
	_check("the view clips its weather to the panel", view.clip_contents)
	for chapter: ChapterData in chapters:
		var map: RunMap = RunMap.generate(chapter, 3)
		map.visit(map.get_choices()[0])
		screen.open(map, chapter.display_name, "Gold 0")
		for _i: int in 5:
			await process_frame
		_check("%s: the view has the chapter's look and size" % chapter.id, view.look == chapter.map_look and view.size.x > 600.0)
	var boss_frame: Texture2D = MapView.FRAMES["boss_idle"]
	var frame: Texture2D = MapView.FRAMES["idle"]
	_check("the boss's frame is bigger than the others", boss_frame.get_width() > frame.get_width())
	_check("a frame is wider than the node icons it holds", frame.get_width() > 32 and boss_frame.get_width() > 48)
	for weather: MapLook.Weather in MapLook.Weather.values():
		_check("every weather has its settings (%d)" % weather, MapView.WEATHER.has(weather))
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

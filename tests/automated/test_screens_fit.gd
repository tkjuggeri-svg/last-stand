extends SceneTree
## Automated check that every screen and menu fits the screen (a playtest found the War Room's title and
## buttons cut off in fullscreen): each is opened with worst-case content and every button and label must lie
## fully inside the visible area, at the base 1280x720 and in a wide fullscreen window (21:9: the game's
## "expand" stretch keeps 720 px of height and widens). Content in a ScrollContainer may scroll.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")
const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(2560, 1080)]

var _failures: int = 0
var _main: Node
var _level: Level


func _initialize() -> void:
	_main = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	await process_frame
	await process_frame
	_level = await MapFixtures.enter_first_battle(_main)
	await _frames(3)
	var screens: Dictionary = _screens()
	for size: Vector2i in SIZES:
		root.size = size
		await _frames(3)
		var area: Rect2 = Rect2(Vector2.ZERO, get_root().get_visible_rect().size)
		for label: String in screens:
			var node: Node = await (screens[label] as Callable).call()
			await _frames(3)
			var opened: bool = node != null and (not (node is CanvasLayer) or (node as CanvasLayer).visible)
			_check("%s opened" % label, opened)
			if not opened:
				continue
			var clipped: Array[String] = FitCheck.clipped(node, area)
			_check("%s fits at %dx%d (visible %s)%s" % [label, size.x, size.y, area.size, "" if clipped.is_empty() else ": " + "; ".join(clipped)], clipped.is_empty())
			_close(node)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


## Label -> Callable that opens that screen (worst case content) and returns its root node.
func _screens() -> Dictionary:
	var book: StoryBook = load("res://data/story/story_book.tres")
	var profile: SaveProfile = _full_profile()
	var screens: Dictionary = {}
	screens["title"] = func() -> Node:
		var title: TitleScreen = _fresh("res://ui/menus/title_screen.tscn")
		title.open(true, "The save could not be read, so the backup was loaded instead. Your progress is safe.")
		return title
	screens["settings"] = func() -> Node:
		var title: TitleScreen = _fresh("res://ui/menus/title_screen.tscn")
		title.open(false, "")
		title.get_node("%SettingsButton").pressed.emit()
		return title
	screens["credits"] = func() -> Node:
		var credits: CreditsScreen = _fresh("res://ui/menus/credits_screen.tscn")
		credits.open()
		return credits
	screens["war room"] = func() -> Node:
		var hub: HubScreen = _fresh("res://ui/hub/hub_screen.tscn")
		hub.open(profile, load("res://data/meta/unlock_board.tres"), RUN.get_hero("necromancer"), true, book, RUN.pressure_options)
		return hub
	screens["chronicle"] = func() -> Node:
		var chronicle: ChronicleScreen = _fresh("res://ui/hub/chronicle_screen.tscn")
		chronicle.open(profile, book)
		return chronicle
	screens["pressure"] = func() -> Node:
		var pressure: PressureScreen = _fresh("res://ui/hub/pressure_screen.tscn")
		var all_on: Array[String] = []
		for option: PressureData in RUN.pressure_options:
			all_on.append(String(option.id))
		pressure.open(RUN.pressure_options, all_on)
		return pressure
	screens["run summary"] = func() -> Node:
		var summary: RunSummaryScreen = _fresh("res://ui/menus/run_summary_screen.tscn")
		var cards: Array = []
		for _i: int in 3:
			for card: UpgradeData in RUN.get_hero("knight").exclusive_cards:
				cards.append(String(card.id))
		var path: Array = []
		for _i: int in 3:
			path.append_array(["battle", "elite", "event", "merchant", "battle", "boss"])
		summary.open({"result": "won", "chapter": 3, "row": 6, "seed": 4166096284, "hero": "knight", "pressure": 9, "depth": 4, "shards": 321,
			"biomes": ["The Crypt Road", "The Drowned Marsh", "The Ashen Keep", "Depth 1: The Pale Cathedral"], "path": path,
			"cards": cards, "relics": ["crown_of_thorns", "banner_of_the_last_keep", "ossuary_bell"], "kills": 1234, "waves": 77, "minutes": 61.4,
			"shard_lines": [["3 battles won", 30], ["2 elites beaten", 40], ["The Fallen Marshal beaten", 60], ["Pressure 9 (+90%)", 80], ["Descended 4 deep", 100]]})
		return summary
	screens["game over"] = func() -> Node:
		var over: GameOverScreen = _fresh("res://ui/menus/game_over_screen.tscn")
		over.open("The fortress has fallen.", 4166096284)
		return over
	screens["victory"] = func() -> Node:
		var win: VictoryScreen = _fresh("res://ui/menus/victory_screen.tscn")
		win.open("Every chapter held. The night is over.", 4166096284)
		return win
	screens["ending"] = func() -> Node:
		var ending: EndingScreen = _fresh("res://ui/menus/ending_screen.tscn")
		var longest: EndingData = book.endings[0]
		for candidate: EndingData in book.endings:
			if candidate.text.length() > longest.text.length():
				longest = candidate
		ending.open(longest, true)
		return ending
	screens["pause menu"] = func() -> Node:
		var pause: PauseMenu = _main.get_node("%PauseMenu")
		pause.open()
		return pause
	screens["feedback"] = func() -> Node:
		var feedback: FeedbackScreen = _main.get_node("%FeedbackScreen")
		feedback.open()
		return feedback
	screens["chapter cleared"] = func() -> Node:
		var chapter: ChapterScreen = _fresh("res://ui/map/chapter_screen.tscn")
		var carry: ChapterCarry = ChapterCarry.new()
		carry.upgrades = RUN.get_hero("knight").exclusive_cards.duplicate()
		chapter.open("Chapter 1: The Crypt Road", "", carry, 0.4, 0.5, 100, 100, [RUN.chapters[3], RUN.chapters[4]] as Array[ChapterData])
		return chapter
	screens["event"] = func() -> Node:
		var events: EventScreen = _main.get_node("%EventScreen")
		var longest: EventData = RUN.chapters[0].events[0]
		for candidate: EventData in RUN.chapters[0].events + RUN.chapters[1].events + RUN.chapters[2].events:
			if candidate.text.length() + candidate.choices.size() * 80 > longest.text.length() + longest.choices.size() * 80:
				longest = candidate
		events.open(longest, _level.events)
		return events
	screens["merchant"] = func() -> Node:
		var shop: MerchantScreen = _main.get_node("%MerchantScreen")
		_level.merchant.open()
		shop.open(_level.merchant)
		return shop
	screens["run map"] = func() -> Node:
		var map_screen: MapScreen = _main.get_node("%MapScreen")
		map_screen.open(_main.call("get_map"), "Chapter 1: The Crypt Road", "Gold 150    Fortress 100 / 100    Lives 3    Next fight: Hardened elite")
		return map_screen
	screens["battle HUD"] = func() -> Node:
		return _level.get_node("HUD")
	screens["build menu"] = func() -> Node:
		var menu: Node = _level.get_node("BuildMenu")
		_level.economy.earn(2000, Economy.Source.REFUND)
		menu.open(_level.builder.get_slots()[0])
		return menu
	screens["build menu, built tower"] = func() -> Node:
		var menu: Node = _level.get_node("BuildMenu")
		_level.economy.earn(5000, Economy.Source.REFUND)
		var slot: BuildSlot = _level.builder.get_slots()[1]
		if slot.is_empty():
			_level.builder.build(slot, load("res://data/towers/archer.tres") as TowerData)
			await _frames(90)
			for _i: int in 2:
				_level.builder.upgrade(slot)
			_level.builder.masterwork(slot)
			_level.builder.masterwork(slot)
		menu.open(slot)
		return menu
	screens["upgrade choice"] = func() -> Node:
		_level.offers.pool = RUN.get_hero("knight").exclusive_cards.duplicate()
		_level.offers.make_offer()
		return _level.get_node("UpgradeChoiceScreen")
	screens["hint"] = func() -> Node:
		var hint: HintPanel = _main.get_node("%HintPanel")
		hint.show_hint(&"story_hint", "Ashen Keep\\nThe last king's castle. Its walls fall inward on those who linger, and its Marshal still keeps the gate.")
		return hint
	return screens


func _full_profile() -> SaveProfile:
	var profile: SaveProfile = SaveProfile.new()
	profile.runs = 6
	profile.wins = 2
	profile.shards = 180
	profile.shards_total = 400
	profile.best_chapter = 3
	profile.best_row = 6
	profile.bosses = ["The Lich Warden", "The Tollkeeper", "The Fallen Marshal"]
	profile.pressure_best = 9
	profile.pressure_wins["knight"] = 5
	profile.depth_best["knight"] = 3
	profile.run = {"seed": 1}
	profile.history.append({"result": "lost", "chapter": 2, "row": 1, "bosses": [], "relics": ["x"], "hero": "knight"})
	return profile


func _fresh(path: String) -> Node:
	var node: Node = (load(path) as PackedScene).instantiate()
	root.add_child(node)
	return node


func _close(node: Node) -> void:
	for screen: String in ["PauseMenu", "FeedbackScreen", "EventScreen", "MerchantScreen", "MapScreen", "HintPanel"]:
		if node.name == screen and node.has_method("hide"):
			node.call("hide")
			return
	if node.get_parent() == root and node != _main:
		node.queue_free()
	elif node.name == "BuildMenu" and node.has_method("close"):
		node.call("close")


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1

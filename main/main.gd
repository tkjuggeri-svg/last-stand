extends Node
## Boots the game and runs a run (see docs/M7_RUN_MAP.md): loads and applies the player's settings,
## starts a run in RunState (its chapters from run_data, each with a node map), and plays the map.
## A chapter's level is made when the chapter starts and stays (with its towers, gold and damage)
## while the map is shown between nodes; a battle, an elite or the boss is played on it as a fight
## (Level.start_encounter, with its reward), a merchant opens the shop, an event or a shrine its
## scene (EventScreen; the level's EventResolver applies the answer, and Main plays what it leaves: an
## extra fight, upgrade choices one after another). Beating the last chapter's
## boss wins the run; losing anywhere loses it (Game Over). Either way the run pays Soul Shards into the
## saved profile (M8), and the front end (FrontEnd: title, War Room, run summary) takes over: Continue
## shows the summary, then the War Room starts the next run; the pause menu's Abandon run ends it the
## same way. In script mode (tests, tools) there is no front end: Main starts a run at once, and
## Restart / Play again start a fresh one, as before M8. The pause
## action opens the pause menu, unless something else holds the game (the upgrade choice) or the run
## is over; a menu that is open in the level (the build menu) takes Esc first. The feedback key opens
## FeedbackScreen anywhere; Main saves its report (FeedbackRecorder: the note, a screenshot and the
## run's state, RunSnapshot) in feedback_dir.

const LOSS_TEXT: Dictionary = {
	Level.LossReason.FORTRESS_DESTROYED: "The fortress has fallen.",
	Level.LossReason.HERO_KILLED: "The hero has fallen.",
}
const VICTORY_TEXT: String = "The fortress stands. Every chapter held."
const STATUS_TEXT: String = "Gold %d    Fortress %d / %d    Lives %d"
## The dev menu (tools/: never exported), loaded in debug builds when it is there.
const DEV_MENU: String = "res://tools/dev/dev_menu.tscn"
## Share of the fortress's max HP repaired between two chapters.
const CHAPTER_REPAIR: float = 0.5

## The run: its chapters, each with its map and its level.
@export var run_data: RunData
## The run's seed (maps, offers); -1 = a random one each run.
@export var run_seed: int = -1
## Start on the title screen (M8); false starts a run at once (tests). Script mode always starts a run.
@export var boot_to_title: bool = true
## The unlock board (M8): what a run may use comes from it and the player's profile.
@export var unlock_board: UnlockBoard
## Where feedback reports are saved (tests point it elsewhere).
@export var feedback_dir: String = FeedbackRecorder.DEFAULT_DIR

## The summary of the last run that ended (M8; empty before), with its shards.
var last_summary: Dictionary = {}

var _level: Level
## The map node being played.
var _node: MapNode
## Upgrade choices an event left to make, one after another, before the map comes back.
var _pending_choices: Array[FightReward] = []

@onready var _run: RunStateNode = get_node("/root/RunState")
@onready var _save: SaveManagerNode = get_node("/root/SaveManager")
@onready var _game_over_screen: GameOverScreen = %GameOverScreen
@onready var _victory_screen: VictoryScreen = %VictoryScreen
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _map_screen: MapScreen = %MapScreen
@onready var _merchant_screen: MerchantScreen = %MerchantScreen
@onready var _event_screen: EventScreen = %EventScreen
@onready var _chapter_screen: ChapterScreen = %ChapterScreen
@onready var _feedback_screen: FeedbackScreen = %FeedbackScreen
@onready var _front_end: FrontEnd = %FrontEnd


func _ready() -> void:
	assert(run_data != null and not run_data.chapters.is_empty(), "Main needs a run_data with chapters")
	GameSettings.load_and_apply()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed=") and arg.trim_prefix("--seed=").is_valid_int():
			run_seed = int(arg.trim_prefix("--seed="))  # replay a run: godot ... -- --seed=<n>
	if OS.is_debug_build() and ResourceLoader.exists(DEV_MENU):
		var dev_menu: Node = (load(DEV_MENU) as PackedScene).instantiate()
		dev_menu.set("main", self)
		add_child(dev_menu)
	_game_over_screen.restart_requested.connect(_after_run)
	_victory_screen.restart_requested.connect(_after_run)
	_pause_menu.restart_requested.connect(_on_restart_requested)
	_pause_menu.quit_requested.connect(quit_game)
	_pause_menu.seed_run_requested.connect(_on_seed_run_requested)
	_front_end.unlock_board = unlock_board
	_front_end.run_requested.connect(start_run)
	_front_end.continue_requested.connect(start_run)
	_front_end.quit_requested.connect(quit_game)
	_map_screen.node_chosen.connect(_on_node_chosen)
	_merchant_screen.left.connect(_show_map)
	_event_screen.choice_picked.connect(_on_event_choice)
	_event_screen.continued.connect(_next_follow_up)
	_chapter_screen.continued.connect(_start_chapter)
	_feedback_screen.submitted.connect(_save_feedback)
	if uses_front_end():
		_game_over_screen.set_button_text("Continue")
		_victory_screen.set_button_text("Continue")
		_pause_menu.set_restart_text("Abandon run")
	if boot_to_title and uses_front_end():
		_front_end.show_title()
	else:
		start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and can_pause():
		get_viewport().set_input_as_handled()
		_pause_menu.show_seed(_run.seed_value)
		_pause_menu.open()


## Not while another screen holds the game (the upgrade choice pauses it) or after the run.
func can_pause() -> bool:
	return _level != null and not _level.is_run_over() and not get_tree().paused and not _pause_menu.is_open()


## True when runs pay into the saved profile and the front end comes between them (not in script mode).
func uses_front_end() -> bool:
	return not _save.is_scripted()


func quit_game() -> void:
	get_tree().quit()


## The chapter's level (null between runs).
func get_level() -> Level:
	return _level


## The chapter's node map.
func get_map() -> RunMap:
	return _run.map


## Starts a fresh run, chapter 1 and its map: from `seed_value` if given (>= 0; a replay), else from
## run_seed if set, else from a new random seed.
func start_run(seed_value: int = -1) -> void:
	_close_screens()
	var chosen: int = seed_value if seed_value >= 0 else (run_seed if run_seed >= 0 else randi())
	_run.start_run(run_data, chosen, RunUnlocks.for_profile(unlock_board, _save.profile))
	_start_chapter()
	if _run.unlocks.has_perk(&"muster"):
		_offer_muster()


func _close_screens() -> void:
	_pause_menu.close()
	_game_over_screen.hide()
	_victory_screen.hide()
	_merchant_screen.hide()
	_event_screen.hide()
	_chapter_screen.hide()
	_front_end.hide_all()
	_pending_choices.clear()


## Replaces the level with the chapter's (fresh) one and shows its map.
func _start_chapter() -> void:
	_free_level()
	_level = _run.get_chapter().level_scene.instantiate()
	_level.run_lost.connect(_on_level_run_lost)
	_level.encounter_cleared.connect(_on_encounter_cleared)
	add_child(_level)
	_level.apply_unlocks(_run.unlocks)
	_level.spawner.enemy_killed.connect(func(_e: Enemy) -> void: _run.kills += 1)
	_level.spawner.wave_cleared.connect(func(_n: int) -> void: _run.waves += 1)
	if _run.carry != null:
		_level.carry_in(_run.carry, CHAPTER_REPAIR)
		_run.carry = null
	var offers: UpgradeOffers = _level.offers
	if offers != null:
		offers.set_seed(_run.chapter_seed())
	if _level.events != null:
		_level.events.set_seed(_run.chapter_seed())
	_show_map()


func _free_level() -> void:
	if _level != null:
		# Remove first so the old level never overlaps the new one, even for a frame.
		remove_child(_level)
		_level.queue_free()
		_level = null


func _show_map() -> void:
	_level.set_active(false)
	_map_screen.open(_run.map, _run.get_chapter().display_name, _status())


func _status() -> String:
	var health: HealthComponent = _level.fortress.health
	var lives: int = _level.hero_lives.get_lives_left() if _level.hero_lives != null else 0
	var text: String = STATUS_TEXT % [_level.economy.get_gold(), health.current_health, health.max_health, lives]
	if _level.events != null and not _level.events.get_pending_affixes().is_empty():
		text = "Next fight: %s    " % ", ".join(_level.events.get_pending_affixes().map(func(a: AffixData) -> String: return a.display_name)) + text
	return text


func _on_node_chosen(node: MapNode) -> void:
	if _run.map.visit(node):
		_enter_node(node)


## Plays any node of the chapter's map, reachable or not (the dev menu's jump).
func jump_to_node(node: MapNode) -> void:
	_run.map.force_visit(node)
	_enter_node(node)


## Starts chapter `index` (0-based) on a fresh level, nothing carried (the dev menu's jump).
func jump_to_chapter(index: int) -> void:
	_close_screens()
	_run.set_chapter(index)
	_start_chapter()


func _enter_node(node: MapNode) -> void:
	_node = node
	_map_screen.close()
	match node.kind:
		RunMap.Kind.BATTLE, RunMap.Kind.ELITE, RunMap.Kind.BOSS:
			_start_fight(node.encounter, node.affix, _run.get_chapter().reward_for(node.kind, _run.is_last_chapter()))
		RunMap.Kind.MERCHANT:
			_level.merchant.open()
			_merchant_screen.open(_level.merchant)
		RunMap.Kind.EVENT, RunMap.Kind.SHRINE:
			_event_screen.open(node.event, _level.events)


## Plays `encounter` on the level with its own twist (an elite's) and any an event left for it.
func _start_fight(encounter: EncounterData, affix: AffixData, reward: FightReward) -> void:
	var affixes: Array[AffixData] = []
	if affix != null:
		affixes.append(affix)
	if _level.events != null:
		affixes.append_array(_level.events.take_fight_affixes())
	var waves: Array[WaveData] = encounter.build_waves(affixes)
	var chapter: ChapterData = _run.get_chapter()
	var scale: float = chapter.fight_health_scale * (chapter.elite_health_scale if _node != null and _node.kind == RunMap.Kind.ELITE else 1.0)
	for wave: WaveData in waves:
		wave.health_multiplier *= scale
	_level.set_active(true)
	_level.start_encounter(waves, reward)


func _on_event_choice(index: int) -> void:
	var outcome: EventOutcome = _level.events.apply(_node.event.choices[index])
	if outcome == null:
		return
	_pending_choices = outcome.choices.duplicate()
	if outcome.extra_fight != null:
		_event_screen.hide()
		_start_fight(_run.get_chapter().extra_fight(_node.row + 1), null, outcome.extra_fight)  # its reward, then the choices
		return
	_event_screen.show_result(outcome.text if not outcome.text.is_empty() else "So be it.")


## The next upgrade choice an event left (over the level, like a fight's reward), else the map.
func _next_follow_up() -> void:
	if _pending_choices.is_empty():
		_show_map()
		return
	var reward: FightReward = _pending_choices.pop_front()
	_level.set_active(true)
	var offer: Array[UpgradeData] = _level.offers.make_relic_offer(reward.relics) if reward.relics > 0 \
		else _level.offers.make_offer(reward.cards, reward.rare_only)
	if offer.is_empty():
		_next_follow_up()
		return
	_level.offers.picked.connect(func(_data: UpgradeData) -> void: _next_follow_up(), CONNECT_ONE_SHOT)


## The Muster starting choice: 1 of 2 common cards before the first fight, then the map.
func _offer_muster() -> void:
	_level.set_active(true)
	if _level.offers.make_offer(2, false, true).is_empty():
		_show_map()
		return
	_level.offers.picked.connect(func(_data: UpgradeData) -> void: _show_map(), CONNECT_ONE_SHOT)


func _on_encounter_cleared() -> void:
	if _node != null and _node.is_combat():
		_run.cleared.append({"chapter": _run.chapter_index + 1, "row": _node.row, "kind": RunMap.Kind.keys()[_node.kind].to_lower(),
			"boss": RunSummary.boss_name(_node.encounter) if _node.kind == RunMap.Kind.BOSS else ""})
	if _node != null and _node.kind == RunMap.Kind.BOSS:
		_on_chapter_cleared()
	else:
		_next_follow_up()


func _on_chapter_cleared() -> void:
	if _run.is_last_chapter():
		_level.end_run_won()
		_finish_run("won")
		_victory_screen.open(VICTORY_TEXT, _run.seed_value)
		return
	# Pack up: everything carries into the next chapter's fresh level (Continue starts it).
	var refund_ratio: float = _run.get_chapter().leave_refund
	var carry: ChapterCarry = _level.carry_out(refund_ratio)
	var cleared: String = _run.get_chapter().display_name
	_run.carry = carry
	_run.next_chapter()
	_level.set_active(false)
	var max_health: int = _level.fortress.health.max_health
	var repair: float = CHAPTER_REPAIR if _level.fortress.can_repair() else 0.0  # none under Iron Tithe
	_chapter_screen.open(cleared, _run.get_chapter().display_name, carry, refund_ratio, repair,
		mini(carry.fortress_health + roundi(max_health * repair), max_health), max_health)


## The feedback box was filled in: save the report with the run's state as it is now.
func _save_feedback(note: String, screenshot: Image) -> void:
	var state: Dictionary = RunSnapshot.capture(_run, _level, _node, _screen_name())
	_feedback_screen.show_saved(FeedbackRecorder.save(feedback_dir, note, screenshot, state))


## Which screen the player is on (for a feedback report).
func _screen_name() -> String:
	if _front_end.is_open():
		return "front_end"
	for screen: CanvasLayer in [_game_over_screen, _victory_screen, _chapter_screen, _merchant_screen, _event_screen, _map_screen, _pause_menu]:
		if screen.visible:
			return screen.name.to_snake_case()
	if _level != null and _level.offers != null and _level.offers.is_offer_open():
		return "upgrade_choice"
	return "fight"


## The run ended: its summary, its shards paid into the profile (saved). Returns the summary.
func _finish_run(result: String) -> Dictionary:
	last_summary = RunSummary.build(_run, _level, result)
	last_summary["shard_lines"] = MetaProgress.shard_lines(last_summary, _save.profile)
	last_summary["shards"] = MetaProgress.finish_run(_save.profile, last_summary)
	_save.save_profile()
	return last_summary


## Game Over / Victory's button: the run summary (then the War Room), or in script mode a fresh run.
func _after_run() -> void:
	if not uses_front_end():
		start_run()
		return
	_front_end.show_summary(last_summary, func() -> void:
		_close_screens()
		_free_level())


## The pause menu's Restart, "Abandon run" with the front end: the run ends (and pays) as abandoned.
func _on_restart_requested() -> void:
	if not uses_front_end():
		start_run()
		return
	_finish_run("abandoned")
	_after_run()


## A run from a typed seed: with the front end the run in play is abandoned first (it still pays).
func _on_seed_run_requested(seed_value: int) -> void:
	if uses_front_end() and _level != null and not _level.is_run_over():
		_finish_run("abandoned")
	start_run(seed_value)


func _on_level_run_lost(reason: Level.LossReason) -> void:
	_finish_run("lost")
	_game_over_screen.open(LOSS_TEXT[reason], _run.seed_value)

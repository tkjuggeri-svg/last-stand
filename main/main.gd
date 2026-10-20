extends Node
## Boots the game and runs a run (see docs/M7_RUN_MAP.md): loads and applies the player's settings,
## starts a run in RunState (its chapters from run_data, each with a node map), and plays the map.
## A chapter's level is made when the chapter starts and stays (with its towers, gold and damage)
## while the map is shown between nodes; a battle, an elite or the boss is played on it as a fight
## (Level.start_encounter, with its reward), a merchant opens the shop, an event or a shrine its
## scene (EventScreen; the level's EventResolver applies the answer, and Main plays what it leaves: an
## extra fight, upgrade choices one after another). Beating the last chapter's
## boss wins the run; losing anywhere loses it (Game Over); Restart starts a fresh run. The pause
## action opens the pause menu, unless something else holds the game (the upgrade choice) or the run
## is over; a menu that is open in the level (the build menu) takes Esc first.

const LOSS_TEXT: Dictionary = {
	Level.LossReason.FORTRESS_DESTROYED: "The fortress has fallen.",
	Level.LossReason.HERO_KILLED: "The hero has fallen.",
}
const VICTORY_TEXT: String = "The fortress stands. Every chapter held."
const STATUS_TEXT: String = "Gold %d    Fortress %d / %d    Lives %d"
## Share of the fortress's max HP repaired between two chapters.
const CHAPTER_REPAIR: float = 0.5

## The run: its chapters, each with its map and its level.
@export var run_data: RunData
## The run's seed (maps, offers); -1 = a random one each run.
@export var run_seed: int = -1

var _level: Level
## The map node being played.
var _node: MapNode
## Upgrade choices an event left to make, one after another, before the map comes back.
var _pending_choices: Array[FightReward] = []

@onready var _run: RunStateNode = get_node("/root/RunState")
@onready var _game_over_screen: GameOverScreen = %GameOverScreen
@onready var _victory_screen: VictoryScreen = %VictoryScreen
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _map_screen: MapScreen = %MapScreen
@onready var _merchant_screen: MerchantScreen = %MerchantScreen
@onready var _event_screen: EventScreen = %EventScreen
@onready var _chapter_screen: ChapterScreen = %ChapterScreen


func _ready() -> void:
	assert(run_data != null and not run_data.chapters.is_empty(), "Main needs a run_data with chapters")
	GameSettings.load_and_apply()
	_game_over_screen.restart_requested.connect(start_run)
	_victory_screen.restart_requested.connect(start_run)
	_pause_menu.restart_requested.connect(start_run)
	_pause_menu.quit_requested.connect(quit_game)
	_map_screen.node_chosen.connect(_on_node_chosen)
	_merchant_screen.left.connect(_show_map)
	_event_screen.choice_picked.connect(_on_event_choice)
	_event_screen.continued.connect(_next_follow_up)
	_chapter_screen.continued.connect(_start_chapter)
	start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and can_pause():
		get_viewport().set_input_as_handled()
		_pause_menu.open()


## Not while another screen holds the game (the upgrade choice pauses it) or after the run.
func can_pause() -> bool:
	return _level != null and not _level.is_run_over() and not get_tree().paused and not _pause_menu.is_open()


func quit_game() -> void:
	get_tree().quit()


## The chapter's level (null between runs).
func get_level() -> Level:
	return _level


## The chapter's node map.
func get_map() -> RunMap:
	return _run.map


## Starts a fresh run: a new seed, chapter 1 and its map.
func start_run() -> void:
	_pause_menu.close()
	_game_over_screen.hide()
	_victory_screen.hide()
	_merchant_screen.hide()
	_event_screen.hide()
	_chapter_screen.hide()
	_pending_choices.clear()
	_run.start_run(run_data, run_seed if run_seed >= 0 else randi())
	_start_chapter()


## Replaces the level with the chapter's (fresh) one and shows its map.
func _start_chapter() -> void:
	if _level != null:
		# Remove first so the old level never overlaps the new one, even for a frame.
		remove_child(_level)
		_level.queue_free()
	_level = _run.get_chapter().level_scene.instantiate()
	_level.run_lost.connect(_on_level_run_lost)
	_level.encounter_cleared.connect(_on_encounter_cleared)
	add_child(_level)
	if _run.carry != null:
		_level.carry_in(_run.carry, CHAPTER_REPAIR)
		_run.carry = null
	var offers: UpgradeOffers = _level.offers
	if offers != null:
		offers.set_seed(_run.chapter_seed())
	if _level.events != null:
		_level.events.set_seed(_run.chapter_seed())
	_show_map()


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
	if not _run.map.visit(node):
		return
	_node = node
	_map_screen.close()
	match node.kind:
		RunMap.Kind.BATTLE, RunMap.Kind.ELITE, RunMap.Kind.BOSS:
			_start_fight(node.encounter, node.affix, _reward_for(node))
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
	_level.set_active(true)
	_level.start_encounter(encounter.build_waves(affixes), reward)


func _on_event_choice(index: int) -> void:
	var outcome: EventOutcome = _level.events.apply(_node.event.choices[index])
	if outcome == null:
		return
	_pending_choices = outcome.choices.duplicate()
	if outcome.extra_fight != null:
		_event_screen.hide()
		_start_fight(_extra_fight_encounter(), null, outcome.extra_fight)  # its reward, then the choices
		return
	_event_screen.show_result(outcome.text if not outcome.text.is_empty() else "So be it.")


## An event's extra fight: the first wave of the next row's battle.
func _extra_fight_encounter() -> EncounterData:
	var chapter: ChapterData = _run.get_chapter()
	var row: int = _node.row + 1
	var pool: Array[EncounterData] = chapter.encounters_for(chapter.battles, row)
	while pool.is_empty() and row > 1:
		row -= 1
		pool = chapter.encounters_for(chapter.battles, row)
	var fight: EncounterData = pool[0].duplicate()
	fight.waves = pool[0].waves.slice(0, 1)
	return fight


## The next upgrade choice an event left (over the level, like a fight's reward), else the map.
func _next_follow_up() -> void:
	if _pending_choices.is_empty():
		_show_map()
		return
	var reward: FightReward = _pending_choices.pop_front()
	_level.set_active(true)
	if _level.offers.make_offer(reward.cards, reward.rare_only).is_empty():
		_next_follow_up()
		return
	_level.offers.picked.connect(func(_data: UpgradeData) -> void: _next_follow_up(), CONNECT_ONE_SHOT)


## What winning the node's fight gives, from the chapter's data.
func _reward_for(node: MapNode) -> FightReward:
	var chapter: ChapterData = _run.get_chapter()
	match node.kind:
		RunMap.Kind.ELITE:
			return FightReward.make(chapter.elite_cards, true, chapter.elite_gold)
		RunMap.Kind.BOSS:
			return FightReward.make(chapter.boss_cards if not _run.is_last_chapter() else 0, true, 0, chapter.boss_repair)
	return FightReward.make(chapter.battle_cards)


func _on_encounter_cleared() -> void:
	if _node != null and _node.kind == RunMap.Kind.BOSS:
		_on_chapter_cleared()
	else:
		_next_follow_up()


func _on_chapter_cleared() -> void:
	if _run.is_last_chapter():
		_level.end_run_won()
		_victory_screen.open(VICTORY_TEXT)
		return
	# Pack up: everything carries into the next chapter's fresh level (Continue starts it).
	var carry: ChapterCarry = _level.carry_out()
	var cleared: String = _run.get_chapter().display_name
	_run.carry = carry
	_run.next_chapter()
	_level.set_active(false)
	var max_health: int = _level.fortress.health.max_health
	_chapter_screen.open(cleared, _run.get_chapter().display_name, carry, CHAPTER_REPAIR,
		mini(carry.fortress_health + roundi(max_health * CHAPTER_REPAIR), max_health), max_health)


func _on_level_run_lost(reason: Level.LossReason) -> void:
	_game_over_screen.open(LOSS_TEXT[reason])

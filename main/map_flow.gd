class_name MapFlow
extends Node
## Plays the chapter's run map on its level (see docs/M7_RUN_MAP.md; split out of Main in M8): shows
## the map with the run's status; the node chosen becomes a fight (its encounter, an elite's twist and
## any an event left, its reward), the merchant's shop, or an event's scene (the level's EventResolver
## applies the answer, and what it leaves is played here: an extra fight, upgrade choices one after
## another), then the map again. It records each fight won in RunState for the run's summary.
## Main calls down (play, show_map, jump_to, offer_muster, close) and hears back: map_shown (the run
## stands on the map: it can be saved there), fight_started and boss_beaten (the chapter is cleared).

signal map_shown
## A fight begins on the level (its first build phase).
signal fight_started
signal boss_beaten

const STATUS_TEXT: String = "Gold %d    Fortress %d / %d    Lives %d"

@export var map_screen: MapScreen
@export var merchant_screen: MerchantScreen
@export var event_screen: EventScreen

var _level: Level
## The map node being played.
var _node: MapNode
## Upgrade choices an event left to make, one after another, before the map comes back.
var _pending_choices: Array[FightReward] = []

@onready var _run: RunStateNode = get_node("/root/RunState")


func _ready() -> void:
	map_screen.node_chosen.connect(_on_node_chosen)
	merchant_screen.left.connect(show_map)
	event_screen.choice_picked.connect(_on_event_choice)
	event_screen.continued.connect(_next_follow_up)


## Plays the run's current chapter on `level` (Main's fresh one, ready) from now on.
func play(level: Level) -> void:
	_level = level
	_node = null
	_pending_choices.clear()
	level.encounter_cleared.connect(_on_encounter_cleared)


## Hides its screens and forgets what was left to do (a new run, a jump).
func close() -> void:
	map_screen.close()
	merchant_screen.hide()
	event_screen.hide()
	_pending_choices.clear()


## The map node being played (null before the first).
func get_current_node() -> MapNode:
	return _node


func show_map() -> void:
	_level.set_active(false)
	map_screen.open(_run.map, _run.get_chapter().display_name, _status())
	map_shown.emit()


## Plays any node of the chapter's map, reachable or not (the dev menu's jump).
func jump_to(node: MapNode) -> void:
	_run.map.force_visit(node)
	_enter_node(node)


## The Muster starting choice: 1 of 2 common cards before the first fight, then the map.
func offer_muster() -> void:
	map_screen.close()  # no picking a node behind the choice
	_level.set_active(true)
	if _level.offers.make_offer(2, false, true).is_empty():
		show_map()
		return
	_level.offers.picked.connect(func(_data: UpgradeData) -> void: show_map(), CONNECT_ONE_SHOT)


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


func _enter_node(node: MapNode) -> void:
	_node = node
	map_screen.close()
	match node.kind:
		RunMap.Kind.BATTLE, RunMap.Kind.ELITE, RunMap.Kind.BOSS:
			_start_fight(node.encounter, node.affix, _run.get_chapter().reward_for(node.kind, _run.is_last_chapter()))
		RunMap.Kind.MERCHANT:
			_level.merchant.open()
			merchant_screen.open(_level.merchant)
		RunMap.Kind.EVENT, RunMap.Kind.SHRINE:
			event_screen.open(node.event, _level.events)


## Bosses (and elite leaders) ignore the wave's health scale, so their groups carry the extra health.
func _scale_bosses(waves: Array[WaveData], factor: float) -> void:
	for wave: WaveData in waves:
		for group: SpawnGroup in wave.groups:
			if group.enemy != null and group.enemy.is_boss:
				group.health_scale *= factor


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
	if _node != null and _node.kind == RunMap.Kind.ELITE and PressureRules.has_rule(_run.pressure, PressureRules.RULE_HARDENED_ELITES):
		scale *= PressureRules.ELITE_HEALTH
		_scale_bosses(waves, PressureRules.ELITE_HEALTH)  # the leader is a boss-class enemy
	for wave: WaveData in waves:
		wave.health_multiplier *= scale
	if _node != null and _node.kind == RunMap.Kind.BOSS and PressureRules.has_rule(_run.pressure, PressureRules.RULE_STRONGER_BOSSES):
		_scale_bosses(waves, PressureRules.BOSS_HEALTH)
	_level.set_active(true)
	_level.start_encounter(waves, reward)
	fight_started.emit()


func _on_event_choice(index: int) -> void:
	var outcome: EventOutcome = _level.events.apply(_node.event.choices[index])
	if outcome == null:
		return
	_pending_choices = outcome.choices.duplicate()
	if outcome.extra_fight != null:
		event_screen.hide()
		_start_fight(_run.get_chapter().extra_fight(_node.row + 1), null, outcome.extra_fight)  # its reward, then the choices
		return
	event_screen.show_result(outcome.text if not outcome.text.is_empty() else "So be it.")


## The next upgrade choice an event left (over the level, like a fight's reward), else the map.
func _next_follow_up() -> void:
	if _pending_choices.is_empty():
		show_map()
		return
	var reward: FightReward = _pending_choices.pop_front()
	_level.set_active(true)
	var offer: Array[UpgradeData] = _level.offers.make_relic_offer(reward.relics) if reward.relics > 0 \
		else _level.offers.make_offer(reward.cards, reward.rare_only)
	if offer.is_empty():
		_next_follow_up()
		return
	_level.offers.picked.connect(func(_data: UpgradeData) -> void: _next_follow_up(), CONNECT_ONE_SHOT)


func _on_encounter_cleared() -> void:
	if _node != null and _node.is_combat():
		_run.cleared.append({"chapter": _run.chapter_index + 1, "row": _node.row, "kind": RunMap.Kind.keys()[_node.kind].to_lower(),
			"boss": RunSummary.boss_name(_node.encounter) if _node.kind == RunMap.Kind.BOSS else ""})
	if _node != null and _node.kind == RunMap.Kind.BOSS:
		boss_beaten.emit()
	else:
		_next_follow_up()

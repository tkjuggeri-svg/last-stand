class_name HintDirector
extends Node
## The tutorial hints (M8, docs/M8_META.md section 7): each tip shows once per profile, the first time
## its moment comes (the first build phase, the first tower, the first wave, the hero first struck, the
## first upgrade choice, the map, an elite on it, the fortress under half, a tower that can evolve, the
## first relic, chapter 2). One at a time, the others wait their turn. Seen tips and "Skip all tips"
## are saved in the profile (hints_seen, hints_off; the War Room switches them back on). Off unless
## Main enables it (not in script mode). Watches the level and MapFlow; HintPanel shows the tip.

## Each tip's text; {action} is replaced by that action's first key or button.
const HINTS: Dictionary = {
	&"build": "Walk to a stone pad and press {interact} to build a tower. Towers fire on their own.",
	&"start_wave": "Ready? Press {start_wave} (or the Start wave button) to send the wave.",
	&"fight": "Press {attack} to swing at the dead. Keep them off the fortress gate.",
	&"dash": "{dash} dashes through the crowd: you can't be hurt while dashing.",
	&"ultimate": "Your ultimate is ready! Press {ultimate}: it charges from your kills and damage.",
	&"upgrade": "Pick one: it lasts the whole run.",
	&"map": "Choose your path: battles give cards, elites relics; merchants sell, events tempt.",
	&"elite": "An elite fight ahead: tougher dead, but it pays a relic.",
	&"quartermaster": "The walls are failing! Between waves the Quartermaster repairs them, for gold.",
	&"evolution": "Level 3: this tower can evolve into one of two forms. It's for good.",
	&"relic": "Relics change a rule of the run. Hover them in the row at the top left.",
	&"chapter2": "The Drowned Marsh: you wade slowly through its water. The paths are faster.",
}

## Off in script mode (tests, tools); Main turns it on.
@export var enabled: bool = false
@export var panel: HintPanel
@export var map_flow: MapFlow

var _queue: Array[StringName] = []
## Texts told at run time (the story's place and boss entries, M11), by id.
var _told: Dictionary = {}

@onready var _save: SaveManagerNode = get_node("/root/SaveManager")
@onready var _run: RunStateNode = get_node("/root/RunState")


func _ready() -> void:
	panel.closed.connect(func(_id: StringName) -> void: _show_next())
	panel.skip_all_requested.connect(skip_all)
	map_flow.map_shown.connect(_on_map_shown)
	map_flow.fight_started.connect(func() -> void: request(&"build"))


## Watches a chapter's new `level` for the moments of its tips.
func watch(level: Level) -> void:
	if not enabled:
		return
	level.builder.tower_built.connect(func(_slot: BuildSlot, _tower: Tower) -> void: request(&"start_wave"))
	level.spawner.wave_started.connect(func(_n: int) -> void: request(&"fight"))
	level.hero_lives.hero.hurt.connect(func(_amount: int) -> void: request(&"dash"))
	level.hero_lives.hero.get_ultimate().charged.connect(func() -> void: request(&"ultimate"))
	level.offers.offer_made.connect(func(_cards: Array[UpgradeData]) -> void: request(&"upgrade"))
	level.modifiers.upgrade_added.connect(func(data: UpgradeData, _stacks: int) -> void:
		if data is RelicData:
			request(&"relic"))
	level.builder.tower_upgraded.connect(func(_slot: BuildSlot, tower: Tower, tower_level: int) -> void:
		if tower_level == tower.data.max_level() and level.builder.can_evolve() and level.builder.evolution_unlocked(tower.data):
			request(&"evolution"))
	if level.quartermaster != null:
		level.fortress.health.health_changed.connect(func(current: int, max_health: int) -> void:
			if current > 0 and current * 2 < max_health:
				request(&"quartermaster"))
	if _run.chapter_index == 1:
		request(&"chapter2")


## Shows tip `id` now, or after the one showing, unless the profile has seen it or the tips are off.
func request(id: StringName) -> void:
	var profile: SaveProfile = _save.profile
	if not enabled or profile.hints_off or profile.hints_seen.has(String(id)) or _queue.has(id) or panel.get_current() == id:
		return
	_queue.append(id)
	if panel.get_current() == &"":
		_show_next()


## Tells `text` once under `id` (a story entry: a place's first visit, a boss's first appearance).
func tell(id: StringName, text: String) -> void:
	_told[id] = text
	request(id)


## No more tips (saved; the War Room's Tips switch brings them back).
func skip_all() -> void:
	_queue.clear()
	_save.profile.hints_off = true
	_save.save_profile()
	panel.close()


## Drops the tips waiting (a run ends, the front end shows).
func clear() -> void:
	_queue.clear()
	panel.close()


func _show_next() -> void:
	if _queue.is_empty() or _save.profile.hints_off:
		return
	var id: StringName = _queue.pop_front()
	_save.profile.hints_seen.append(String(id))  # seen once shown, so quitting never repeats it
	_save.save_profile()
	panel.show_hint(id, _text(id))


func _on_map_shown() -> void:
	request(&"map")
	for node: MapNode in _run.map.get_choices():
		if node.kind == RunMap.Kind.ELITE:
			request(&"elite")


## The tip's text with its actions' current keys.
func _text(id: StringName) -> String:
	var text: String = _told.get(id, HINTS.get(id, ""))
	for action: StringName in [&"interact", &"start_wave", &"attack", &"dash", &"ultimate"]:
		var bindings: Array[InputEvent] = GameSettings.get_bindings(action)
		text = text.replace("{%s}" % action, GameSettings.describe(bindings[0]) if not bindings.is_empty() else String(action))
	return text

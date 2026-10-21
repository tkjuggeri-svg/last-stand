extends CanvasLayer
## The dev menu (F12, the dev_menu action; debug builds only: tools/ is never exported). Jump to any
## chapter, map node or wave; set the gold; grant any card or relic; spawn any enemy or boss; make the
## hero or the fortress invulnerable; see the run's seed. A debugging aid: it pokes the game through
## Main and the level's systems, never the other way round.

const UPGRADES_DIR: String = "res://data/upgrades"
const RELICS_DIR: String = "res://data/relics"
const ENEMIES_DIR: String = "res://data/enemies"

## Set by Main before it adds the menu.
var main: Node

var _info: Label
var _chapters: OptionButton
var _nodes: OptionButton
var _wave: SpinBox
var _gold: SpinBox
var _boons: OptionButton
var _enemies: OptionButton
var _lane: SpinBox
var _hero_god: CheckButton
var _fortress_god: CheckButton
var _boon_list: Array[UpgradeData] = []
var _enemy_list: Array[EnemyData] = []
var _node_list: Array[MapNode] = []


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_menu"):
		get_viewport().set_input_as_handled()
		visible = not visible
		if visible:
			_refresh()


func _run() -> RunStateNode:
	return get_node("/root/RunState") as RunStateNode


func _level() -> Level:
	return main.call("get_level") as Level


func _refresh() -> void:
	var run: RunStateNode = _run()
	var level: Level = _level()
	var node: MapNode = run.map.get_current() if run.map != null else null
	_info.text = "Seed %d   chapter %d   %s   wave %d" % [run.seed_value, run.chapter_index + 1,
		"row %d %s" % [node.row, RunMap.Kind.keys()[node.kind].to_lower()] if node != null else "start",
		level.run_cycle.get_current_wave_number() if level != null and level.run_cycle != null else 0]
	_chapters.clear()
	for i: int in run.get_chapter_count():
		_chapters.add_item(run.run_data.chapters[i].display_name, i)
	_chapters.select(run.chapter_index)
	_nodes.clear()
	_node_list = run.map.nodes.duplicate() if run.map != null else []
	for map_node: MapNode in _node_list:
		_nodes.add_item("row %d: %s%s" % [map_node.row, RunMap.Kind.keys()[map_node.kind].to_lower(),
			" (%s)" % map_node.event.title if map_node.event != null else ""])
	if level != null:
		_gold.value = level.economy.get_gold()
		_hero_god.button_pressed = (level.get_node("Hero") as Hero).health.invulnerable
		_fortress_god.button_pressed = level.fortress.health.invulnerable


# ---------------------------------------------------------------- actions

func _jump_chapter() -> void:
	_end_fight()
	main.call("jump_to_chapter", _chapters.get_selected_id())
	_refresh()


func _jump_node() -> void:
	if _nodes.selected < 0:
		return
	_end_fight()
	await get_tree().physics_frame
	main.call("jump_to_node", _node_list[_nodes.selected])
	_refresh()


## Ends the running wave, then starts and ends waves until the next one to start is wave `n`.
func _skip_to_wave() -> void:
	var level: Level = _level()
	var target: int = int(_wave.value)
	for _guard: int in 40:
		if level.offers != null and level.offers.is_offer_open():
			level.offers.pick(0)
		level.spawner.end_wave()
		await get_tree().physics_frame
		if level.spawner.get_wave_number() >= target - 1 or not level.spawner.has_next_wave():
			break
		level.run_cycle.start_wave()
		await get_tree().physics_frame
	_refresh()


func _end_fight() -> void:
	var level: Level = _level()
	if level == null:
		return
	if level.offers != null and level.offers.is_offer_open():
		level.offers.pick(0)
	level.spawner.end_wave()


func _set_gold() -> void:
	var economy: Economy = _level().economy
	var target: int = int(_gold.value)
	if target > economy.get_gold():
		economy.earn(target - economy.get_gold(), Economy.Source.REFUND)
	else:
		economy.try_spend(economy.get_gold() - target)


func _grant() -> void:
	if _boons.selected >= 0:
		_level().modifiers.add_upgrade(_boon_list[_boons.selected])


func _spawn() -> void:
	if _enemies.selected >= 0:
		_level().spawner.spawn_extra(_enemy_list[_enemies.selected], int(_lane.value))


func _set_invulnerable(hero: bool, on: bool) -> void:
	var level: Level = _level()
	var health: HealthComponent = (level.get_node("Hero") as Hero).health if hero else level.fortress.health
	health.invulnerable = on


# ---------------------------------------------------------------- the panel

func _build() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -480
	panel.offset_right = -8
	panel.offset_top = 8
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # wider content grows to the left, never off-screen
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title: Label = Label.new()
	title.text = "Dev menu (F12)"
	box.add_child(title)
	_info = Label.new()
	box.add_child(_info)
	_chapters = OptionButton.new()
	_row(box, "Chapter", _chapters, "Go", _jump_chapter)
	_nodes = OptionButton.new()
	_nodes.custom_minimum_size.x = 200
	_row(box, "Node", _nodes, "Go", _jump_node)
	_wave = _spin(1, 30, 1)
	_row(box, "Wave", _wave, "Skip to", _skip_to_wave)
	var end_wave: Button = Button.new()
	end_wave.text = "End this wave"
	end_wave.pressed.connect(func() -> void: _level().spawner.end_wave())
	box.add_child(end_wave)
	_gold = _spin(0, 99999, 50)
	_row(box, "Gold", _gold, "Set", _set_gold)
	_boons = OptionButton.new()
	_boon_list = _load_all(UPGRADES_DIR) + _load_all(RELICS_DIR)
	for data: UpgradeData in _boon_list:
		_boons.add_item(("Relic: %s" if data is RelicData else "%s") % data.display_name)
	_row(box, "Card/relic", _boons, "Grant", _grant)
	_enemies = OptionButton.new()
	for file: String in DirAccess.get_files_at(ENEMIES_DIR):
		if file.ends_with(".tres"):
			var enemy: EnemyData = load(ENEMIES_DIR.path_join(file))
			_enemy_list.append(enemy)
			_enemies.add_item(("Boss: %s" if enemy.is_boss else "%s") % enemy.display_name)
	_lane = _spin(0, 2, 1)
	var spawn_row: HBoxContainer = _row(box, "Enemy", _enemies, "Spawn", _spawn)
	spawn_row.add_child(_lane)
	spawn_row.move_child(_lane, 2)
	_hero_god = CheckButton.new()
	_hero_god.text = "Hero invulnerable"
	_hero_god.toggled.connect(func(on: bool) -> void: _set_invulnerable(true, on))
	box.add_child(_hero_god)
	_fortress_god = CheckButton.new()
	_fortress_god.text = "Fortress invulnerable"
	_fortress_god.toggled.connect(func(on: bool) -> void: _set_invulnerable(false, on))
	box.add_child(_fortress_god)


func _row(box: VBoxContainer, label: String, control: Control, action: String, callback: Callable) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var name_label: Label = Label.new()
	name_label.text = label
	name_label.custom_minimum_size.x = 96
	row.add_child(name_label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	var button: Button = Button.new()
	button.text = action
	button.pressed.connect(callback)
	row.add_child(button)
	box.add_child(row)
	return row


func _spin(low: float, high: float, step: float) -> SpinBox:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = step
	return spin


func _load_all(dir: String) -> Array[UpgradeData]:
	var found: Array[UpgradeData] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			found.append(load(dir.path_join(file)))
	return found

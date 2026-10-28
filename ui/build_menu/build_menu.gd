extends CanvasLayer
## Build / upgrade / sell panel for the slot the hero is standing at. Opens with E (interact); closes
## with E, Esc or by walking away. Shows a card per tower (icon, name, price, Build) with the focused
## or hovered tower's description and stats underneath, or the built tower's level and stats, what
## the next level changes and costs (Upgrade), its two evolutions at level 3 (EvolutionChoice: side
## by side, permanent), and its sell refund.
## Display and intents only: TowerBuilder decides. Never pauses the game.

const COIN: Texture2D = preload("res://assets/sprites/ui/coin.png")
const ERROR_COLOR: Color = UiColors.WARN
const OK_COLOR: Color = UiColors.GOOD
const GOLD_COLOR: Color = UiColors.GOLD

@export var builder: TowerBuilder
@export var economy: Economy

var _slot: BuildSlot = null
## Cost labels of the open option cards, by tower data (recoloured when gold changes).
var _cost_labels: Dictionary = {}

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title
@onready var _message: Label = %Message
## Tower cards, 3 per row.
@onready var _options: GridContainer = %Options
@onready var _tower_info: HBoxContainer = %TowerInfo
@onready var _info_icon: TextureRect = %InfoIcon
@onready var _info_name: Label = %InfoName
@onready var _info_text: Label = %InfoStats
@onready var _sell_button: Button = %SellButton
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _upgrade_info: Label = %UpgradeInfo
@onready var _masterwork_button: Button = %MasterworkButton
@onready var _masterwork_info: Label = %MasterworkInfo
@onready var _details: Label = %Details
@onready var _evolutions: EvolutionChoice = %Evolutions


func _ready() -> void:
	_panel.hide()
	# Autowrap labels report a transient, far too tall minimum until they get their width: re-fit
	# every time the content's minimum changes instead of once.
	_panel.minimum_size_changed.connect(_fit_panel)
	_sell_button.pressed.connect(_on_sell_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_masterwork_button.pressed.connect(_on_masterwork_pressed)
	if builder != null:
		builder.active_slot_changed.connect(_on_active_slot_changed)
		builder.build_failed.connect(_on_build_failed)
		builder.tower_built.connect(_on_tower_built)
		builder.tower_sold.connect(_on_tower_sold)
		builder.tower_upgraded.connect(_on_tower_upgraded)
		builder.tower_masterworked.connect(_on_tower_masterworked)
		builder.upgrade_failed.connect(_on_upgrade_failed)
		builder.tower_evolved.connect(_on_tower_evolved)
	if economy != null:
		economy.gold_changed.connect(_on_gold_changed)


func _unhandled_input(event: InputEvent) -> void:
	if builder == null:
		return
	if event.is_action_pressed("interact"):
		if is_open():
			close()
		elif builder.get_active_slot() != null:
			open(builder.get_active_slot())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and is_open():
		close()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# The level is switched off at Game Over: don't leave the panel hanging.
	if what == NOTIFICATION_DISABLED:
		close()


func is_open() -> bool:
	return _panel.visible


func get_slot() -> BuildSlot:
	return _slot


func open(slot: BuildSlot) -> void:
	_slot = slot
	_message.text = ""
	_rebuild()
	_panel.show()


func close() -> void:
	if _slot != null and is_instance_valid(_slot):
		_slot.show_range(0.0)
		_slot.show_links([])
	_slot = null
	_panel.hide()


## Fills the panel for the current slot: tower choices if empty, tower info and Sell if built.
func _rebuild() -> void:
	for child: Node in _options.get_children():
		child.queue_free()
	_cost_labels.clear()
	var empty: bool = _slot.is_empty()
	_options.visible = empty
	_details.visible = empty
	_tower_info.visible = not empty
	_evolutions.visible = false
	if empty:
		_title.text = "Build a tower"
		for data: TowerData in builder.catalog:
			_options.add_child(_make_card(data))
		_slot.show_range(0.0)
		_slot.show_links([])
		_on_gold_changed(economy.get_gold() if economy != null else 0)
		var first: Button = _options.get_child(0).find_child("Build", true, false) if _options.get_child_count() > 0 else null
		_show_details(builder.catalog[0] if not builder.catalog.is_empty() else null)
		if first != null:
			first.grab_focus.call_deferred()
	else:
		var tower: Tower = _slot.tower
		var data: TowerData = tower.data
		var evolution: TowerEvolution = tower.get_evolution()
		_title.text = "%s   Level %d" % [data.display_name if evolution == null else "%s (%s)" % [evolution.display_name, data.display_name], tower.get_level()]
		_info_icon.texture = TowerIcons.for_level(data, tower.get_level()) if evolution == null else TowerIcons.for_evolution(data, evolution)
		_info_name.text = data.description if evolution == null else evolution.description
		_info_text.text = _stats_text(tower.get_stats()) if evolution == null else (tower.get_stats() as TowerEvolution).key_numbers()
		if not data.synergies.is_empty():
			_info_text.text += "\n" + TowerSynergies.describe(data, tower.get_synergies(), builder.catalog)
		_show_links(data, tower)
		_sell_button.text = "Sell   +%d gold" % builder.refund_for_tower(tower)
		_update_upgrade()
		_update_masterwork()
		_details.text = ""
		_slot.show_rings([[tower.get_attack_range(), tower.get_min_range(), BuildSlot.RANGE_COLOR]])
		if _evolutions.show_for(builder, _slot):
			_evolutions.refresh_gold(economy.get_gold() if economy != null else 0)
		(_upgrade_button if not _upgrade_button.disabled else _sell_button).grab_focus.call_deferred()
	_fit_panel()


## The panel hangs from the bottom edge: fit its height to the content (switching between the
## build cards and the sell view changes it). Called whenever the panel's minimum size changes.
func _fit_panel() -> void:
	_panel.offset_top = _panel.offset_bottom - _panel.get_combined_minimum_size().y


## A card: the tower's icon beside its name and price, and a Build button.
func _make_card(data: TowerData) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = Vector2(196, 0)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = TowerIcons.for_level(data)
	icon.custom_minimum_size = Vector2(64, 80)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	row.add_child(icon)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	row.add_child(column)
	var name_label: Label = Label.new()
	name_label.text = data.display_name
	column.add_child(name_label)
	var cost_row: HBoxContainer = HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 6)
	var coin: TextureRect = TextureRect.new()
	coin.texture = COIN
	coin.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin.custom_minimum_size = Vector2(20, 20)
	cost_row.add_child(coin)
	var cost: Label = Label.new()
	cost.text = str(builder.build_cost(data))
	cost_row.add_child(cost)
	_cost_labels[data] = cost
	column.add_child(cost_row)
	var build_button: Button = Button.new()
	build_button.name = "Build"
	build_button.text = "Build"
	build_button.pressed.connect(func() -> void: builder.build(_slot, data))
	build_button.focus_entered.connect(func() -> void: _preview(data))
	build_button.mouse_entered.connect(func() -> void: _preview(data))
	column.add_child(build_button)
	return card


## Range ring and details for the tower the player is looking at.
func _preview(data: TowerData) -> void:
	_preview_range(data)
	_show_details(data)


func _show_details(data: TowerData) -> void:
	_details.text = "" if data == null else "%s  %s" % [data.description, _stats_text(data.stats_for(1)).replace("\n", ". ")]
	if data != null and not data.synergies.is_empty():
		_details.text += "  " + TowerSynergies.describe(data, [], builder.catalog)


func _preview_range(data: TowerData) -> void:
	if _slot != null and _slot.is_empty():
		_slot.show_range(data.attack_range)
		_show_links(data, null)


## Links from the slot to the towers that pair with `data` there (TowerSynergy).
func _show_links(data: TowerData, except: Tower) -> void:
	var points: Array[Vector2] = []
	for partner: Tower in TowerSynergies.all_partners(data, _slot.global_position, builder.get_towers(), except):
		points.append(partner.global_position)
	_slot.show_links(points)


func _stats_text(stats: TowerTier) -> String:
	var lines: Array[String] = ["Damage %d every %s s, range %d" % [stats.damage, String.num(stats.fire_interval, 2), roundi(stats.attack_range)]]
	if stats.damage <= 0:
		lines[0] = "Every %s s, range %d" % [String.num(stats.fire_interval, 2), roundi(stats.attack_range)]
	if stats.targets > 1:
		lines[0] += ", %d targets" % stats.targets
	if stats.pierce > 0:
		lines.append("Passes through %d more enem%s" % [stats.pierce, "y" if stats.pierce == 1 else "ies"])
	if stats.burn_dps > 0.0:
		lines.append("Burns %d/s for %s s within %d px" % [roundi(stats.burn_dps), String.num(stats.burn_duration, 1), roundi(stats.burn_radius)])
	if stats.splash_radius > 0.0:
		lines.append("Explodes: hits all enemies within %d px" % roundi(stats.splash_radius))
	if stats.slow_factor < 1.0:
		lines.append("Slows to %d%% speed for %.1f s%s" % [roundi(stats.slow_factor * 100.0), stats.slow_duration,
			" (all within %d px)" % roundi(stats.slow_area) if stats.slow_area > 0.0 else ""])
	return "\n".join(lines)


## The Upgrade button and the "what changes" line for the open tower.
func _update_upgrade() -> void:
	if _slot == null or _slot.is_empty():
		return
	var tower: Tower = _slot.tower
	var cost: int = builder.upgrade_cost(_slot)
	if cost < 0:
		if not builder.can_evolve():
			_upgrade_info.text = "Highest level. %s." % TowerBuilder.NO_EVOLUTIONS
		else:
			_upgrade_info.text = "Choose an evolution below: it is for good." if not builder.evolution_options(_slot).is_empty() else "Highest level."
		_upgrade_button.text = "Evolved" if tower.is_evolved() else "Max level"
		_upgrade_button.disabled = true
		return
	var next: TowerTier = tower.preview_level(tower.get_level() + 1)
	_upgrade_info.text = "Level %d: %s" % [tower.get_level() + 1, next.describe_changes(tower.get_stats())]
	_upgrade_button.text = "Upgrade   -%d gold" % cost
	_upgrade_button.disabled = economy != null and not economy.can_afford(cost)


## The Masterwork button and its line: "+8% power a rank, now +16%", or what unlocks it.
func _update_masterwork() -> void:
	if _slot == null or _slot.is_empty():
		return
	var tower: Tower = _slot.tower
	var cost: int = builder.masterwork_cost(_slot)
	var rank: int = tower.get_masterwork()
	if cost < 0:
		_masterwork_info.text = "Masterwork (from level %d): +%d%% power a rank." % [builder.masterwork_min_level, roundi(builder.masterwork_power * 100.0)]
		_masterwork_button.text = "Masterwork"
		_masterwork_button.disabled = true
		return
	_masterwork_info.text = "Masterwork rank %d: +%d%% power now, +%d%% after the next." % [rank, roundi(builder.masterwork_power * rank * 100.0),
		roundi(builder.masterwork_power * (rank + 1) * 100.0)]
	_masterwork_button.text = "Masterwork %d   -%d gold" % [rank + 1, cost]
	_masterwork_button.disabled = economy != null and not economy.can_afford(cost)


func _on_masterwork_pressed() -> void:
	if _slot != null:
		builder.masterwork(_slot)


func _on_tower_masterworked(slot: BuildSlot, _tower: Tower, rank: int) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Masterwork rank %d." % rank, OK_COLOR)
		Sfx.play(self, &"tower_upgrade")


func _on_gold_changed(gold: int) -> void:
	_update_upgrade()
	_update_masterwork()
	if _evolutions.visible:
		_evolutions.refresh_gold(gold)
	for data: TowerData in _cost_labels:
		var label: Label = _cost_labels[data]
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", GOLD_COLOR if gold >= builder.build_cost(data) else ERROR_COLOR)


func _on_upgrade_pressed() -> void:
	if _slot != null:
		builder.upgrade(_slot)


func _on_tower_upgraded(slot: BuildSlot, tower: Tower, level: int) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Upgraded to level %d." % level, OK_COLOR)
		Sfx.play(self, &"tower_upgrade")
		_slot.show_range(tower.get_attack_range())


func _on_tower_evolved(slot: BuildSlot, _tower: Tower, evolution: TowerEvolution) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Evolved into %s." % evolution.display_name, OK_COLOR)
		Sfx.play(self, &"tower_evolve")


func _on_upgrade_failed(slot: BuildSlot, reason: String) -> void:
	if slot == _slot:
		_show_message(reason, ERROR_COLOR)


func _on_sell_pressed() -> void:
	if _slot != null:
		builder.sell(_slot)


func _on_build_failed(slot: BuildSlot, data: TowerData, reason: String) -> void:
	if slot != _slot:
		return
	if reason == TowerBuilder.NOT_ENOUGH_GOLD:
		_show_message("Not enough gold! %s costs %d." % [data.display_name, builder.build_cost(data)], ERROR_COLOR)
	else:
		_show_message(reason, ERROR_COLOR)


func _on_tower_built(slot: BuildSlot, tower: Tower) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Built %s for %d gold." % [tower.data.display_name, tower.invested], OK_COLOR)
		Sfx.play(self, &"tower_build")


func _on_tower_sold(slot: BuildSlot, refund: int) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Sold for %d gold." % refund, GOLD_COLOR)
		Sfx.play(self, &"tower_sell")


func _on_active_slot_changed(slot: BuildSlot) -> void:
	if is_open() and slot != _slot:
		close()


func _show_message(text: String, color: Color) -> void:
	if color == ERROR_COLOR:
		Sfx.play(self, &"ui_error")
	_message.text = text
	_message.add_theme_color_override("font_color", color)

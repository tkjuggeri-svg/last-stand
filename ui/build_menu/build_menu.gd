extends CanvasLayer
## Build / sell panel for the slot the hero is standing at. Opens with E (interact); closes with E,
## Esc or by walking away. Shows each tower's name, price and description, or the built tower's
## stats and sell refund. Display and intents only: TowerBuilder decides. Never pauses the game.

const TOWER_FRAMES: SpriteFrames = preload("res://entities/towers/tower_frames.tres")
const COIN: Texture2D = preload("res://assets/sprites/ui/coin.png")
const ERROR_COLOR: Color = Color(1.0, 0.47, 0.4, 1)
const OK_COLOR: Color = Color(0.6, 0.9, 0.5, 1)
const GOLD_COLOR: Color = Color(0.95, 0.82, 0.45, 1)

@export var builder: TowerBuilder
@export var economy: Economy

var _slot: BuildSlot = null
## Cost labels of the open option cards, by tower data (recoloured when gold changes).
var _cost_labels: Dictionary = {}

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title
@onready var _message: Label = %Message
@onready var _options: HBoxContainer = %Options
@onready var _tower_info: HBoxContainer = %TowerInfo
@onready var _info_icon: TextureRect = %InfoIcon
@onready var _info_name: Label = %InfoName
@onready var _info_text: Label = %InfoStats
@onready var _sell_button: Button = %SellButton


func _ready() -> void:
	_panel.hide()
	_sell_button.pressed.connect(_on_sell_pressed)
	if builder != null:
		builder.active_slot_changed.connect(_on_active_slot_changed)
		builder.build_failed.connect(_on_build_failed)
		builder.tower_built.connect(_on_tower_built)
		builder.tower_sold.connect(_on_tower_sold)
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
	_slot = null
	_panel.hide()


## Fills the panel for the current slot: tower choices if empty, tower info and Sell if built.
func _rebuild() -> void:
	for child: Node in _options.get_children():
		child.queue_free()
	_cost_labels.clear()
	var empty: bool = _slot.is_empty()
	_options.visible = empty
	_tower_info.visible = not empty
	if empty:
		_title.text = "Build a tower"
		for data: TowerData in builder.catalog:
			_options.add_child(_make_card(data))
		_slot.show_range(0.0)
		_on_gold_changed(economy.get_gold() if economy != null else 0)
		var first: Button = _options.get_child(0).get_node("Build") if _options.get_child_count() > 0 else null
		if first != null:
			first.grab_focus.call_deferred()
	else:
		var data: TowerData = _slot.tower.data
		_title.text = data.display_name
		_info_icon.texture = _icon_for(data)
		_info_name.text = data.description
		_info_text.text = _stats_text(data)
		_sell_button.text = "Sell   +%d gold" % builder.refund_for(data)
		_slot.show_range(data.attack_range)
		_sell_button.grab_focus.call_deferred()


func _make_card(data: TowerData) -> Control:
	var card: VBoxContainer = VBoxContainer.new()
	card.custom_minimum_size = Vector2(190, 0)
	card.add_theme_constant_override("separation", 4)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var icon: TextureRect = TextureRect.new()
	icon.texture = _icon_for(data)
	icon.custom_minimum_size = Vector2(48, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top.add_child(icon)
	var name_box: VBoxContainer = VBoxContainer.new()
	var name_label: Label = Label.new()
	name_label.text = data.display_name
	name_box.add_child(name_label)
	var cost_row: HBoxContainer = HBoxContainer.new()
	var coin: TextureRect = TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(16, 16)
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_row.add_child(coin)
	var cost: Label = Label.new()
	cost.text = str(data.cost)
	cost_row.add_child(cost)
	_cost_labels[data] = cost
	name_box.add_child(cost_row)
	top.add_child(name_box)
	card.add_child(top)
	var description: Label = Label.new()
	description.text = data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(190, 0)
	description.add_theme_font_size_override("font_size", 12)
	card.add_child(description)
	var build_button: Button = Button.new()
	build_button.name = "Build"
	build_button.text = "Build"
	build_button.pressed.connect(func() -> void: builder.build(_slot, data))
	build_button.focus_entered.connect(func() -> void: _preview_range(data))
	build_button.mouse_entered.connect(func() -> void: _preview_range(data))
	card.add_child(build_button)
	return card


func _preview_range(data: TowerData) -> void:
	if _slot != null and _slot.is_empty():
		_slot.show_range(data.attack_range)


func _icon_for(data: TowerData) -> Texture2D:
	return TOWER_FRAMES.get_frame_texture(StringName("%s_idle" % data.id), 0)


func _stats_text(data: TowerData) -> String:
	var lines: Array[String] = ["Damage %d every %.1f s, range %d" % [data.damage, data.fire_interval, roundi(data.attack_range)]]
	if data.splash_radius > 0.0:
		lines.append("Explodes: hits all enemies within %d px" % roundi(data.splash_radius))
	if data.slow_factor < 1.0:
		lines.append("Slows to %d%% speed for %.1f s" % [roundi(data.slow_factor * 100.0), data.slow_duration])
	return "\n".join(lines)


func _on_gold_changed(gold: int) -> void:
	for data: TowerData in _cost_labels:
		var label: Label = _cost_labels[data]
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", GOLD_COLOR if gold >= data.cost else ERROR_COLOR)


func _on_sell_pressed() -> void:
	if _slot != null:
		builder.sell(_slot)


func _on_build_failed(slot: BuildSlot, data: TowerData, reason: String) -> void:
	if slot != _slot:
		return
	if reason == TowerBuilder.NOT_ENOUGH_GOLD:
		_show_message("Not enough gold! %s costs %d." % [data.display_name, data.cost], ERROR_COLOR)
	else:
		_show_message(reason, ERROR_COLOR)


func _on_tower_built(slot: BuildSlot, tower: Tower) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Built %s for %d gold." % [tower.data.display_name, tower.data.cost], OK_COLOR)


func _on_tower_sold(slot: BuildSlot, refund: int) -> void:
	if slot == _slot:
		_rebuild()
		_show_message("Sold for %d gold." % refund, GOLD_COLOR)


func _on_active_slot_changed(slot: BuildSlot) -> void:
	if is_open() and slot != _slot:
		close()


func _show_message(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)

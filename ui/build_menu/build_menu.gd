extends CanvasLayer
## Build / sell panel for the slot the hero is standing at. Opens with E (interact); closes with E,
## Esc or by walking away. Shows a card per tower (icon, name, price, Build) with the focused or
## hovered tower's description and stats underneath, or the built tower's stats and sell refund.
## Display and intents only: TowerBuilder decides. Never pauses the game.

const TOWER_FRAMES: SpriteFrames = preload("res://entities/towers/tower_frames.tres")
const COIN: Texture2D = preload("res://assets/sprites/ui/coin.png")
const ERROR_COLOR: Color = Color(1.0, 0.47, 0.4, 1)
const OK_COLOR: Color = Color(0.6, 0.9, 0.5, 1)
const GOLD_COLOR: Color = Color(0.94, 0.82, 0.48, 1)
## Part of a tower frame used as its menu icon (art px): skip the empty sky above the tallest tower.
const ICON_TOP: float = 4.0
const ICON_SIZE: Vector2 = Vector2(32, 40)

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
@onready var _details: Label = %Details


func _ready() -> void:
	_panel.hide()
	# Autowrap labels report a transient, far too tall minimum until they get their width: re-fit
	# every time the content's minimum changes instead of once.
	_panel.minimum_size_changed.connect(_fit_panel)
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
	_details.visible = empty
	_tower_info.visible = not empty
	if empty:
		_title.text = "Build a tower"
		for data: TowerData in builder.catalog:
			_options.add_child(_make_card(data))
		_slot.show_range(0.0)
		_on_gold_changed(economy.get_gold() if economy != null else 0)
		var first: Button = _options.get_child(0).find_child("Build", true, false) if _options.get_child_count() > 0 else null
		_show_details(builder.catalog[0] if not builder.catalog.is_empty() else null)
		if first != null:
			first.grab_focus.call_deferred()
	else:
		var data: TowerData = _slot.tower.data
		_title.text = data.display_name
		_info_icon.texture = _icon_for(data)
		_info_name.text = data.description
		_info_text.text = _stats_text(data)
		_sell_button.text = "Sell   +%d gold" % builder.refund_for(data)
		_details.text = ""
		_slot.show_range(_slot.tower.get_attack_range())
		_sell_button.grab_focus.call_deferred()
	_fit_panel()


## The panel hangs from the bottom edge: fit its height to the content (switching between the
## build cards and the sell view changes it). Called whenever the panel's minimum size changes.
func _fit_panel() -> void:
	_panel.offset_top = _panel.offset_bottom - _panel.get_combined_minimum_size().y


## A card: the tower's icon beside its name and price, and a Build button.
func _make_card(data: TowerData) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = Vector2(240, 0)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = _icon_for(data)
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
	cost.text = str(data.cost)
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
	_details.text = "" if data == null else "%s  %s" % [data.description, _stats_text(data).replace("\n", ". ")]


func _preview_range(data: TowerData) -> void:
	if _slot != null and _slot.is_empty():
		_slot.show_range(data.attack_range)


## The upper part of the tower's first idle frame (32x40 art px), shown at the 2x art scale.
func _icon_for(data: TowerData) -> Texture2D:
	var frame: AtlasTexture = TOWER_FRAMES.get_frame_texture(StringName("%s_idle" % data.id), 0) as AtlasTexture
	if frame == null:
		return null
	var image: Image = frame.atlas.get_image().get_region(Rect2i(Rect2(frame.region.position + Vector2(0, ICON_TOP), ICON_SIZE)))
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


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

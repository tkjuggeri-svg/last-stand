class_name PressureScreen
extends CanvasLayer
## The Pressure panel (M12), opened from the War Room: every modifier as a switch with its points and what
## it does, the total, its title and the shard bonus. Display and intents only: the front end keeps the
## selection in the profile; PressureRules says what the points are worth.

## The switches changed: the ids now on.
signal selection_changed(ids: Array[String])

var _options: Array[PressureData] = []
var _on: Array[String] = []

@onready var _total: Label = %Total
@onready var _rows: VBoxContainer = %Rows
@onready var _close: Button = %CloseButton


func _ready() -> void:
	hide()
	_close.pressed.connect(hide)


## Shows `options` with the ones in `selected` (ids) on, best Pressure played and best won by this hero.
func open(options: Array[PressureData], selected: Array[String]) -> void:
	_options = options
	_on = selected.duplicate()
	_build()
	show()
	_close.grab_focus.call_deferred()


## The switch of modifier `id` (tests).
func get_switch(id: StringName) -> CheckButton:
	var row: Node = _rows.get_node_or_null(NodePath(String(id)))
	return row.find_child("Switch", true, false) as CheckButton if row != null else null


func get_total_text() -> String:
	return _total.text


func _build() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for data: PressureData in _options:
		_rows.add_child(_row(data))
	_update_total()


func _row(data: PressureData) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = String(data.id)
	row.add_theme_constant_override("separation", 12)
	var toggle: CheckButton = CheckButton.new()
	toggle.name = "Switch"
	toggle.custom_minimum_size = Vector2(340, 0)
	toggle.text = "%s  +%d" % [data.display_name, data.points]
	toggle.set_pressed_no_signal(_on.has(String(data.id)))
	toggle.toggled.connect(func(pressed: bool) -> void: _toggle(data, pressed))
	row.add_child(toggle)
	var text: Label = Label.new()
	text.theme_type_variation = &"DimLabel"
	text.text = data.text
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row


func _toggle(data: PressureData, pressed: bool) -> void:
	var id: String = String(data.id)
	if pressed and not _on.has(id):
		_on.append(id)
	elif not pressed:
		_on.erase(id)
	_update_total()
	selection_changed.emit(_on.duplicate())


func _update_total() -> void:
	var total: int = 0
	for data: PressureData in _options:
		if _on.has(String(data.id)):
			total += data.points
	var title: String = PressureRules.title(total)
	_total.text = "Pressure %d%s  (shards x%.1f)" % [total, " · %s" % title if title != "" else "", PressureRules.shard_multiplier(total)]

class_name SettingsMenu
extends PanelContainer
## Settings: fullscreen or windowed, Master / Music / SFX volume, and two bindings for every
## rebindable action (click a binding, then press a key or mouse button; Esc cancels). Every change
## is applied and saved at once through GameSettings. UI only: GameSettings owns the rules.

signal closed

const WAITING_TEXT: String = "Press a key..."

## The binding button waiting for an input (null when none).
var _listening: Button = null
var _listening_action: StringName = &""
var _listening_slot: int = 0

@onready var _fullscreen: CheckButton = %Fullscreen
@onready var _bindings: GridContainer = %Bindings
@onready var _back_button: Button = %BackButton
@onready var _reset_button: Button = %ResetButton
@onready var _sliders: Dictionary = {&"Master": %MasterSlider, &"Music": %MusicSlider, &"SFX": %SfxSlider}


func _ready() -> void:
	hide()
	_fullscreen.toggled.connect(GameSettings.set_fullscreen)
	for bus: StringName in _sliders:
		var slider: HSlider = _sliders[bus]
		slider.value_changed.connect(func(value: float) -> void: _on_volume_changed(bus, value))
	_back_button.pressed.connect(close)
	_reset_button.pressed.connect(_on_reset_pressed)


func open() -> void:
	_fullscreen.set_pressed_no_signal(GameSettings.is_fullscreen())
	for bus: StringName in _sliders:
		(_sliders[bus] as HSlider).set_value_no_signal(roundf(GameSettings.get_volume(bus) * 100.0))
		_update_volume_label(bus)
	_build_bindings()
	show()
	_back_button.grab_focus.call_deferred()


func close() -> void:
	_stop_listening()
	hide()
	closed.emit()


func is_listening() -> bool:
	return _listening != null


## The binding button of `action` in `slot` (for the keyboard and tests).
func get_binding_button(action: StringName, slot: int) -> Button:
	return _bindings.get_node_or_null("%s_%d" % [action, slot]) as Button


func _input(event: InputEvent) -> void:
	if _listening == null or not event.is_pressed() or event.is_echo():
		return
	var key: InputEventKey = event as InputEventKey
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if key == null and mouse == null:
		return
	get_viewport().set_input_as_handled()
	if key != null and key.physical_keycode == KEY_ESCAPE:
		_stop_listening()
		return
	var binding: InputEvent
	if key != null:
		var new_key: InputEventKey = InputEventKey.new()
		new_key.physical_keycode = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		binding = new_key
	else:
		var new_mouse: InputEventMouseButton = InputEventMouseButton.new()
		new_mouse.button_index = mouse.button_index
		binding = new_mouse
	GameSettings.bind(_listening_action, _listening_slot, binding)
	_stop_listening()
	_build_bindings()


func _build_bindings() -> void:
	for child: Node in _bindings.get_children():
		_bindings.remove_child(child)
		child.queue_free()
	for action: StringName in GameSettings.ACTIONS:
		var label: Label = Label.new()
		label.text = GameSettings.ACTION_NAMES[action]
		label.custom_minimum_size = Vector2(260, 0)
		_bindings.add_child(label)
		var events: Array[InputEvent] = GameSettings.get_bindings(action)
		for slot: int in GameSettings.SLOTS:
			var button: Button = Button.new()
			button.name = "%s_%d" % [action, slot]
			button.custom_minimum_size = Vector2(190, 36)
			button.text = GameSettings.describe(events[slot]) if slot < events.size() else "-"
			button.pressed.connect(_listen.bind(button, action, slot))
			_bindings.add_child(button)


func _listen(button: Button, action: StringName, slot: int) -> void:
	_stop_listening()
	_listening = button
	_listening_action = action
	_listening_slot = slot
	button.text = WAITING_TEXT


func _stop_listening() -> void:
	if _listening != null and is_instance_valid(_listening):
		var events: Array[InputEvent] = GameSettings.get_bindings(_listening_action)
		_listening.text = GameSettings.describe(events[_listening_slot]) if _listening_slot < events.size() else "-"
	_listening = null


func _on_volume_changed(bus: StringName, value: float) -> void:
	GameSettings.set_volume(bus, value / 100.0)
	_update_volume_label(bus)


func _update_volume_label(bus: StringName) -> void:
	var slider: HSlider = _sliders[bus]
	(slider.get_parent().get_node("Value") as Label).text = "%d%%" % roundi(slider.value)


func _on_reset_pressed() -> void:
	GameSettings.reset_bindings()
	GameSettings.save()
	_build_bindings()

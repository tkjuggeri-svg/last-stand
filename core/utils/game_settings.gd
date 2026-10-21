class_name GameSettings
## The player's settings (static, no autoload): window mode, the volume of the Master, Music and SFX
## audio buses, and the key/mouse bindings of every rebindable action. Saved to a ConfigFile in
## user:// on every change; Main loads and applies them at startup. Defaults come from the project
## (its input map, full volume, windowed).

const ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right", &"attack", &"dash",
	&"interact", &"start_wave", &"pause", &"feedback"]
const ACTION_NAMES: Dictionary = {
	&"move_up": "Move up", &"move_down": "Move down", &"move_left": "Move left", &"move_right": "Move right",
	&"attack": "Attack", &"dash": "Dash", &"interact": "Build / interact", &"start_wave": "Start wave", &"pause": "Pause",
	&"feedback": "Send feedback",
}
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]
## Bindings per action (shown as two slots in the settings menu).
const SLOTS: int = 2

## Where the settings are saved (tests point it elsewhere).
static var path: String = "user://settings.cfg"
static var _fullscreen: bool = false
static var _volumes: Dictionary = {}


## Reads the saved settings (if any) and applies them: window mode, volumes, bindings.
static func load_and_apply() -> void:
	var config: ConfigFile = ConfigFile.new()
	var loaded: bool = config.load(path) == OK
	_fullscreen = loaded and bool(config.get_value("display", "fullscreen", false))
	for bus: StringName in BUSES:
		_volumes[bus] = float(config.get_value("audio", String(bus), 1.0)) if loaded else 1.0
	reset_bindings()
	if loaded:
		for action: StringName in ACTIONS:
			var saved: Variant = config.get_value("bindings", String(action), null)
			if saved is Array:
				InputMap.action_erase_events(action)
				for code: Variant in saved:
					var event: InputEvent = decode(String(code))
					if event != null:
						InputMap.action_add_event(action, event)
	_apply_window()
	for bus: StringName in BUSES:
		_apply_volume(bus)


static func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "fullscreen", _fullscreen)
	for bus: StringName in BUSES:
		config.set_value("audio", String(bus), get_volume(bus))
	for action: StringName in ACTIONS:
		var codes: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var code: String = encode(event)
			if not code.is_empty():
				codes.append(code)
		config.set_value("bindings", String(action), codes)
	config.save(path)


static func is_fullscreen() -> bool:
	return _fullscreen


static func set_fullscreen(on: bool) -> void:
	_fullscreen = on
	_apply_window()
	save()


## 0 (silent) .. 1 (full) for one of BUSES.
static func get_volume(bus: StringName) -> float:
	return float(_volumes.get(bus, 1.0))


static func set_volume(bus: StringName, volume: float) -> void:
	_volumes[bus] = clampf(volume, 0.0, 1.0)
	_apply_volume(bus)
	save()


## The action's bindings, in slot order (at most SLOTS).
static func get_bindings(action: StringName) -> Array[InputEvent]:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	return events.slice(0, SLOTS)


## Binds `event` to `action` in `slot` (replacing what was there). The same key or button is taken
## off every other action first, so one input never does two things.
static func bind(action: StringName, slot: int, event: InputEvent) -> void:
	for other: StringName in ACTIONS:
		for existing: InputEvent in InputMap.action_get_events(other):
			if encode(existing) == encode(event):
				InputMap.action_erase_event(other, existing)
	var events: Array[InputEvent] = get_bindings(action)
	if slot < events.size():
		events[slot] = event
	else:
		events.append(event)
	InputMap.action_erase_events(action)
	for e: InputEvent in events:
		InputMap.action_add_event(action, e)
	save()


## Back to the project's input map for every rebindable action (not saved by itself).
static func reset_bindings() -> void:
	for action: StringName in ACTIONS:
		InputMap.action_erase_events(action)
		var setting: Dictionary = ProjectSettings.get_setting("input/" + String(action), {})
		for event: InputEvent in setting.get("events", []):
			InputMap.action_add_event(action, event)


## A short text for a binding ("W", "Space", "Left mouse").
static func describe(event: InputEvent) -> String:
	var key: InputEventKey = event as InputEventKey
	if key != null:
		var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		# The key's name on this keyboard layout (a physical W is "Z" on AZERTY); headless can't tell.
		var mapped: bool = key.physical_keycode != KEY_NONE and DisplayServer.get_name() != "headless"
		var label: Key = DisplayServer.keyboard_get_keycode_from_physical(code) if mapped else code
		return OS.get_keycode_string(label if label != KEY_NONE else code)
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null:
		match mouse.button_index:
			MOUSE_BUTTON_LEFT:
				return "Left mouse"
			MOUSE_BUTTON_RIGHT:
				return "Right mouse"
			MOUSE_BUTTON_MIDDLE:
				return "Middle mouse"
		return "Mouse %d" % mouse.button_index
	return "?"


## "key:<physical keycode>" or "mouse:<button>"; "" for anything else.
static func encode(event: InputEvent) -> String:
	var key: InputEventKey = event as InputEventKey
	if key != null:
		return "key:%d" % (key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null:
		return "mouse:%d" % mouse.button_index
	return ""


static func decode(code: String) -> InputEvent:
	var parts: PackedStringArray = code.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	if parts[0] == "key":
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = int(parts[1]) as Key
		return key
	if parts[0] == "mouse":
		var mouse: InputEventMouseButton = InputEventMouseButton.new()
		mouse.button_index = int(parts[1]) as MouseButton
		return mouse
	return null


static func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


static func _apply_volume(bus: StringName) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var volume: float = get_volume(bus)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))

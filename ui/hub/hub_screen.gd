class_name HubScreen
extends CanvasLayer
## The War Room between runs (M8): the Soul Shards, the Quartermaster's line about the last run, the
## unlock board (each unlock with what it adds, its price or what it needs first, and Buy), the records,
## and Start a run / Tips / Reset progress / back to the title. Display and intents only: Main's front
## end applies the rules (MetaProgress) and refreshes it.

signal start_requested
signal back_requested
signal buy_requested(unlock: UnlockData)
signal tips_toggled(on: bool)
signal reset_requested

@onready var _shards: Label = %Shards
@onready var _line: Label = %Line
@onready var _unlocks: VBoxContainer = %Unlocks
@onready var _records: Label = %Records
@onready var _start_button: Button = %StartButton
@onready var _tips_button: CheckButton = %TipsButton
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton
@onready var _confirm: ConfirmationDialog = %ConfirmReset


func _ready() -> void:
	hide()
	_start_button.pressed.connect(func() -> void: start_requested.emit())
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_tips_button.toggled.connect(func(on: bool) -> void: tips_toggled.emit(on))
	_reset_button.pressed.connect(func() -> void: _confirm.popup_centered())
	_confirm.confirmed.connect(func() -> void: reset_requested.emit())


func open(profile: SaveProfile, board: UnlockBoard) -> void:
	refresh(profile, board)
	show()
	_start_button.grab_focus.call_deferred()


## Shows `profile` against `board`: shards, the line, every unlock's state, the records.
func refresh(profile: SaveProfile, board: UnlockBoard) -> void:
	_shards.text = "Soul Shards: %d" % profile.shards
	_line.text = "%s: \"%s\"" % [HubLines.SPEAKER, HubLines.line_for(profile)]
	_tips_button.set_pressed_no_signal(not profile.hints_off)
	for child: Node in _unlocks.get_children():
		_unlocks.remove_child(child)  # now, so the new rows get their unlock's name
		child.queue_free()
	for unlock: UnlockData in board.unlocks:
		_unlocks.add_child(_row(unlock, MetaProgress.blocker(profile, board, unlock)))
	_records.text = "Best: %s\nRuns: %d   Won: %d\nBosses beaten: %s\nShards earned in all: %d" % [
		"chapter %d, row %d" % [profile.best_chapter, profile.best_row] if profile.best_chapter > 0 else "no run yet",
		profile.runs, profile.wins,
		", ".join(profile.bosses) if not profile.bosses.is_empty() else "none yet", profile.shards_total]
	if not profile.run.is_empty():
		_records.text += "\n\nA run is saved: Continue it from the title. A new run abandons it."


## The Buy button of unlock `id` (tests).
func get_buy_button(id: StringName) -> Button:
	var row: Node = _unlocks.get_node_or_null(NodePath(String(id)))
	return row.find_child("Buy", true, false) as Button if row != null else null


func get_start_button() -> Button:
	return _start_button


func _row(unlock: UnlockData, blocker: String) -> Control:
	var row: PanelContainer = PanelContainer.new()
	row.name = String(unlock.id)
	row.theme_type_variation = &"CardPanel"
	var line: HBoxContainer = HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)
	var icon: TextureRect = TextureRect.new()
	# One width for every icon (towers are bigger than cards), so the names line up; never scaled.
	icon.custom_minimum_size = Vector2(64, 64)
	icon.clip_contents = true
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _icon(unlock)
	line.add_child(icon)
	var text: VBoxContainer = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.theme_type_variation = &"HeaderLabel"
	title.text = unlock.display_name
	text.add_child(title)
	var description: Label = Label.new()
	description.theme_type_variation = &"DimLabel"
	description.text = unlock.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(description)
	line.add_child(text)
	var buy: Button = Button.new()
	buy.name = "Buy"
	buy.custom_minimum_size = Vector2(190, 44)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if blocker == MetaProgress.OWNED:
		buy.text = "Unlocked"
		buy.disabled = true
	else:
		buy.text = "Buy  %d" % unlock.cost if blocker.is_empty() or blocker == MetaProgress.NEEDS_SHARDS else blocker
		buy.disabled = not blocker.is_empty()
		buy.tooltip_text = "%d Soul Shards" % unlock.cost
	buy.pressed.connect(func() -> void: buy_requested.emit(unlock))
	line.add_child(buy)
	return row


func _icon(unlock: UnlockData) -> Texture2D:
	if unlock.get_icon() != null:
		return unlock.get_icon()
	var towers: Array[TowerData] = unlock.towers + unlock.evolutions
	return TowerIcons.for_level(towers[0], 1) if not towers.is_empty() else null

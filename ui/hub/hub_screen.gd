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
## The player listened to a character's beat (StoryBeat id): the front end records it in the profile.
signal beat_read(beat: StringName)
## The Pressure switches changed (the ids now on): the front end saves the selection.
signal pressure_changed(ids: Array[String])
## The hero buttons: -1 the previous owned hero, 1 the next.
signal hero_cycled(step: int)

# What the Chronicle shows: the profile and story of the last refresh.
var _profile: SaveProfile
var _book: StoryBook
var _pressure_options: Array[PressureData] = []
var _pressure_selected: Array[String] = []

@onready var _shards: Label = %Shards
@onready var _cast: HBoxContainer = %Cast
@onready var _chronicle_button: Button = %ChronicleButton
@onready var _chronicle: ChronicleScreen = %ChronicleScreen
@onready var _pressure_button: Button = %PressureButton
@onready var _pressure_screen: PressureScreen = %PressureScreen
@onready var _beat_dialog: AcceptDialog = %BeatDialog
@onready var _unlocks: VBoxContainer = %Unlocks
@onready var _hero_name: Label = %HeroName
@onready var _hero_text: Label = %HeroText
@onready var _hero_prev: Button = %HeroPrev
@onready var _hero_next: Button = %HeroNext
@onready var _records: Label = %Records
@onready var _start_button: Button = %StartButton
@onready var _tips_button: CheckButton = %TipsButton
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton
@onready var _confirm: ConfirmationDialog = %ConfirmReset


func _ready() -> void:
	hide()
	_pressure_button.pressed.connect(func() -> void: _pressure_screen.open(_pressure_options, _pressure_selected))
	_pressure_screen.selection_changed.connect(func(ids: Array[String]) -> void:
		_pressure_selected = ids
		_refresh_pressure_button()
		pressure_changed.emit(ids))
	_chronicle_button.pressed.connect(func() -> void: _chronicle.open(_profile, _book))
	_start_button.pressed.connect(func() -> void: start_requested.emit())
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_hero_prev.pressed.connect(func() -> void: hero_cycled.emit(-1))
	_hero_next.pressed.connect(func() -> void: hero_cycled.emit(1))
	_tips_button.toggled.connect(func(on: bool) -> void: tips_toggled.emit(on))
	_reset_button.pressed.connect(func() -> void: _confirm.popup_centered())
	_confirm.confirmed.connect(func() -> void: reset_requested.emit())


func open(profile: SaveProfile, board: UnlockBoard, hero: HeroData = null, can_cycle: bool = false, book: StoryBook = null, pressure: Array[PressureData] = []) -> void:
	refresh(profile, board, hero, can_cycle, book, pressure)
	show()
	_start_button.grab_focus.call_deferred()


## Shows `profile` against `board`: shards, the line, the hero of the next run, every unlock's state, the records.
func refresh(profile: SaveProfile, board: UnlockBoard, hero: HeroData = null, can_cycle: bool = false, book: StoryBook = null, pressure: Array[PressureData] = []) -> void:
	_hero_prev.visible = can_cycle
	_hero_next.visible = can_cycle
	_hero_name.text = hero.display_name if hero != null else ""
	_hero_text.text = hero.description if hero != null else ""
	_shards.text = "Soul Shards: %d" % profile.shards
	_show_cast(profile, book)
	_pressure_options = pressure
	_pressure_selected = profile.pressure_selection.duplicate()
	_pressure_button.visible = profile.pressure_open() and not pressure.is_empty()
	_refresh_pressure_button()
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


func get_pressure_screen() -> PressureScreen:
	return _pressure_screen


func get_pressure_button() -> Button:
	return _pressure_button


func get_chronicle() -> ChronicleScreen:
	return _chronicle


func get_chronicle_button() -> Button:
	return _chronicle_button


## The Listen button of `character` (tests); null when they have nothing to tell.
func get_listen_button(character: StringName) -> Button:
	var card: Node = _cast.get_node_or_null(NodePath(String(character)))
	return card.find_child("Listen", true, false) as Button if card != null else null


## The line `character` shows now (tests).
func get_cast_line(character: StringName) -> String:
	var card: Node = _cast.get_node_or_null(NodePath(String(character)))
	var label: Label = card.find_child("Line", true, false) as Label if card != null else null
	return label.text if label != null else ""


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


func _show_cast(profile: SaveProfile, book: StoryBook) -> void:
	_profile = profile
	_book = book
	_chronicle_button.visible = book != null
	for child: Node in _cast.get_children():
		_cast.remove_child(child)
		child.queue_free()
	if book == null:
		return
	for character: StoryCharacter in book.characters:
		_cast.add_child(_card(character, Story.line_for(book, profile, character.id), Story.next_beat(book, profile, character.id)))


func _card(character: StoryCharacter, line: String, beat: StoryBeat) -> Control:
	var card: HBoxContainer = HBoxContainer.new()
	card.name = String(character.id)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 8)
	var face: TextureRect = TextureRect.new()
	# The bust's top: the face and shoulders fit a short card; never scaled.
	face.custom_minimum_size = Vector2(Portraits.FRAME, 80)
	face.clip_contents = true
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP
	face.texture = Portraits.texture(character.portrait)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_child(face)
	var text: VBoxContainer = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var who: Label = Label.new()
	who.text = character.display_name
	text.add_child(who)
	var said: Label = Label.new()
	said.name = "Line"
	said.theme_type_variation = &"DimLabel"
	said.text = "\"%s\"" % line if line != "" else ""
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(said)
	if beat != null:
		var listen: Button = Button.new()
		listen.name = "Listen"
		listen.text = "Listen: %s" % beat.title
		listen.pressed.connect(func() -> void: _tell(beat, character))
		text.add_child(listen)
	card.add_child(text)
	return card


func _tell(beat: StoryBeat, character: StoryCharacter) -> void:
	_beat_dialog.title = "%s: %s" % [character.display_name, beat.title]
	_beat_dialog.dialog_text = beat.text
	_beat_dialog.popup_centered(Vector2i(900, 0))
	beat_read.emit(beat.id)


func _refresh_pressure_button() -> void:
	var total: int = 0
	for data: PressureData in _pressure_options:
		if _pressure_selected.has(String(data.id)):
			total += data.points
	_pressure_button.text = "Pressure %d" % total if total > 0 else "Pressure"

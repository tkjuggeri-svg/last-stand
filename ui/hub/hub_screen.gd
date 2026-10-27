class_name HubScreen
extends CanvasLayer
## The War Room between runs (M8): the Soul Shards, a line about the last run, the hero of the next run, the
## Council (M14: the three characters, each selling their share of the unlock board, UnlockData.seller), the
## records, and Start a run / Tips / Reset progress / back to the title. Display and intents only: Main's front
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

## The pages of the War Room, in the order of their tabs.
enum Page { HEROES, COUNCIL, RECORDS }

## Width of the story dialog (px) and the most of the screen it may take.
const STORY_WIDTH: float = 900.0
const STORY_SCREEN_SHARE: float = 0.9
## The tallest the scrolling text may be (of the screen's height), its least height and the room around the text (px).
const STORY_HEIGHT_SHARE: float = 0.55
const STORY_MIN_HEIGHT: float = 120.0
const STORY_PADDING: float = 24.0

# What the Chronicle shows: the profile and story of the last refresh.
var _profile: SaveProfile
var _book: StoryBook
# The unlock whose Buy was pressed last: once it is owned, its seller says one of their sale lines.
var _just_bought: UnlockData
var _pressure_options: Array[PressureData] = []
var _pressure_selected: Array[String] = []

# The hero shown in the panel (for their story).
var _hero: HeroData
var _story_scroll: ScrollContainer
var _story_text: Label

@onready var _shards: Label = %Shards
@onready var _tabs: Array[Button] = [%TabHeroes, %TabCouncil, %TabRecords]
@onready var _pages: Array[Control] = [%HeroPage, %CouncilPage, %RecordsPage]
@onready var _cast: VBoxContainer = %Cast
@onready var _greeting: Label = %Greeting
@onready var _chronicle_button: Button = %ChronicleButton
@onready var _chronicle: ChronicleScreen = %ChronicleScreen
@onready var _pressure_button: Button = %PressureButton
@onready var _pressure_screen: PressureScreen = %PressureScreen
@onready var _beat_dialog: AcceptDialog = %BeatDialog
@onready var _unlocks: VBoxContainer = %Unlocks
@onready var _hero_name: Label = %HeroName
@onready var _hero_text: Label = %HeroText
@onready var _hero_portrait: TextureRect = %HeroPortrait
@onready var _hero_story_name: Label = %HeroStoryName
@onready var _hero_story_button: Button = %HeroStoryButton
@onready var _hero_story_line: Label = %HeroStoryLine
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
	var group: ButtonGroup = ButtonGroup.new()
	for index: int in _tabs.size():
		_tabs[index].button_group = group
		_tabs[index].pressed.connect(show_page.bind(index))
	show_page(Page.COUNCIL)
	_pressure_button.pressed.connect(func() -> void: _pressure_screen.open(_pressure_options, _pressure_selected))
	_pressure_screen.selection_changed.connect(func(ids: Array[String]) -> void:
		_pressure_selected = ids
		_refresh_pressure_button()
		pressure_changed.emit(ids))
	_chronicle_button.pressed.connect(func() -> void: _chronicle.open(_profile, _book))
	_hero_story_button.pressed.connect(_tell_hero_story)
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
	_show_hero_story(hero)
	_shards.text = "Soul Shards: %d" % profile.shards
	_show_council(profile, board, book)
	_pressure_options = pressure
	_pressure_selected = profile.pressure_selection.duplicate()
	_pressure_button.visible = profile.pressure_open() and not pressure.is_empty()
	_refresh_pressure_button()
	_tips_button.set_pressed_no_signal(not profile.hints_off)
	_records.text = "Best: %s\nRuns: %d   Won: %d\nBosses beaten: %s\nShards earned in all: %d" % [
		"chapter %d, row %d" % [profile.best_chapter, profile.best_row] if profile.best_chapter > 0 else "no run yet",
		profile.runs, profile.wins,
		", ".join(profile.bosses) if not profile.bosses.is_empty() else "none yet", profile.shards_total]
	var owned: int = board.unlocks.filter(func(u: UnlockData) -> bool: return MetaProgress.blocker(profile, board, u) == MetaProgress.OWNED).size()
	_records.text += "\nUnlocked: %d of %d (the Council sells the rest)" % [owned, board.unlocks.size()]
	if profile.pressure_best > 0:
		_records.text += "\nHighest Pressure: %d (%s)" % [profile.pressure_best, PressureRules.title(profile.pressure_best)]
	if not profile.pressure_wins.is_empty():
		var best_win: int = 0
		for points: Variant in profile.pressure_wins.values():
			best_win = maxi(best_win, int(points))
		if best_win > 0:
			_records.text += "\nWon at Pressure: %d (%s)" % [best_win, PressureRules.title(best_win)]
	if not profile.depth_best.is_empty():
		var deepest: int = 0
		for depth: Variant in profile.depth_best.values():
			deepest = maxi(deepest, int(depth))
		_records.text += "\nDeepest descent: %d" % deepest
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


## Shows one page (a Page value); the tab of the page you are on stays pressed.
func show_page(page: int) -> void:
	for index: int in _pages.size():
		_pages[index].visible = index == page
		_tabs[index].set_pressed_no_signal(index == page)
	_greeting.visible = page != Page.COUNCIL  # there the first voice is on its own card already


## The page showing now (tests).
func get_page() -> int:
	return _pages.find_custom(func(p: Control) -> bool: return p.visible)


## The height the screen's content needs at least (tests: it must stay within the base viewport).
func get_required_height() -> float:
	return ($Frame/Margin as Control).get_combined_minimum_size().y


## The card of `character` (tests).
func get_cast_card(character: StringName) -> Control:
	return _cast.get_node_or_null(NodePath(String(character))) as Control


## The Listen button of `character` (tests); null when they have nothing to tell.
func get_listen_button(character: StringName) -> Button:
	var card: Node = _cast.get_node_or_null(NodePath(String(character)))
	return card.find_child("Listen", true, false) as Button if card != null else null


## The line `character` shows now (tests).
func get_cast_line(character: StringName) -> String:
	var card: Node = _cast.get_node_or_null(NodePath(String(character)))
	var label: Label = card.find_child("Line", true, false) as Label if card != null else null
	return label.text if label != null else ""


## The Buy button of unlock `id` (tests), on its seller's card or in the plain list.
func get_buy_button(id: StringName) -> Button:
	var row: Node = (_pages[Page.COUNCIL] as Node).find_child(String(id), true, false)
	return row.find_child("Buy", true, false) as Button if row != null else null


## The ids of the unlocks on `character`'s card (tests).
func get_wares(character: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	var card: Node = _cast.get_node_or_null(NodePath(String(character)))
	var shelf: Node = card.find_child("Wares", true, false) if card != null else null
	if shelf != null:
		for row: Node in shelf.get_children():
			ids.append(StringName(row.name))
	return ids


func get_start_button() -> Button:
	return _start_button


## The Council: each character's card with their line, Listen, and the unlocks they sell; unlocks nobody in the story
## sells (or every unlock, without a story) in the plain list under the cards.
func _show_council(profile: SaveProfile, board: UnlockBoard, book: StoryBook) -> void:
	_profile = profile
	_book = book
	_chronicle_button.visible = book != null
	for box: Node in [_cast, _unlocks]:
		for child: Node in box.get_children():
			box.remove_child(child)  # now, so the new rows and cards get their names
			child.queue_free()
	_greeting.text = ""
	var sellers: Array[StringName] = []
	if book != null:
		for character: StoryCharacter in book.characters:
			sellers.append(character.id)
	for unlock: UnlockData in board.unlocks:
		if not sellers.has(unlock.seller):
			_unlocks.add_child(_unlock_row(profile, board, unlock))
	if book == null:
		return
	for character: StoryCharacter in book.characters:
		var line: String = Story.line_for(book, profile, character.id)
		var wares: Array[Control] = []
		var for_sale: bool = false
		for unlock: UnlockData in board.unlocks:
			if unlock.seller == character.id:
				wares.append(_unlock_row(profile, board, unlock))
				for_sale = for_sale or MetaProgress.blocker(profile, board, unlock) != MetaProgress.OWNED
		if _just_bought != null and _just_bought.seller == character.id and MetaProgress.blocker(profile, board, _just_bought) == MetaProgress.OWNED \
				and not character.sale_lines.is_empty():
			line = character.sale_lines[board.unlocks.find(_just_bought) % character.sale_lines.size()]
		var beat: StoryBeat = Story.next_beat(book, profile, character.id)
		_cast.add_child(HubCards.council_card(character, line, beat, func() -> void: _tell(beat, character), wares, not wares.is_empty() and not for_sale))
		if _greeting.text.is_empty() and line != "":
			# The first voice greets you on every page; the Council page has the rest.
			_greeting.text = "%s: \"%s\"" % [character.display_name, line]
	_just_bought = null


func _unlock_row(profile: SaveProfile, board: UnlockBoard, unlock: UnlockData) -> Control:
	return HubCards.unlock_row(unlock, MetaProgress.blocker(profile, board, unlock), func() -> void:
		_just_bought = unlock
		buy_requested.emit(unlock))


func _tell(beat: StoryBeat, character: StoryCharacter) -> void:
	_show_story("%s: %s" % [character.display_name, beat.title], beat.text)
	beat_read.emit(beat.id)


## The project theme for the dialog window (a Window does not inherit the screen's theme).
func theme_of_screen() -> Theme:
	return load("res://ui/theme/game_theme.tres") as Theme


## A story in the dialog: the text scrolls inside a box that never grows past the screen (the long ones used to run off it).
func _show_story(title: String, text: String) -> void:
	if _story_text == null:
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_story_text = Label.new()
		_story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_story_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(_story_text)
		_story_scroll = scroll
		_beat_dialog.add_child(scroll)
		_beat_dialog.theme = theme_of_screen()
	var view: Vector2 = get_viewport().get_visible_rect().size
	var width: float = minf(STORY_WIDTH, view.x * STORY_SCREEN_SHARE)
	# As tall as the text needs, up to most of the screen (the rest of the dialog is its title and button).
	var font: Font = _story_text.get_theme_font(&"font")
	var needed: float = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width - STORY_PADDING, _story_text.get_theme_font_size(&"font_size")).y
	_story_scroll.custom_minimum_size = Vector2(width, clampf(needed + STORY_PADDING, STORY_MIN_HEIGHT, view.y * STORY_HEIGHT_SHARE))
	_beat_dialog.title = title
	_story_text.text = text
	_beat_dialog.reset_size()
	_beat_dialog.popup_centered()


func _refresh_pressure_button() -> void:
	var total: int = 0
	for data: PressureData in _pressure_options:
		if _pressure_selected.has(String(data.id)):
			total += data.points
	_pressure_button.text = "Pressure %d" % total if total > 0 else "Pressure"


func _show_hero_story(hero: HeroData) -> void:
	_hero = hero
	var has_story: bool = hero != null and not hero.story_name.is_empty()
	_hero_portrait.visible = has_story
	_hero_story_name.visible = has_story
	_hero_story_button.visible = has_story
	_hero_story_line.visible = has_story
	if not has_story:
		return
	_hero_portrait.texture = Portraits.texture(hero.portrait_index)
	_hero_story_name.text = hero.story_name
	_hero_story_line.text = hero.story_line


func _tell_hero_story() -> void:
	if _hero == null:
		return
	_show_story("%s, %s" % [_hero.story_name, _hero.display_name], _hero.story_text)


## The hero story's button (tests).
func get_hero_story_button() -> Button:
	return _hero_story_button


## The story dialog (tests).
func get_story_dialog() -> AcceptDialog:
	return _beat_dialog


func get_hero_story_line() -> String:
	return _hero_story_line.text

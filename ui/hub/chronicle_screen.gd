class_name ChronicleScreen
extends CanvasLayer
## The Chronicle (M11), opened from the War Room: the foes met, the places entered, what the people
## have told and the endings seen. Locked entries show only their hint. Display only: Story says what is
## unlocked.

const FOES: int = 0
const PLACES: int = 1
const PEOPLE: int = 2
const ENDINGS: int = 3
const LOCKED_TITLE: String = "???"

@onready var _tabs: TabContainer = %Tabs
@onready var _close: Button = %CloseButton


func _ready() -> void:
	hide()
	_close.pressed.connect(hide)


func open(profile: SaveProfile, book: StoryBook) -> void:
	for tab: Node in _tabs.get_children():
		for child: Node in tab.get_children():
			tab.remove_child(child)
			child.queue_free()
	if book != null:
		_fill(FOES, _lore(profile, book, LoreEntry.Kind.FOE))
		_fill(PLACES, _lore(profile, book, LoreEntry.Kind.PLACE))
		_fill(PEOPLE, _people(profile, book))
		_fill(ENDINGS, _endings(profile, book))
	_tabs.current_tab = 0
	show()
	_close.grab_focus.call_deferred()


## How many entries a tab shows unlocked, and in all (tests).
func get_counts(tab: int) -> Vector2i:
	var rows: Node = _tabs.get_child(tab).get_node_or_null("Rows")
	if rows == null:
		return Vector2i.ZERO
	var open_rows: int = 0
	for row: Node in rows.get_children():
		if not row.has_meta("locked"):
			open_rows += 1
	return Vector2i(open_rows, rows.get_child_count())


func _lore(profile: SaveProfile, book: StoryBook, kind: LoreEntry.Kind) -> Array[Array]:
	var rows: Array[Array] = []
	for entry: LoreEntry in book.lore:
		if entry.kind == kind:
			var unlocked: bool = Story.is_unlocked(entry, profile)
			rows.append([entry.title if unlocked else LOCKED_TITLE, entry.text if unlocked else entry.hint, not unlocked])
	return rows


func _people(profile: SaveProfile, book: StoryBook) -> Array[Array]:
	var rows: Array[Array] = []
	for character: StoryCharacter in book.characters:
		for beat: StoryBeat in Story.heard_beats(book, profile, character.id):
			rows.append(["%s: %s" % [character.display_name, beat.title], beat.text, false])
	if rows.is_empty():
		rows.append(["Nobody has told you anything yet", "Visit the War Room's people and listen.", true])
	return rows


func _endings(profile: SaveProfile, book: StoryBook) -> Array[Array]:
	var rows: Array[Array] = []
	for ending: EndingData in book.endings:
		var seen: bool = profile.endings.has(String(ending.id))
		var hint: String = "Held the night to its end." if not ending.secret else "Something waits beyond the three endings."
		rows.append([ending.title if seen else LOCKED_TITLE, ending.text if seen else hint, not seen])
	return rows


func _fill(tab: int, rows: Array[Array]) -> void:
	var scroll: ScrollContainer = _tabs.get_child(tab) as ScrollContainer
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "Rows"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	for data: Array in rows:
		var panel: PanelContainer = PanelContainer.new()
		panel.theme_type_variation = &"CardPanel"
		if data[2]:
			panel.set_meta("locked", true)
		var text: VBoxContainer = VBoxContainer.new()
		var title: Label = Label.new()
		title.theme_type_variation = &"HeaderLabel"
		title.text = data[0]
		text.add_child(title)
		var body: Label = Label.new()
		body.theme_type_variation = &"DimLabel"
		body.text = data[1]
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(body)
		panel.add_child(text)
		box.add_child(panel)

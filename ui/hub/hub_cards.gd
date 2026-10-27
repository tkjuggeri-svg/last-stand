class_name HubCards
## The War Room's building blocks (display only): an unlock's row (icon, name, what it adds, its price or what it
## needs first, and Buy) and a Council card (a character's portrait, line, Listen, then the unlocks they sell).
## The hub wires the buttons to its intents through the callables.

## The line a seller with nothing left shows under their card.
const SOLD_OUT: String = "Nothing more to sell you. For now."


## One unlock: `blocker` is MetaProgress.blocker's answer for it; `on_buy` is called when Buy is pressed.
static func unlock_row(unlock: UnlockData, blocker: String, on_buy: Callable) -> Control:
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
	buy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # a long reason wraps instead of widening the whole screen
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if blocker == MetaProgress.OWNED:
		buy.text = "Unlocked"
		buy.disabled = true
	else:
		buy.text = "Buy  %d" % unlock.cost if blocker.is_empty() or blocker == MetaProgress.NEEDS_SHARDS else blocker
		buy.disabled = not blocker.is_empty()
		buy.tooltip_text = "%d Soul Shards" % unlock.cost
	buy.pressed.connect(on_buy)
	line.add_child(buy)
	return row


## A character's card: their line (quoted, or nothing), Listen when `beat` is ready (`on_listen`), and `wares`
## (their unlock rows) under it; `sold_out` shows SOLD_OUT instead when they sell things but none are left to buy.
static func council_card(character: StoryCharacter, line: String, beat: StoryBeat, on_listen: Callable, wares: Array[Control], sold_out: bool) -> Control:
	var frame: PanelContainer = PanelContainer.new()
	frame.name = String(character.id)
	frame.theme_type_variation = &"CardPanel"
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	frame.add_child(column)
	var card: HBoxContainer = HBoxContainer.new()
	card.add_theme_constant_override("separation", 12)
	column.add_child(card)
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
	who.text = "%s, %s" % [character.display_name, character.role] if not character.role.is_empty() else character.display_name
	who.theme_type_variation = &"HeaderLabel"
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
		listen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # a long title wraps, so the card can shrink at big interface sizes
		listen.pressed.connect(on_listen)
		text.add_child(listen)
	card.add_child(text)
	if not wares.is_empty():
		var shelf: VBoxContainer = VBoxContainer.new()
		shelf.name = "Wares"
		shelf.add_theme_constant_override("separation", 6)
		for row: Control in wares:
			shelf.add_child(row)
		column.add_child(shelf)
	if sold_out:
		var done: Label = Label.new()
		done.name = "SoldOut"
		done.theme_type_variation = &"DimLabel"
		done.text = SOLD_OUT
		column.add_child(done)
	return frame


static func _icon(unlock: UnlockData) -> Texture2D:
	if unlock.get_icon() != null:
		return unlock.get_icon()
	var towers: Array[TowerData] = unlock.towers + unlock.evolutions
	return TowerIcons.for_level(towers[0], 1) if not towers.is_empty() else null

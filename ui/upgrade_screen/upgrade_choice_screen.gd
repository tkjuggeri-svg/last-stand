class_name UpgradeChoiceScreen
extends CanvasLayer
## The upgrade choice after a wave: shows the open offer as cards (icon, name, rarity and category,
## what it does) and pauses the game until one is taken. Mouse or keyboard (arrows to move, Enter to
## take). One reroll per offer for gold. Display and intents only: UpgradeOffers decides. A relic offer
## (an elite's or a boss's reward) says so in its title and on each card.

const CATEGORY_NAMES: Dictionary = {
	UpgradeData.Category.HERO: "Hero",
	UpgradeData.Category.TOWERS: "Towers",
	UpgradeData.Category.FORTRESS: "Fortress",
	UpgradeData.Category.ECONOMY: "Economy",
}
const CARD_SIZE: Vector2 = Vector2(236, 236)
const CARD_TITLE: String = "Choose an upgrade"
const RELIC_TITLE: String = "Choose a relic"

@export var offers: UpgradeOffers
@export var economy: Economy

## True while this screen holds the game paused (so it only ever unpauses its own pause).
var _paused_by_us: bool = false

@onready var _cards: HBoxContainer = %Cards
@onready var _reroll_button: Button = %RerollButton
@onready var _gold_label: Label = %GoldLabel
@onready var _title: Label = %Title


func _ready() -> void:
	hide()
	_reroll_button.pressed.connect(_on_reroll_pressed)
	if offers != null:
		offers.offer_made.connect(_open)
		offers.picked.connect(func(data: UpgradeData) -> void:
			Sfx.play(self, &"relic_pick" if data is RelicData else &"upgrade_pick")
			_close())
	if economy != null:
		economy.gold_changed.connect(func(_gold: int) -> void: _update_reroll())


func _exit_tree() -> void:
	if _paused_by_us:
		get_tree().paused = false


func is_open() -> bool:
	return visible


## The Take buttons, in card order (for the keyboard and tests).
func get_take_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for card: Node in _cards.get_children():
		if not card.is_queued_for_deletion():
			buttons.append(card.find_child("Take", true, false) as Button)
	return buttons


func _open(cards: Array[UpgradeData]) -> void:
	if cards.is_empty():
		return  # nothing left to offer: no choice to make
	for child: Node in _cards.get_children():
		child.queue_free()
	for i: int in cards.size():
		_cards.add_child(_make_card(cards[i], i))
	_title.text = RELIC_TITLE if not cards.is_empty() and cards[0] is RelicData else CARD_TITLE
	_update_reroll()
	show()
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_us = true
	var first: Button = _cards.get_child(_cards.get_child_count() - cards.size()).find_child("Take", true, false)
	first.grab_focus.call_deferred()


func _close() -> void:
	hide()
	if _paused_by_us:
		get_tree().paused = false
		_paused_by_us = false


func _make_card(data: UpgradeData, index: int) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = UiColors.card_panel(data)
	card.custom_minimum_size = CARD_SIZE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	# The 32 px icon (16 art px at 2x) shown at exactly twice that: still whole pixels, easy to read.
	var icon: TextureRect = TextureRect.new()
	icon.texture = data.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(icon)
	var title: Label = Label.new()
	title.text = data.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var relic: bool = data is RelicData
	title.theme_type_variation = UiColors.card_title(data)
	column.add_child(title)
	var kind: Label = Label.new()
	if relic:
		kind.text = "Relic  -  %s" % CATEGORY_NAMES[data.category]
	else:
		kind.text = "%s  -  %s%s" % ["Rare" if data.rarity == UpgradeData.Rarity.RARE else "Common", CATEGORY_NAMES[data.category],
			"" if data.stackable else "  -  once"]
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.theme_type_variation = &"DimLabel"
	column.add_child(kind)
	var text: Label = Label.new()
	text.text = data.description
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text)
	var take: Button = Button.new()
	take.name = "Take"
	take.text = "Take"
	take.pressed.connect(func() -> void: offers.pick(index))
	column.add_child(take)
	return card


func _update_reroll() -> void:
	if offers == null:
		_reroll_button.hide()
		return
	_reroll_button.text = "Reroll   -%d gold" % offers.get_reroll_cost() if not offers.is_rerolled() else "Rerolled"
	_reroll_button.disabled = not offers.can_reroll()
	_gold_label.text = str(economy.get_gold()) if economy != null else ""


func _on_reroll_pressed() -> void:
	if offers.reroll():
		Sfx.play(self, &"reroll")

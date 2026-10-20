class_name MerchantScreen
extends CanvasLayer
## A merchant's shop on the run map: the stock's upgrade cards (name, rarity, what it does, price,
## Buy), the fortress repair, a reroll of the cards and Leave. Prices turn red when the gold is short.
## Display and intents only: the Merchant decides.

signal left

const RARE_COLOR: Color = Color(0.94, 0.82, 0.48, 1)
const ERROR_COLOR: Color = Color(1.0, 0.47, 0.4, 1)

var _merchant: Merchant
var _buy_buttons: Array[Button] = []

@onready var _cards: HBoxContainer = %Cards
@onready var _gold_label: Label = %GoldLabel
@onready var _repair_button: Button = %RepairButton
@onready var _reroll_button: Button = %RerollButton
@onready var _leave_button: Button = %LeaveButton


func _ready() -> void:
	hide()
	_repair_button.pressed.connect(func() -> void: _merchant.buy_repair())
	_reroll_button.pressed.connect(func() -> void: _merchant.reroll())
	_leave_button.pressed.connect(_leave)


## Opens the shop of `merchant` (its stock was made by Merchant.open()).
func open(merchant: Merchant) -> void:
	if _merchant != null and _merchant.changed.is_connected(_refresh):
		_merchant.changed.disconnect(_refresh)
		_merchant.economy.gold_changed.disconnect(_on_gold_changed)
	_merchant = merchant
	_merchant.changed.connect(_refresh)
	_merchant.economy.gold_changed.connect(_on_gold_changed)
	_refresh()
	show()
	_leave_button.grab_focus.call_deferred()


func get_buy_button(index: int) -> Button:
	return _buy_buttons[index]


func get_repair_button() -> Button:
	return _repair_button


func get_reroll_button() -> Button:
	return _reroll_button


func get_leave_button() -> Button:
	return _leave_button


func _on_gold_changed(_gold: int) -> void:
	if visible:
		_refresh()


func _leave() -> void:
	hide()
	left.emit()


func _refresh() -> void:
	if _merchant == null:
		return
	for child: Node in _cards.get_children():
		child.queue_free()
	_buy_buttons.clear()
	var cards: Array[UpgradeData] = _merchant.get_cards()
	for i: int in cards.size():
		_cards.add_child(_card(cards[i], i))
	_gold_label.text = "Gold: %d" % _merchant.economy.get_gold()
	var repair: String = _merchant.repair_blocker()
	_repair_button.text = "Repair walls +%d   -%d gold" % [_merchant.repair_amount(), _merchant.get_repair_price()] if repair.is_empty() or repair == Merchant.NOT_ENOUGH_GOLD else "Repair: %s" % repair.to_lower()
	_repair_button.disabled = not repair.is_empty()
	_reroll_button.text = "New cards   -%d gold" % _merchant.get_reroll_price()
	_reroll_button.disabled = not _merchant.can_reroll()


func _card(data: UpgradeData, index: int) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = Vector2(300, 220)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	if data.icon != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = data.icon
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		header.add_child(icon)
	var title: Label = Label.new()
	title.text = data.display_name
	title.add_theme_color_override("font_color", RARE_COLOR if data.rarity == UpgradeData.Rarity.RARE else Color.WHITE)
	header.add_child(title)
	var text: Label = Label.new()
	text.text = data.description
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(270, 0)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text)
	var button: Button = Button.new()
	var blocker: String = _merchant.card_blocker(index)
	button.text = "Sold" if blocker == Merchant.SOLD_OUT else "Buy   -%d gold" % _merchant.price_of(data)
	button.disabled = not blocker.is_empty()
	if blocker == Merchant.NOT_ENOUGH_GOLD:
		button.add_theme_color_override("font_disabled_color", ERROR_COLOR)
	button.pressed.connect(func() -> void: _merchant.buy_card(index))
	column.add_child(button)
	_buy_buttons.append(button)
	return card

class_name MerchantScreen
extends CanvasLayer
## A merchant's shop on the run map: the stock's upgrade cards (name, rarity, what it does, price,
## Buy), a relic when it has one (its own colour), the fortress repair, a reroll of the cards and
## Leave. Prices turn red when the gold is short.
## Display and intents only: the Merchant decides.

signal left


var _merchant: Merchant
var _buy_buttons: Array[Button] = []
var _relic_button: Button = null

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


## The relic's Buy button (null when the merchant has no relic this visit).
func get_relic_button() -> Button:
	return _relic_button


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
		var index: int = i
		var card: Control = _card(cards[i], _merchant.card_blocker(i), func() -> void: _merchant.buy_card(index))
		_buy_buttons.append(card.find_child("Buy", true, false) as Button)
		_cards.add_child(card)
	_relic_button = null
	if _merchant.get_relic() != null:
		var relic_card: Control = _card(_merchant.get_relic(), _merchant.relic_blocker(), func() -> void: _merchant.buy_relic())
		_relic_button = relic_card.find_child("Buy", true, false) as Button
		_cards.add_child(relic_card)
	_gold_label.text = "Gold: %d" % _merchant.economy.get_gold()
	var repair: String = _merchant.repair_blocker()
	_repair_button.text = "Repair walls +%d   -%d gold" % [_merchant.repair_amount(), _merchant.get_repair_price()] if repair.is_empty() or repair == Merchant.NOT_ENOUGH_GOLD else "Repair: %s" % repair.to_lower()
	_repair_button.disabled = not repair.is_empty()
	_reroll_button.text = "New cards   -%d gold" % _merchant.get_reroll_price()
	_reroll_button.disabled = not _merchant.can_reroll()


func _card(data: UpgradeData, blocker: String, buy: Callable) -> Control:
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
	var relic: bool = data is RelicData
	title.text = ("Relic: %s" if relic else "%s") % data.display_name
	title.theme_type_variation = UiColors.card_title(data)
	header.add_child(title)
	var text: Label = Label.new()
	text.text = data.description
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(270, 0)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text)
	var button: Button = Button.new()
	button.name = "Buy"
	button.text = "Sold" if blocker == Merchant.SOLD_OUT else "Buy   -%d gold" % _merchant.price_of(data)
	button.disabled = not blocker.is_empty()
	if blocker == Merchant.NOT_ENOUGH_GOLD:
		button.add_theme_color_override("font_disabled_color", UiColors.WARN)
	button.pressed.connect(buy)
	column.add_child(button)
	return card

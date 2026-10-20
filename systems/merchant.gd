class_name Merchant
extends Node
## A run map merchant's shop on this chapter's level (open() at each visit): a few upgrade cards
## (common or rare price), one repair of the fortress per visit, and a reroll of the cards. Gold
## comes from the level's Economy. Owns the stock and the prices; MerchantScreen only shows and asks.

## The stock, the gold or the repair changed (the screen refreshes).
signal changed

const NOT_ENOUGH_GOLD: String = "Not enough gold"
const SOLD_OUT: String = "Sold"
const WALLS_WHOLE: String = "The walls are whole"

@export var economy: Economy
@export var offers: UpgradeOffers
@export var modifiers: RunModifiers
@export var fortress: Fortress
## Cards in stock per visit.
@export var card_count: int = 3
@export var common_price: int = 90
@export var rare_price: int = 160
## The repair: a share of the fortress's max HP, once per visit.
@export_range(0.0, 1.0) var repair_fraction: float = 0.25
@export var repair_price: int = 60
@export var reroll_price: int = 25

var _cards: Array[UpgradeData] = []
var _sold: Array[bool] = []
var _repaired: bool = false


## A new visit: fresh cards, the repair available again.
func open() -> void:
	_cards = offers.draw_cards(card_count)
	_sold.clear()
	_sold.resize(_cards.size())
	_sold.fill(false)
	_repaired = false
	changed.emit()


func get_cards() -> Array[UpgradeData]:
	return _cards.duplicate()


func price_of(data: UpgradeData) -> int:
	return rare_price if data.rarity == UpgradeData.Rarity.RARE else common_price


func is_sold(index: int) -> bool:
	return index >= 0 and index < _sold.size() and _sold[index]


## Why card `index` can't be bought now ("" = it can).
func card_blocker(index: int) -> String:
	if is_sold(index):
		return SOLD_OUT
	if not economy.can_afford(price_of(_cards[index])):
		return NOT_ENOUGH_GOLD
	return ""


func buy_card(index: int) -> bool:
	if index < 0 or index >= _cards.size() or not card_blocker(index).is_empty():
		return false
	if not economy.try_spend(price_of(_cards[index])):
		return false
	_sold[index] = true
	modifiers.add_upgrade(_cards[index])
	changed.emit()
	return true


## HP the repair would restore now (never past the max).
func repair_amount() -> int:
	var health: HealthComponent = fortress.health
	return mini(roundi(health.max_health * repair_fraction), health.max_health - health.current_health)


func repair_blocker() -> String:
	if _repaired:
		return SOLD_OUT
	if repair_amount() <= 0:
		return WALLS_WHOLE
	if not economy.can_afford(repair_price):
		return NOT_ENOUGH_GOLD
	return ""


func buy_repair() -> bool:
	if not repair_blocker().is_empty() or not economy.try_spend(repair_price):
		return false
	fortress.health.heal(repair_amount())
	_repaired = true
	changed.emit()
	return true


func can_reroll() -> bool:
	return economy.can_afford(reroll_price) and not _cards.is_empty()


## New cards in place of the unsold ones.
func reroll() -> bool:
	if not can_reroll() or not economy.try_spend(reroll_price):
		return false
	var fresh: Array[UpgradeData] = offers.draw_cards(card_count)
	for i: int in _cards.size():
		if not _sold[i] and i < fresh.size():
			_cards[i] = fresh[i]
	changed.emit()
	return true

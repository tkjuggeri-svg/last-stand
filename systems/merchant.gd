class_name Merchant
extends Node
## A run map merchant's shop on this chapter's level (open() at each visit): a few upgrade cards
## (common or rare price), one repair of the fortress per visit, and a reroll of the cards. Gold
## comes from the level's Economy. Owns the stock and the prices; MerchantScreen only shows and asks.
## Sometimes (relic_chance per visit) it also has a relic, at its high RelicData.price (M7.5). Its
## prices follow the run's merchant-price modifiers (Merchant's Seal); Iron Tithe forbids its repair.

## The stock, the gold or the repair changed (the screen refreshes).
signal changed

const NOT_ENOUGH_GOLD: String = "Not enough gold"
const SOLD_OUT: String = "Sold"
const WALLS_WHOLE: String = "The walls are whole"
const NO_REPAIRS: String = "Iron Tithe: no repairs"

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
## Chance that a visit's stock includes a relic.
@export_range(0.0, 1.0) var relic_chance: float = 0.35

## The next visit's prices are multiplied by this (an event's price), then it's back to 1.
var next_price_factor: float = 1.0

var _price_factor: float = 1.0
var _cards: Array[UpgradeData] = []
var _sold: Array[bool] = []
var _repaired: bool = false
## This visit's relic (null: none in stock) and whether it was bought.
var _relic: RelicData = null
var _relic_sold: bool = false


## What a saved run needs to carry on (M8): an event's price for the next visit.
func save_state() -> Dictionary:
	return {"next_price_factor": next_price_factor}


func load_state(state: Dictionary) -> void:
	next_price_factor = float(state.get("next_price_factor", 1.0))


## A new visit: fresh cards, the repair available again.
func open() -> void:
	_price_factor = next_price_factor
	next_price_factor = 1.0
	_cards = offers.draw_cards(card_count)
	_sold.clear()
	_sold.resize(_cards.size())
	_sold.fill(false)
	_repaired = false
	_relic = offers.draw_relic() if offers.roll(relic_chance) else null
	_relic_sold = false
	changed.emit()


func get_cards() -> Array[UpgradeData]:
	return _cards.duplicate()


func price_of(data: UpgradeData) -> int:
	if data is RelicData:
		return _priced((data as RelicData).price)
	return _priced(rare_price if data.rarity == UpgradeData.Rarity.RARE else common_price)


func get_repair_price() -> int:
	return _priced(repair_price)


func get_reroll_price() -> int:
	return _priced(reroll_price)


## This visit's relic (null: none in stock).
func get_relic() -> RelicData:
	return _relic


## Why the relic can't be bought now ("" = it can).
func relic_blocker() -> String:
	if _relic == null or _relic_sold:
		return SOLD_OUT
	if not economy.can_afford(price_of(_relic)):
		return NOT_ENOUGH_GOLD
	return ""


func buy_relic() -> bool:
	if not relic_blocker().is_empty() or not economy.try_spend(price_of(_relic)):
		return false
	_relic_sold = true
	modifiers.add_upgrade(_relic)
	changed.emit()
	return true


func is_relic_sold() -> bool:
	return _relic_sold


## A base price with this visit's factor and the run's merchant-price modifiers.
func _priced(base: int) -> int:
	return roundi(RunModifiers.value(modifiers, base, [RunModifiers.MERCHANT_PRICES]) * _price_factor)


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
	if not fortress.can_repair():
		return NO_REPAIRS
	if repair_amount() <= 0:
		return WALLS_WHOLE
	if not economy.can_afford(get_repair_price()):
		return NOT_ENOUGH_GOLD
	return ""


func buy_repair() -> bool:
	if not repair_blocker().is_empty() or not economy.try_spend(get_repair_price()):
		return false
	fortress.repair_hp(repair_amount())
	_repaired = true
	changed.emit()
	return true


func can_reroll() -> bool:
	return economy.can_afford(get_reroll_price()) and not _cards.is_empty()


## New cards in place of the unsold ones.
func reroll() -> bool:
	if not can_reroll() or not economy.try_spend(get_reroll_price()):
		return false
	var fresh: Array[UpgradeData] = offers.draw_cards(card_count)
	for i: int in _cards.size():
		if not _sold[i] and i < fresh.size():
			_cards[i] = fresh[i]
	changed.emit()
	return true

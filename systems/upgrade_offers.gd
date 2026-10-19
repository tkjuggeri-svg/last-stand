class_name UpgradeOffers
extends Node
## Makes the upgrade offers between waves: offer_size different cards drawn from the pool (rare ones
## less often), never a non-stackable upgrade the run already has. The player takes exactly one
## (pick); once per offer they may reroll it for gold, and the reroll price rises each time it is
## used in the run. Draws come from a seeded RNG, so a run's offers are reproducible (tests, the
## balance tool); seed -1 = a random run. Rules only: the choice screen shows the offer.

signal offer_made(cards: Array[UpgradeData])
signal picked(data: UpgradeData)

@export var modifiers: RunModifiers
@export var economy: Economy
## Every upgrade that can be offered.
@export var pool: Array[UpgradeData] = []
@export var offer_size: int = 3
## Relative chance of a card being drawn, by rarity.
@export var common_weight: float = 3.0
@export var rare_weight: float = 1.0
@export var reroll_base_cost: int = 25
## Each reroll used in the run makes the next one this much dearer.
@export var reroll_cost_step: int = 25
## Seed of the run's RNG; -1 picks a random one.
@export var seed_value: int = -1

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _offer: Array[UpgradeData] = []
var _rerolled: bool = false
var _rerolls_used: int = 0
var _seeded: bool = false


func _ready() -> void:
	assert(modifiers != null, "UpgradeOffers needs RunModifiers: %s" % get_path())
	_ensure_seeded()


## Sets the RNG seed (a fresh, reproducible sequence of offers).
func set_seed(value: int) -> void:
	seed_value = value
	_seeded = false
	_ensure_seeded()


## True if there is anything left to offer.
func has_cards() -> bool:
	return not _candidates().is_empty()


func is_offer_open() -> bool:
	return not _offer.is_empty()


func get_offer() -> Array[UpgradeData]:
	return _offer.duplicate()


## Draws a new offer (replacing any open one) and reports it.
func make_offer() -> Array[UpgradeData]:
	_offer = _draw()
	_rerolled = false
	offer_made.emit(get_offer())
	return get_offer()


## Takes card `index` of the open offer. Returns false if there is no such card.
func pick(index: int) -> bool:
	if index < 0 or index >= _offer.size():
		return false
	var data: UpgradeData = _offer[index]
	_offer.clear()
	modifiers.add_upgrade(data)
	picked.emit(data)
	return true


func get_reroll_cost() -> int:
	return reroll_base_cost + reroll_cost_step * _rerolls_used


## One reroll per offer, if the gold allows.
func can_reroll() -> bool:
	return is_offer_open() and not _rerolled and economy != null and economy.can_afford(get_reroll_cost())


## Pays and draws a fresh offer. Returns false (and changes nothing) if not allowed.
func reroll() -> bool:
	if not can_reroll() or not economy.try_spend(get_reroll_cost()):
		return false
	_rerolls_used += 1
	_offer = _draw()
	_rerolled = true
	offer_made.emit(get_offer())
	return true


func is_rerolled() -> bool:
	return _rerolled


## Seeds the RNG once, on first use (so offers drawn before _ready are seeded too).
func _ensure_seeded() -> void:
	if _seeded:
		return
	_seeded = true
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func _candidates() -> Array[UpgradeData]:
	return pool.filter(func(d: UpgradeData) -> bool: return d != null and modifiers.can_take(d))


## offer_size different cards, weighted by rarity.
func _draw() -> Array[UpgradeData]:
	_ensure_seeded()
	var left: Array[UpgradeData] = _candidates()
	var cards: Array[UpgradeData] = []
	while cards.size() < offer_size and not left.is_empty():
		var weights: PackedFloat32Array = PackedFloat32Array()
		for data: UpgradeData in left:
			weights.append(rare_weight if data.rarity == UpgradeData.Rarity.RARE else common_weight)
		var index: int = _rng.rand_weighted(weights)
		cards.append(left[index])
		left.remove_at(index)
	return cards

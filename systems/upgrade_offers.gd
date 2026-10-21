class_name UpgradeOffers
extends Node
## Makes the upgrade offers between waves: offer_size different cards drawn from the pool (rare ones
## less often), never a non-stackable upgrade the run already has. The player takes exactly one
## (pick); once per offer they may reroll it for gold, and the reroll price rises each time it is
## used in the run. Draws come from a seeded RNG, so a run's offers are reproducible (tests, the
## balance tool); seed -1 = a random run. Rules only: the choice screen shows the offer.
## It also offers relics (M7.5): a relic offer (an elite's or a boss's reward) draws from relic_pool,
## never one the run has or one that works against a relic it has (RelicData.incompatible).

signal offer_made(cards: Array[UpgradeData])
signal picked(data: UpgradeData)

@export var modifiers: RunModifiers
@export var economy: Economy
## Every upgrade that can be offered.
@export var pool: Array[UpgradeData] = []
## Every relic that can be offered or found.
@export var relic_pool: Array[RelicData] = []
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
## Size and rarity rule of the open offer (a reroll keeps them).
var _size: int = 3
var _rare_only: bool = false
## The open offer is of relics (a reroll draws relics again).
var _relics: bool = false


func _ready() -> void:
	assert(modifiers != null, "UpgradeOffers needs RunModifiers: %s" % get_path())
	_size = offer_size
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


## Draws a new offer (replacing any open one) and reports it: `size` cards (-1 = offer_size), only
## rare ones if `rare_only` (the reward of an elite or a boss).
func make_offer(size: int = -1, rare_only: bool = false) -> Array[UpgradeData]:
	_size = offer_size if size < 0 else size
	_rare_only = rare_only
	_relics = false
	_offer = _draw()
	_rerolled = false
	offer_made.emit(get_offer())
	return get_offer()


## Draws a relic offer (replacing any open one): `size` relics the run may take. Empty if none is left.
func make_relic_offer(size: int) -> Array[UpgradeData]:
	_size = size
	_rare_only = false
	_relics = true
	_offer = _draw()
	_rerolled = false
	if not _offer.is_empty():
		offer_made.emit(get_offer())
	return get_offer()


## One relic the run may take, drawn without opening an offer (a merchant's, an event's); null if none.
func draw_relic() -> RelicData:
	_ensure_seeded()
	var left: Array[RelicData] = relic_candidates()
	return left[_rng.randi_range(0, left.size() - 1)] if not left.is_empty() else null


## The relics the run may still get: not taken, not working against one it has.
func relic_candidates() -> Array[RelicData]:
	var owned: Array[StringName] = []
	for relic: RelicData in modifiers.get_relics():
		owned.append(relic.id)
	var found: Array[RelicData] = []
	for relic: RelicData in relic_pool:
		if relic != null and not owned.has(relic.id) and not relic.incompatible.any(func(id: StringName) -> bool: return owned.has(id)) \
				and not modifiers.get_relics().any(func(r: RelicData) -> bool: return r.incompatible.has(relic.id)):
			found.append(relic)
	return found


## True with chance `p`, from the run's seeded RNG (whether a merchant has a relic).
func roll(p: float) -> bool:
	_ensure_seeded()
	return _rng.randf() < p


## Draws `count` cards for a shop (a merchant's stock): weighted like an offer, but no offer is opened.
func draw_cards(count: int) -> Array[UpgradeData]:
	var keep: Array = [_size, _rare_only, _relics]
	_size = count
	_rare_only = false
	_relics = false
	var cards: Array[UpgradeData] = _draw()
	_size = keep[0]
	_rare_only = keep[1]
	_relics = keep[2]
	return cards


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


## The cards that may be drawn (only rare ones if `rare_only`).
func _candidates(rare_only: bool = false) -> Array[UpgradeData]:
	var found: Array[UpgradeData] = []
	for data: UpgradeData in pool:
		if data != null and modifiers.can_take(data) and (not rare_only or data.rarity == UpgradeData.Rarity.RARE):
			found.append(data)
	return found


## offer_size different cards, weighted by rarity.
func _draw() -> Array[UpgradeData]:
	_ensure_seeded()
	var left: Array[UpgradeData] = []
	if _relics:
		left.append_array(relic_candidates())
	else:
		left = _candidates(_rare_only)
	var cards: Array[UpgradeData] = []
	while cards.size() < _size and not left.is_empty():
		var weights: PackedFloat32Array = PackedFloat32Array()
		for data: UpgradeData in left:
			weights.append(rare_weight if data.rarity == UpgradeData.Rarity.RARE else common_weight)
		var index: int = _rng.rand_weighted(weights)
		cards.append(left[index])
		left.remove_at(index)
	return cards

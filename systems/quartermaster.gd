class_name Quartermaster
extends Node
## Gold sinks between waves (build phase only): repair the fortress (each repair costs more than
## the last) and buy back one lost hero life (once per run, dearer the later the wave). Both compete
## with tower upgrades for the same gold. Owns the prices and rules; the HUD's panel only shows them
## and asks.

## Something that changes a price or an availability happened (the panel refreshes).
signal changed
signal fortress_repaired(amount: int, cost: int)
signal life_bought(cost: int)

const NOT_BETWEEN_WAVES: String = "Only between waves"
const NOT_ENOUGH_GOLD: String = "Not enough gold"
const WALLS_WHOLE: String = "The walls are whole"
const NO_LIFE_LOST: String = "No life lost"
const ALREADY_BOUGHT: String = "Only once per run"
const NO_REPAIRS: String = "Iron Tithe: no repairs"

@export var economy: Economy
@export var fortress: Fortress
@export var hero_lives: HeroLives
@export var run_cycle: RunCycle
@export_group("Repair")
## Share of the fortress's max HP one repair restores.
@export_range(0.0, 1.0) var repair_fraction: float = 0.25
@export var repair_base_cost: int = 100
## Added to the price after every repair.
@export var repair_cost_step: int = 50
@export_group("Buy back a life")
@export var life_base_cost: int = 300
## Added to the price for every wave already fought.
@export var life_cost_per_wave: int = 30
@export var max_life_buys: int = 1

var _repairs: int = 0
var _life_buys: int = 0


func _ready() -> void:
	assert(economy != null, "Quartermaster needs an Economy: %s" % get_path())
	assert(fortress != null, "Quartermaster needs a Fortress: %s" % get_path())
	assert(hero_lives != null, "Quartermaster needs HeroLives: %s" % get_path())
	assert(run_cycle != null, "Quartermaster needs a RunCycle: %s" % get_path())
	economy.gold_changed.connect(func(_gold: int) -> void: changed.emit())
	hero_lives.lives_changed.connect(func(_lives: int) -> void: changed.emit())
	run_cycle.phase_changed.connect(func(_phase: RunCycle.Phase) -> void: changed.emit())
	if not fortress.is_node_ready():
		await fortress.ready  # its `health` is set in its _ready()
	fortress.health.health_changed.connect(func(_current: int, _max: int) -> void: changed.emit())


## What a saved run needs to carry on (M8): the repairs and lives bought so far (their prices rise).
func save_state() -> Dictionary:
	return {"repairs": _repairs, "life_buys": _life_buys}


func load_state(state: Dictionary) -> void:
	_repairs = int(state.get("repairs", 0))
	_life_buys = int(state.get("life_buys", 0))
	changed.emit()


func repair_cost() -> int:
	return _priced(repair_base_cost + repair_cost_step * _repairs)


## HP one repair would restore now (never past the max).
func repair_amount() -> int:
	var health: HealthComponent = fortress.health
	return mini(roundi(health.max_health * repair_fraction), health.max_health - health.current_health)


## Why a repair isn't possible now ("" = it is).
func repair_blocker() -> String:
	if run_cycle.get_phase() != RunCycle.Phase.BUILD:
		return NOT_BETWEEN_WAVES
	if not fortress.can_repair():
		return NO_REPAIRS
	if fortress.health.is_dead() or repair_amount() <= 0:
		return WALLS_WHOLE
	if not economy.can_afford(repair_cost()):
		return NOT_ENOUGH_GOLD
	return ""


func repair() -> bool:
	if not repair_blocker().is_empty():
		return false
	var cost: int = repair_cost()
	var amount: int = repair_amount()
	if not economy.try_spend(cost):
		return false
	_repairs += 1
	fortress.repair_hp(amount)
	fortress_repaired.emit(amount, cost)
	changed.emit()
	return true


func get_repair_count() -> int:
	return _repairs


func life_cost() -> int:
	# In the build phase the current wave is the next one, so this counts the waves already fought.
	return _priced(life_base_cost + life_cost_per_wave * maxi(run_cycle.get_current_wave_number() - 1, 0))


## Why buying a life isn't possible now ("" = it is).
func life_blocker() -> String:
	if _life_buys >= max_life_buys:
		return ALREADY_BOUGHT
	if run_cycle.get_phase() != RunCycle.Phase.BUILD:
		return NOT_BETWEEN_WAVES
	if hero_lives.get_lives_left() >= hero_lives.get_max_lives() or hero_lives.get_lives_left() <= 0:
		return NO_LIFE_LOST
	if not economy.can_afford(life_cost()):
		return NOT_ENOUGH_GOLD
	return ""


func buy_life() -> bool:
	if not life_blocker().is_empty():
		return false
	var cost: int = life_cost()
	if not economy.try_spend(cost):
		return false
	_life_buys += 1
	hero_lives.restore_life()
	life_bought.emit(cost)
	changed.emit()
	return true


## Lives still for sale this run.
func get_lives_for_sale() -> int:
	return maxi(max_life_buys - _life_buys, 0)


## A price under the run's Quartermaster-price modifiers (Merchant's Seal makes it dearer).
func _priced(base: int) -> int:
	return roundi(RunModifiers.value(fortress.modifiers, base, [RunModifiers.QUARTERMASTER_PRICES]))

class_name EventResolver
extends Node
## Applies run map events and shrines (EventData) to the chapter's level: whether an answer can be
## chosen (its need: gold, a tower, an upgrade, a spare life), and what it does (gold, damage to the
## fortress, boons and curses as upgrades, a lost life, tower gifts and prices, twists on the next
## fights, merchant prices). Answers that need more play (an upgrade choice, an extra fight) come back
## in the EventOutcome for Main to run. It also keeps the twists that events put on coming fights
## (take_fight_affixes, at each fight's start). Rules only: EventScreen shows the scene.

const NEEDS_GOLD: String = "Not enough gold"
const NEEDS_TOWER: String = "You have no tower"
const NEEDS_UPGRADABLE: String = "No tower can go up a level"
const NEEDS_UPGRADE: String = "You have no upgrade"
const NEEDS_LIFE: String = "Your last life is all you have"

@export var economy: Economy
@export var modifiers: RunModifiers
@export var fortress: Fortress
@export var hero_lives: HeroLives
@export var builder: TowerBuilder
@export var merchant: Merchant

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Twists on the next fights, and how many fights each still has.
var _affixes: Array[AffixData] = []
var _fights_left: Array[int] = []


## Seeds the gambles (a run's results are reproducible).
func set_seed(value: int) -> void:
	_rng.seed = value


## Why `choice` can't be taken now ("" = it can).
func choice_blocker(choice: EventChoice) -> String:
	match choice.need:
		EventChoice.Need.GOLD:
			return "" if economy.can_afford(choice.gold_cost) else NEEDS_GOLD
		EventChoice.Need.TOWER:
			return "" if not _towers().is_empty() else NEEDS_TOWER
		EventChoice.Need.UPGRADABLE_TOWER:
			return "" if _cheapest_upgradable() != null else NEEDS_UPGRADABLE
		EventChoice.Need.UPGRADE:
			return "" if not modifiers.get_taken().is_empty() else NEEDS_UPGRADE
		EventChoice.Need.SPARE_LIFE:
			return "" if hero_lives.get_lives_left() > 1 else NEEDS_LIFE
	return ""


## Takes `choice`: pays its gold, rolls its gamble, applies its effects. Returns what follows (null
## if it can't be taken).
func apply(choice: EventChoice) -> EventOutcome:
	if not choice_blocker(choice).is_empty():
		return null
	if choice.need == EventChoice.Need.GOLD and not economy.try_spend(choice.gold_cost):
		return null
	var outcome: EventOutcome = EventOutcome.new()
	var won: bool = choice.chance >= 1.0 or _rng.randf() < choice.chance
	outcome.text = choice.result_text if won else choice.fail_text
	for effect: EventEffect in (choice.effects if won else choice.fail_effects):
		_apply_effect(effect, outcome)
	return outcome


## The twists for the fight that starts now (each counts the fight; spent ones are dropped).
func take_fight_affixes() -> Array[AffixData]:
	var taken: Array[AffixData] = _affixes.duplicate()
	for i: int in range(_fights_left.size() - 1, -1, -1):
		_fights_left[i] -= 1
		if _fights_left[i] <= 0:
			_affixes.remove_at(i)
			_fights_left.remove_at(i)
	return taken


## The twists waiting for the coming fights (for the map's status line).
func get_pending_affixes() -> Array[AffixData]:
	return _affixes.duplicate()


func _apply_effect(effect: EventEffect, outcome: EventOutcome) -> void:
	match effect.type:
		EventEffect.Type.GOLD:
			if effect.amount >= 0:
				economy.earn(effect.amount, Economy.Source.REWARD)
			else:
				economy.try_spend(mini(-effect.amount, economy.get_gold()))
		EventEffect.Type.GOLD_MULTIPLY:
			economy.earn(roundi(economy.get_gold() * (effect.factor - 1.0)), Economy.Source.REWARD)
		EventEffect.Type.FORTRESS_DAMAGE:
			var health: HealthComponent = fortress.health
			health.take_damage(mini(effect.amount, health.current_health - 1))
		EventEffect.Type.GRANT_UPGRADE:
			modifiers.add_upgrade(effect.upgrade)
		EventEffect.Type.UPGRADE_CHOICE:
			outcome.choices.append(FightReward.make(effect.amount, effect.rare_only))
		EventEffect.Type.LOSE_LIFE:
			hero_lives.lose_life()
		EventEffect.Type.LOSE_LAST_UPGRADE:
			modifiers.remove_last_upgrade()
		EventEffect.Type.FREE_TOWER_LEVEL:
			builder.free_upgrade(_cheapest_upgradable())
		EventEffect.Type.DESTROY_BEST_TOWER:
			builder.demolish(_best_tower())
		EventEffect.Type.FREE_EVOLUTION:
			builder.free_evolutions += 1
		EventEffect.Type.NEXT_FIGHTS_AFFIX:
			_affixes.append(effect.affix)
			_fights_left.append(effect.amount)
		EventEffect.Type.MERCHANT_PRICES:
			merchant.next_price_factor *= effect.factor
		EventEffect.Type.EXTRA_FIGHT:
			outcome.extra_fight = FightReward.make(effect.amount, effect.rare_only)


func _towers() -> Array[BuildSlot]:
	return builder.get_slots().filter(func(s: BuildSlot) -> bool: return not s.is_empty())


## The built tower with the least gold in it that can still go up a level (null if none).
func _cheapest_upgradable() -> BuildSlot:
	var best: BuildSlot = null
	for slot: BuildSlot in _towers():
		if slot.tower.is_max_level() or slot.tower.is_building():
			continue
		if best == null or slot.tower.invested < best.tower.invested:
			best = slot
	return best


## The tower with the highest level (then the most gold in it).
func _best_tower() -> BuildSlot:
	var best: BuildSlot = null
	for slot: BuildSlot in _towers():
		if best == null or slot.tower.get_level() > best.tower.get_level() \
				or (slot.tower.get_level() == best.tower.get_level() and slot.tower.invested > best.tower.invested):
			best = slot
	return best

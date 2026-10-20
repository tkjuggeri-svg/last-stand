extends SceneTree
## Automated check for playing the run map through the real main.tscn: a run starts on the map with the
## chapter's level hidden and frozen; a battle plays its 2 waves with no upgrade choice between them,
## then one choice of 3 and back to the map; gold, damage and towers stay on the level between nodes;
## an elite's reward is a choice of 2 rare cards and bonus gold; the boss's reward repairs the fortress.
## Also the merchant (stock, prices, one repair per visit, rerolls, never without the gold) and the
## elite twists (Swift, Warded, Swarming, Siege, Ironclad) applied to a fight's waves.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BRUTE: EnemyData = preload("res://data/enemies/brute.tres")
const CULTIST: EnemyData = preload("res://data/enemies/cultist.tres")
const AFFIX_DIR: String = "res://data/affixes"

var _failures: int = 0


func _initialize() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_seed", 5)
	root.add_child(main)
	await _frames(3)
	await _test_battle(main)
	await _test_rewards(main)
	await _test_merchant(main)
	_test_affixes()
	await _test_warded_spawn(main)
	main.queue_free()
	await _frames(2)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_battle(main: Node) -> void:
	var level: Level = main.call("get_level")
	var screen: MapScreen = main.get_node("%MapScreen")
	_check("a run starts on the map; the level waits hidden and frozen", screen.visible and not level.is_active()
		and not level.can_process() and not (level.get_node("HUD") as CanvasLayer).visible)
	await MapFixtures.enter_first_battle(main)
	await _frames(2)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	_check("a battle: the level shows, in the build phase of a 2-wave fight", level.is_active() and level.can_process()
		and (level.get_node("HUD") as CanvasLayer).visible and cycle.get_phase() == RunCycle.Phase.BUILD and spawner.get_wave_count() == 2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	builder.build(builder.get_slots()[4], ARCHER)
	spawner.enemy_spawned.connect(_kill)
	cycle.start_wave()
	await _until(func() -> bool: return cycle.get_phase() != RunCycle.Phase.COMBAT, 60 * 40)
	_check("after wave 1: straight to the next build phase, no upgrade choice", cycle.get_phase() == RunCycle.Phase.BUILD and not offers.is_offer_open())
	cycle.start_wave()
	await _until(func() -> bool: return offers.is_offer_open(), 60 * 40)
	_check("after the battle: one upgrade choice of 3", offers.get_offer().size() == 3)
	offers.pick(0)
	await _frames(2)
	_check("then the map again, the level hidden", screen.visible and not level.is_active())
	level.fortress.health.take_damage(20)  # damage taken in the fight (after the reward, which may repair)
	var gold: int = level.economy.get_gold()
	var hp: int = level.fortress.health.current_health
	screen.node_chosen.emit((main.call("get_map") as RunMap).get_choices()[0])  # row 2: a battle
	await _frames(2)
	_check("the next battle is on the same level: gold, damage and towers stay (gold %d, fortress %d)" % [gold, hp],
		main.call("get_level") == level and level.is_active() and level.economy.get_gold() == gold
		and level.fortress.health.current_health == hp and hp < level.fortress.health.max_health and not builder.get_slots()[4].is_empty())
	spawner.enemy_spawned.disconnect(_kill)


## Elite and boss rewards, through the level's fights directly.
func _test_rewards(main: Node) -> void:
	var level: Level = main.call("get_level")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	level.set_active(true)
	spawner.enemy_spawned.connect(_kill)
	var gold: int = level.economy.get_gold()
	level.start_encounter([WaveFixtures.make_wave(1, 0.2)], FightReward.make(2, true, 100))
	cycle.start_wave()
	await _until(func() -> bool: return offers.is_offer_open(), 600)
	var offer: Array[UpgradeData] = offers.get_offer()
	_check("an elite's reward: a choice of 2 rare cards", offer.size() == 2 and offer.all(func(d: UpgradeData) -> bool: return d.rarity == UpgradeData.Rarity.RARE))
	_check("...and its bonus gold (+%d)" % (level.economy.get_gold() - gold), level.economy.get_gold() - gold >= 100)
	offers.pick(0)
	await _frames(2)
	var health: HealthComponent = level.fortress.health
	health.take_damage(50)
	var before: int = health.current_health
	level.set_active(true)
	level.start_encounter([WaveFixtures.make_wave(1, 0.2)], FightReward.make(0, true, 0, 0.4))
	cycle.start_wave()
	await _until(func() -> bool: return health.current_health > before, 600)
	_check("a boss's reward repairs the fortress (%d -> %d)" % [before, health.current_health], health.current_health == mini(before + roundi(health.max_health * 0.4), health.max_health))
	spawner.enemy_spawned.disconnect(_kill)
	await _frames(2)


func _test_merchant(main: Node) -> void:
	var level: Level = main.call("get_level")
	var shop: Merchant = level.merchant
	var economy: Economy = level.economy
	var screen: MerchantScreen = main.get_node("%MerchantScreen")
	economy.try_spend(economy.get_gold())
	economy.earn(300, Economy.Source.KILL)
	level.fortress.health.take_damage(30)
	shop.open()
	screen.open(shop)
	await _frames(2)
	var cards: Array[UpgradeData] = shop.get_cards()
	_check("the merchant offers %d cards at their rarity's price" % cards.size(), cards.size() == shop.card_count
		and cards.all(func(d: UpgradeData) -> bool: return shop.price_of(d) == (shop.rare_price if d.rarity == UpgradeData.Rarity.RARE else shop.common_price)))
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var taken: int = mods.get_taken().size()
	var price: int = shop.price_of(cards[0])
	screen.get_buy_button(0).pressed.emit()
	_check("Buy takes the card for its price", mods.get_taken().size() == taken + 1 and economy.get_gold() == 300 - price and shop.is_sold(0))
	_check("...and it can't be bought twice", not shop.buy_card(0) and shop.card_blocker(0) == Merchant.SOLD_OUT)
	var hp: int = level.fortress.health.current_health
	screen.get_repair_button().pressed.emit()
	_check("the repair: +%d for %d gold, once per visit" % [shop.repair_amount(), shop.repair_price], level.fortress.health.current_health > hp
		and not shop.buy_repair() and shop.repair_blocker() == Merchant.SOLD_OUT)
	var unsold: Array[UpgradeData] = shop.get_cards()
	var gold: int = economy.get_gold()
	screen.get_reroll_button().pressed.emit()
	_check("a reroll costs %d and keeps what was sold" % shop.reroll_price, economy.get_gold() == gold - shop.reroll_price and shop.get_cards()[0] == unsold[0])
	economy.try_spend(economy.get_gold())
	_check("without the gold: no card, no reroll, the buttons disabled", not shop.buy_card(1) and not shop.reroll()
		and screen.get_buy_button(1).disabled and screen.get_reroll_button().disabled)
	shop.open()
	_check("the next visit: a fresh stock and the repair available again", not shop.is_sold(0) and shop.repair_blocker() != Merchant.SOLD_OUT)
	var left: Array[bool] = [false]
	screen.left.connect(func() -> void: left[0] = true)
	screen.get_leave_button().pressed.emit()
	_check("Leave closes the shop and goes back to the map", left[0] and not screen.visible and (main.get_node("%MapScreen") as CanvasLayer).visible)


func _test_affixes() -> void:
	var wave: WaveData = WaveData.new()
	for entry: Array in [[GHOUL, 10], [BRUTE, 2], [CULTIST, 2]]:
		var group: SpawnGroup = SpawnGroup.new()
		group.enemy = entry[0]
		group.count = entry[1]
		wave.groups.append(group)
	var count: Callable = func(w: WaveData, enemy: EnemyData) -> int:
		var n: int = 0
		for group: SpawnGroup in w.groups:
			if group.enemy == enemy:
				n += group.count
		return n
	var swift: WaveData = (load(AFFIX_DIR.path_join("swift.tres")) as AffixData).apply(wave)
	_check("Swift: 25% faster", is_equal_approx(swift.speed_multiplier, 1.25) and count.call(swift, GHOUL) == 10)
	var warded: WaveData = (load(AFFIX_DIR.path_join("warded.tres")) as AffixData).apply(wave)
	_check("Warded: every enemy spawns with a 30 ward", warded.spawn_shield == 30)
	var swarm: WaveData = (load(AFFIX_DIR.path_join("swarming.tres")) as AffixData).apply(wave)
	_check("Swarming: 50%% more enemies, 35%% less HP (ghouls %d)" % count.call(swarm, GHOUL), count.call(swarm, GHOUL) == 15 and is_equal_approx(swarm.health_multiplier, 0.65))
	var siege: WaveData = (load(AFFIX_DIR.path_join("siege.tres")) as AffixData).apply(wave)
	_check("Siege: half the Ghouls become Cultists (%d / %d)" % [count.call(siege, GHOUL), count.call(siege, CULTIST)], count.call(siege, GHOUL) == 5 and count.call(siege, CULTIST) == 7)
	var iron: WaveData = (load(AFFIX_DIR.path_join("ironclad.tres")) as AffixData).apply(wave)
	_check("Ironclad: twice the Brutes, +30% HP", count.call(iron, BRUTE) == 4 and is_equal_approx(iron.health_multiplier, 1.3))
	_check("the data itself is untouched", count.call(wave, GHOUL) == 10 and is_equal_approx(wave.speed_multiplier, 1.0))


func _test_warded_spawn(main: Node) -> void:
	var level: Level = main.call("get_level")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var wave: WaveData = WaveFixtures.make_wave(1, 0.2)
	wave.spawn_shield = 30
	level.set_active(true)
	level.start_encounter([wave], FightReward.make(0))
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	await _until(func() -> bool: return spawner.get_child_count() > 0, 60)
	var enemy: Enemy = spawner.get_child(0)
	_check("a Warded wave's enemy spawns with its ward (%d)" % enemy.get_health().get_shield(), enemy.get_health().get_shield() == 30)


func _kill(enemy: Enemy) -> void:
	enemy.get_health().take_damage.call_deferred(100000)


func _until(condition: Callable, max_frames: int) -> void:
	for _i: int in max_frames:
		if condition.call():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

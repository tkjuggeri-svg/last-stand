extends SceneTree
## Automated check for relics (M7.5): the data (15 rule-changing relics, one of each per run), the
## offers (never one the run has, never one that works against one it has; every relic about as likely
## as any other, in an offer and at a merchant), that an event taking "the
## latest upgrade" never takes a relic, every relic's rule on a real level, the sources (an elite's and
## a boss's relic choice, a merchant's relic, the Drowned Reliquary event, tougher elites) and the HUD's
## own relic row with tooltips.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const R: String = "res://data/relics/"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const CULTIST: EnemyData = preload("res://data/enemies/cultist.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const BRAZIER: TowerData = preload("res://data/towers/brazier.tres")
const HONED: UpgradeData = preload("res://data/upgrades/honed_blade.tres")
const RELIQUARY: EventData = preload("res://data/events/drowned_reliquary.tres")
const RUN: RunData = preload("res://data/run/run.tres")
const HERO_AWAY: Vector2 = Vector2(380, 380)

var _failures: int = 0


func _initialize() -> void:
	await _test_data_and_offers()
	await _test_equal_odds()
	await _test_hourglass()
	await _test_bloodpact()
	await _test_ossuary_bell()
	await _test_siege_ledger()
	await _test_lantern()
	await _test_twin_banners()
	await _test_phoenix()
	await _test_executioner()
	await _test_glass_banner()
	await _test_soul_lantern()
	await _test_drowned_bell()
	await _test_iron_tithe()
	await _test_merchants_seal()
	await _test_second_oath()
	await _test_ember_heart()
	await _test_sources()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _relic(id: String) -> RelicData:
	return load(R + id + ".tres")


# ---------------------------------------------------------------- data and offers

func _test_data_and_offers() -> void:
	var level: Level = await _level([])
	var pool: Array[RelicData] = level.offers.relic_pool
	var ids: Dictionary = {}
	var shaped: bool = true
	for relic: RelicData in pool:
		ids[relic.id] = true
		shaped = shaped and relic.icon != null and not relic.description.is_empty() and not relic.stackable \
			and relic.rarity == UpgradeData.Rarity.RARE and relic.price >= 200 and (relic.rule != &"" or not relic.modifiers.is_empty())
	var rules: int = pool.filter(func(r: RelicData) -> bool: return r.rule != &"").size()
	_check("%d relics, all different, each with an icon, a text, a price and a rule (%d rules)" % [pool.size(), rules],
		pool.size() >= 15 and ids.size() == pool.size() and shaped and rules == pool.size())
	var trade_offs: int = 0
	for relic: RelicData in pool:
		for word: String in [" but ", "fewer", "less gold", "more.", "costs the fortress"]:
			if relic.description.contains(word):
				trade_offs += 1
				break
	_check("some are trade-offs (%d)" % trade_offs, trade_offs >= 5)
	var marsh: Level = (load("res://levels/drowned_marsh.tscn") as PackedScene).instantiate()
	_check("the Drowned Marsh has the same relic pool", (marsh.get_node("%UpgradeOffers") as UpgradeOffers).relic_pool.size() == pool.size())
	marsh.free()
	var offer: Array[UpgradeData] = level.offers.make_relic_offer(3)
	var distinct: bool = offer.size() == 3 and offer[0] != offer[1] and offer[1] != offer[2] and offer[0] != offer[2]
	_check("a relic offer: 3 different relics", distinct and offer.all(func(d: UpgradeData) -> bool: return d is RelicData))
	var taken: UpgradeData = offer[0]
	level.offers.pick(0)
	var again: bool = false
	for _i: int in 40:
		again = again or level.offers.make_relic_offer(3).has(taken)
		level.offers.pick(0)
	_check("one of each per run: a relic taken is never offered again", not again)
	var fresh: Level = await _level([_relic("iron_tithe")])
	var lantern_offered: bool = false
	for _i: int in 30:
		lantern_offered = lantern_offered or fresh.offers.make_relic_offer(pool.size()).any(func(d: UpgradeData) -> bool: return d.id == &"soul_lantern")
		fresh.offers.pick(-1)
	_check("never one that works against a relic it has (Iron Tithe: no Soul Lantern)", not lantern_offered)
	fresh.modifiers.add_upgrade(HONED)
	fresh.modifiers.add_upgrade(_relic("hourglass"))
	var lost: UpgradeData = fresh.modifiers.remove_last_upgrade()
	_check("an event taking \"the latest upgrade\" takes the card, never a relic", lost == HONED and fresh.modifiers.has_relic(&"hourglass"))
	level.queue_free()
	fresh.queue_free()
	await _frames(2)


## Many offers from a fresh pool (nothing taken): every relic comes up about as often as the others.
func _test_equal_odds() -> void:
	var level: Level = await _level([])
	level.offers.set_seed(11)
	var offered: Dictionary = {}
	var stocked: Dictionary = {}
	for _i: int in 1500:
		for data: UpgradeData in level.offers.make_relic_offer(3):
			offered[data.id] = int(offered.get(data.id, 0)) + 1
		var relic: RelicData = level.offers.draw_relic()
		stocked[relic.id] = int(stocked.get(relic.id, 0)) + 1
	var pool: int = level.offers.relic_pool.size()
	_check("every relic about as likely in an offer (%d-%d times each, %d expected)" % [offered.values().min(), offered.values().max(), roundi(1500.0 * 3.0 / pool)],
		offered.size() == pool and _even(offered, 1500.0 * 3.0 / pool, 0.2))
	_check("...and at a merchant (%d-%d times each, %d expected)" % [stocked.values().min(), stocked.values().max(), roundi(1500.0 / pool)],
		stocked.size() == pool and _even(stocked, 1500.0 / pool, 0.35))
	level.queue_free()
	await _frames(2)


## True if every count is within `share` of `expected`.
func _even(counts: Dictionary, expected: float, share: float) -> bool:
	return counts.values().all(func(n: int) -> bool: return absf(n - expected) <= expected * share)


# ---------------------------------------------------------------- the rules

func _test_hourglass() -> void:
	var level: Level = await _level([_relic("hourglass")], [WaveFixtures.make_wave(1, 1.0, GHOUL, 2), WaveData.new()])
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return spawned.size() >= 1, 120)
	_check("Hourglass: an enemy in the wave's first 5 s walks at half speed", spawned[0].is_slowed() and is_equal_approx(spawned[0].get_status().get_slow_factor(), 0.5))
	level.queue_free()
	await _frames(2)
	var late: Level = await _level([_relic("hourglass")], [_late_wave(), WaveData.new()])
	var later: Array[Enemy] = []
	late.spawner.enemy_spawned.connect(func(e: Enemy) -> void: later.append(e))
	await WaveFixtures.start_wave(late)
	await _until(func() -> bool: return not later.is_empty(), 60 * 9)
	_check("...one that comes later walks at full speed", not later.is_empty() and not later[0].is_slowed())
	late.queue_free()
	await _frames(2)


func _test_bloodpact() -> void:
	var level: Level = await _level([_relic("bloodpact")])
	_check("Bloodpact: one life fewer (%d)" % level.hero_lives.get_max_lives(), level.hero_lives.get_max_lives() == 2)
	var hero: Hero = level.get_node("Hero")
	hero.health.take_damage(50)
	var target: Enemy = _stationary(level, hero.global_position + Vector2(30, 0), GHOUL, 1000)
	await _frames(2)
	var before: int = hero.health.current_health
	hero.attack(target.global_position)
	await _frames(10)
	_check("...the sword heals the hero (%d -> %d)" % [before, hero.health.current_health], hero.health.current_health > before)
	level.queue_free()
	await _frames(2)


func _test_ossuary_bell() -> void:
	var level: Level = await _level([_relic("ossuary_bell")], [WaveFixtures.make_wave(10, 0.1, GHOUL, 2), WaveData.new()])
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return spawned.size() >= 10, 120)
	for e: Enemy in spawned:
		if is_instance_valid(e):
			e.get_health().take_damage(1000)
	await _frames(2)
	var bones: Array[Node] = level.find_children("*", "BonePickup", true, false)
	_check("Ossuary Bell: the 10th kill drops a bone", bones.size() == 1)
	var gold: int = level.economy.get_gold()
	(level.get_node("Hero") as Node2D).global_position = (bones[0] as Node2D).global_position if not bones.is_empty() else Vector2.ZERO
	await _frames(4)
	_check("...the hero picks it up: +%d gold" % (level.economy.get_gold() - gold), level.economy.get_gold() - gold == 30
		and level.find_children("*", "BonePickup", true, false).is_empty())
	level.queue_free()
	await _frames(2)


func _test_siege_ledger() -> void:
	var level: Level = await _level([_relic("siege_ledger")])
	var builder: TowerBuilder = level.builder
	level.economy.earn(5000, Economy.Source.REFUND)
	var gold: int = level.economy.get_gold()
	builder.build(builder.get_slots()[3], ARCHER)
	_check("Siege Ledger: building costs 25%% less (%d instead of %d)" % [gold - level.economy.get_gold(), ARCHER.cost],
		gold - level.economy.get_gold() == roundi(ARCHER.cost * 0.75))
	await _frames(50)
	builder.upgrade(builder.get_slots()[3])
	await _frames(50)
	builder.upgrade(builder.get_slots()[3])
	await _frames(50)
	var slot: BuildSlot = builder.get_slots()[3]
	_check("...but no tower can evolve", slot.tower.is_max_level() and builder.evolution_options(slot).is_empty() and not builder.evolve(slot, 0))
	level.queue_free()
	await _frames(2)


func _test_lantern() -> void:
	var level: Level = await _level([_relic("lantern_of_the_lost")], [_wave_of([[CULTIST, 1], [GHOUL, 1]]), WaveData.new()])
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return spawned.size() >= 2, 120)
	var cultist: Enemy = spawned[0] if spawned[0].data == CULTIST else spawned[1]
	var ghoul: Enemy = spawned[1] if cultist == spawned[0] else spawned[0]
	var hp: int = cultist.get_health().current_health
	cultist.get_health().take_damage(4)
	_check("Lantern of the Lost: a Cultist is marked and takes 50%% more damage (-%d from 4)" % (hp - cultist.get_health().current_health),
		cultist.get_status().is_vulnerable() and hp - cultist.get_health().current_health == 6)
	_check("...a Ghoul is not", not ghoul.get_status().is_vulnerable())
	level.queue_free()
	await _frames(2)


func _test_twin_banners() -> void:
	var level: Level = await _level([])
	var builder: TowerBuilder = level.builder
	level.economy.earn(5000, Economy.Source.REFUND)
	var near: BuildSlot = builder.get_slots()[2]  # (-220, -160)
	var twin: BuildSlot = builder.get_slots()[4]  # (-140, -80), 113 px away
	var far: BuildSlot = builder.get_slots()[6]   # (200, -200)
	builder.build(near, ARCHER)
	builder.build(twin, ARCHER)
	builder.build(far, ARCHER)
	await _frames(50)
	for _i: int in 2:
		builder.upgrade(near)
		await _frames(50)
	var level_one: int = twin.tower.get_stats().damage
	level.modifiers.add_upgrade(_relic("twin_banners"))
	await _frames(2)
	_check("Twin Banners: a level-1 archer next to a level-3 one fights with level 3's stats (damage %d -> %d)" % [level_one, twin.tower.get_stats().damage],
		twin.tower.get_stats_level() == 3 and twin.tower.get_stats().damage == near.tower.get_stats().damage and twin.tower.get_level() == 1
		and (twin.tower.get_node("%BoostMark") as CanvasItem).visible)
	_check("...one farther than 330 px does not", far.tower.get_stats_level() == 1)
	level.queue_free()
	await _frames(2)


func _test_phoenix() -> void:
	var level: Level = await _level([_relic("phoenix_feather")])
	var health: HealthComponent = level.fortress.health
	var lost: Array[bool] = [false]
	level.run_lost.connect(func(_r: Level.LossReason) -> void: lost[0] = true)
	health.take_damage(1000)
	await _frames(2)
	_check("Phoenix Feather: a fatal blow leaves the fortress at 30%% (%d / %d)" % [health.current_health, health.max_health],
		not lost[0] and health.current_health == roundi(health.max_health * 0.3))
	health.take_damage(1000)
	await _frames(2)
	_check("...once per chapter: the next one destroys it", lost[0])
	level.queue_free()
	await _frames(2)


func _test_executioner() -> void:
	var level: Level = await _level([_relic("executioners_mark")], [WaveFixtures.make_wave(1, 1.0, GHOUL, 2), WaveData.new()])
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return not spawned.is_empty(), 120)
	var ghoul: Enemy = spawned[0]
	var ref: WeakRef = weakref(ghoul)
	ghoul.get_health().take_damage(ghoul.get_health().max_health - 2)
	await _frames(2)
	_check("Executioner's Mark: an enemy brought below 12% HP dies at once", ref.get_ref() == null or not (ref.get_ref() as Enemy).is_alive())
	_check("...kills pay 15% less gold", is_equal_approx(level.modifiers.apply(100.0, [RunModifiers.KILL_GOLD]), 85.0))
	level.queue_free()
	await _frames(2)


func _test_glass_banner() -> void:
	var level: Level = await _level([])
	level.economy.earn(500, Economy.Source.REFUND)
	level.builder.build(level.builder.get_slots()[3], ARCHER)
	await _frames(2)
	var damage: int = level.builder.get_slots()[3].tower.get_stats().damage
	var banner: RelicData = _relic("glass_banner")
	var bonus: float = banner.modifiers[0].percent
	level.modifiers.add_upgrade(banner)
	await _frames(2)
	var health: HealthComponent = level.fortress.health
	health.take_damage(10)
	_check("Glass Banner: towers deal %d%% more (%d -> %d), the fortress takes 50%% more (-%d from 10)"
		% [roundi(bonus * 100.0), damage, level.builder.get_slots()[3].tower.get_stats().damage, health.max_health - health.current_health],
		bonus > 0.0 and level.builder.get_slots()[3].tower.get_stats().damage == roundi(damage * (1.0 + bonus))
		and health.max_health - health.current_health == 15)
	level.queue_free()
	await _frames(2)


func _test_soul_lantern() -> void:
	var level: Level = await _level([_relic("soul_lantern")], [_wave_of([[GHOUL, 2]]), WaveData.new()])
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	level.fortress.health.take_damage(30)
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return spawned.size() >= 2, 120)
	var hp: int = level.fortress.health.current_health
	spawned[0].global_position = Vector2(-120, 0)
	await _frames(1)
	spawned[0].get_health().take_damage(1000)
	await _frames(1)
	_check("Soul Lantern: a kill near the fortress repairs it (+%d)" % (level.fortress.health.current_health - hp), level.fortress.health.current_health == hp + 1)
	hp = level.fortress.health.current_health
	spawned[1].global_position = Vector2(-700, 240)
	await _frames(1)
	spawned[1].get_health().take_damage(1000)
	await _frames(1)
	_check("...a kill far away does not", level.fortress.health.current_health == hp)
	level.queue_free()
	await _frames(2)


func _test_drowned_bell() -> void:
	var level: Level = await _level([_relic("drowned_bell")], [WaveFixtures.make_wave(3, 0.5, GHOUL, 0), WaveData.new()])
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return spawned.size() >= 3, 120)
	for e: Enemy in spawned:
		e.get_health().setup(100000)
		e.speed_multiplier = 0.05  # still on the road when the bell tolls
	var effects: RelicEffects = level.get_node("%RelicEffects")
	await _frames(roundi((effects.bell_interval - effects.bell_warning * 0.5) * 60.0) - 90)
	var rings: int = level.find_children("*", "TelegraphMarker", true, false).size()
	await _frames(60)
	var frozen: bool = spawned.all(func(e: Enemy) -> bool: return e.get_status().is_frozen())
	_check("Drowned Bell: a ring warns of the toll (%d), then every enemy freezes" % rings, rings >= 1 and frozen)
	level.queue_free()
	await _frames(2)


func _test_iron_tithe() -> void:
	var level: Level = await _level([])
	var base: int = level.fortress.health.max_health
	level.modifiers.add_upgrade(_relic("iron_tithe"))
	await _frames(1)
	var health: HealthComponent = level.fortress.health
	health.take_damage(60)
	var hp: int = health.current_health
	level.fortress.repair(0.5)
	var shop: Quartermaster = level.get_node("%Quartermaster")
	level.economy.earn(2000, Economy.Source.REFUND)
	level.merchant.open()
	_check("Iron Tithe: fortress max HP +50%% (%d -> %d), but no repair of any kind" % [base, health.max_health],
		health.max_health == roundi(base * 1.5) and health.current_health == hp and not shop.repair() and shop.repair_blocker() == Quartermaster.NO_REPAIRS
		and level.merchant.repair_blocker() == Merchant.NO_REPAIRS and not level.merchant.buy_repair() and health.current_health == hp)
	level.queue_free()
	await _frames(2)


func _test_merchants_seal() -> void:
	var level: Level = await _level([])
	var shop: Quartermaster = level.get_node("%Quartermaster")
	level.merchant.open()
	var price: int = level.merchant.get_repair_price()
	var repair: int = shop.repair_cost()
	level.modifiers.add_upgrade(_relic("merchants_seal"))
	_check("Merchant's Seal: merchants 35%% cheaper (%d -> %d), the Quartermaster 50%% dearer (%d -> %d)"
		% [price, level.merchant.get_repair_price(), repair, shop.repair_cost()],
		level.merchant.get_repair_price() == roundi(price * 0.65) and shop.repair_cost() == roundi(repair * 1.5))
	level.queue_free()
	await _frames(2)


func _test_second_oath() -> void:
	var level: Level = await _level([_relic("second_oath")])
	var hero: Hero = level.get_node("Hero")
	var hp: int = level.fortress.health.current_health
	hero.health.take_damage(1000)
	await _frames(2)
	_check("Second Oath: the fallen hero is back in 1 s (%.1f s left), the fortress pays 10 HP"
		% level.hero_lives.get_respawn_time_left(), level.hero_lives.get_respawn_time_left() <= 1.0 and level.fortress.health.current_health == hp - 10)
	await _frames(70)
	_check("...and it is up again after 1 s", not hero.health.is_dead())
	level.queue_free()
	await _frames(2)


func _test_ember_heart() -> void:
	var level: Level = await _level([])
	level.economy.earn(500, Economy.Source.REFUND)
	level.builder.build(level.builder.get_slots()[3], BRAZIER)
	await _frames(2)
	var duration: float = level.builder.get_slots()[3].tower.get_stats().burn_duration
	level.modifiers.add_upgrade(_relic("ember_heart"))
	await _frames(1)
	_check("Ember Heart: burning ground lasts twice as long (%.1f -> %.1f s)" % [duration, level.builder.get_slots()[3].tower.get_stats().burn_duration],
		is_equal_approx(level.builder.get_slots()[3].tower.get_stats().burn_duration, duration * 2.0))
	level.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- where they come from

func _test_sources() -> void:
	var chapter: ChapterData = RUN.chapters[0]
	_check("elites: a choice of %d relics and %.0f%% tougher fights" % [chapter.elite_relics, (chapter.elite_health_scale - 1.0) * 100.0],
		chapter.elite_relics == 3 and chapter.elite_health_scale > 1.0 and RUN.chapters[1].elite_relics == 3)
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_seed", 5)
	root.add_child(main)
	await _frames(2)
	var elite_reward: FightReward = chapter.reward_for(RunMap.Kind.ELITE, false)
	var boss_reward: FightReward = chapter.reward_for(RunMap.Kind.BOSS, false)
	_check("an elite's reward is a relic choice of 3 (no cards, no gold); the boss's too, with a repair",
		elite_reward.relics == 3 and elite_reward.cards == 0 and elite_reward.gold == 0 and boss_reward.relics == 3 and boss_reward.repair > 0.0)
	var level: Level = main.call("get_level")
	level.set_active(true)
	level.start_encounter([WaveData.new()], FightReward.relic_choice(3))
	await WaveFixtures.start_wave(level)
	await _until(func() -> bool: return level.offers.is_offer_open(), 60 * 3)
	var screen: UpgradeChoiceScreen = level.get_node("UpgradeChoiceScreen")
	_check("a won elite fight opens a relic choice (\"%s\")" % (screen.get_node("%Title") as Label).text,
		level.offers.get_offer().size() == 3 and level.offers.get_offer().all(func(d: UpgradeData) -> bool: return d is RelicData)
		and (screen.get_node("%Title") as Label).text == "Choose a relic")
	var picked: UpgradeData = level.offers.get_offer()[0]
	level.offers.pick(0)
	await _frames(2)
	var row: RunIconsRow = level.get_node("HUD").get_node("%RelicIcons")
	var icon: Control = row.get_node_or_null(NodePath(String(picked.id)))
	_check("the relic shows in the HUD's relic row, with its tooltip (not in the card row)", icon != null and icon.tooltip_text.contains(picked.description)
		and level.get_node("HUD").get_node("%UpgradeIcons").get_node_or_null(NodePath(String(picked.id))) == null)
	var merchant: Merchant = level.merchant
	merchant.relic_chance = 1.0
	merchant.open()
	var stocked: RelicData = merchant.get_relic()
	level.economy.earn(1000, Economy.Source.REFUND)
	var gold: int = level.economy.get_gold()
	_check("a merchant may have a relic, at its high price (%s, %d)" % [stocked.display_name if stocked else "none", merchant.price_of(stocked) if stocked else 0],
		stocked != null and merchant.price_of(stocked) == stocked.price and merchant.buy_relic() and level.modifiers.get_relics().has(stocked)
		and level.economy.get_gold() == gold - stocked.price)
	var hp: int = level.fortress.health.current_health
	var outcome: EventOutcome = level.events.apply(RELIQUARY.choices[0])
	_check("the rare Drowned Reliquary: the fortress takes 20, then a choice of 2 relics", RELIQUARY.rare and outcome != null
		and outcome.choices.size() == 1 and outcome.choices[0].relics == 2 and level.fortress.health.current_health == hp - 20)
	main.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- helpers

## The arena with `relics` taken and `waves` (default: an empty wave), the hero out of the way.
func _level(relics: Array, waves: Array = []) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var typed: Array[WaveData] = []
	for wave: WaveData in waves:
		typed.append(wave)
	if typed.is_empty():
		typed = [WaveData.new(), WaveData.new()]
	(level.get_node("WaveSpawner") as WaveSpawner).waves = typed
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	await _frames(2)
	for relic: RelicData in relics:
		level.modifiers.add_upgrade(relic)
	await _frames(1)
	return level


## A wave of [[enemy, count], ...] on the south road, one every 0.3 s.
func _wave_of(groups: Array) -> WaveData:
	var wave: WaveData = WaveData.new()
	for entry: Array in groups:
		wave.groups.append(WaveFixtures.make_wave(entry[1], 0.3, entry[0], 2).groups[0])
	return wave


## One Ghoul that comes 6 s into the wave (after the Hourglass's 5 s).
func _late_wave() -> WaveData:
	return WaveFixtures.make_wave(1, 1.0, GHOUL, 2, 6.0)


func _stationary(level: Level, at: Vector2, data: EnemyData, health: int) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().setup(health)
	return enemy


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

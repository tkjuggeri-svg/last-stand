extends SceneTree
## Automated check for run map events and shrines: the data (5 events with 2-3 answers plus the rare
## Drowned Reliquary (M7.5: a relic choice), 5 shrines with
## a deal and Walk away, every answer saying what it does), every effect EventResolver applies (gold,
## doubling, damage that never kills, boons and curses as upgrades, losing a life and an upgrade, tower
## gifts and prices, free evolutions, merchant prices, twists on the next fights that count down), the
## needs that disable an answer, the seeded gamble, and the flow through main.tscn: the scene, the
## answer, the result, Continue; upgrade choices one after another; an extra fight and its reward.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const RUN: RunData = preload("res://data/run/run.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const HONED: UpgradeData = preload("res://data/upgrades/honed_blade.tres")
const E: String = "res://data/events/"

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_effects()
	await _test_biome_events()
	await _test_main_flow()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	var chapter: ChapterData = RUN.chapters[0]
	var events_ok: bool = chapter.events.size() == 8 and chapter.events.all(func(e: EventData) -> bool:
		return not e.shrine and e.choices.size() >= 2 and e.choices.size() <= 3) \
		and chapter.events.filter(func(e: EventData) -> bool: return e.rare).size() == 1
	var shrines_ok: bool = chapter.shrines.size() == 5 and chapter.shrines.all(func(e: EventData) -> bool:
		return e.shrine and e.choices.size() == 2 and e.choices[1].effects.is_empty())
	var told: bool = true
	for scene: EventData in chapter.events + chapter.shrines:
		told = told and not scene.title.is_empty() and not scene.text.is_empty()
		for choice: EventChoice in scene.choices:
			told = told and not choice.label.is_empty() and not choice.outcome.is_empty()
	_check("chapter 1 has 7 events (2-3 answers), 1 rare one, and 5 shrines (a deal, Walk away)", events_ok and shrines_ok)
	_check("every scene has a title and text, every answer says what it does", told)


## The biome events (M11): two own events per chapter, well-formed, and every plain answer resolves.
func _test_biome_events() -> void:
	var base: Array[EventData] = RUN.chapters[0].events.slice(0, 6)
	var formed: bool = true
	var own_per_chapter: bool = true
	var all_own: Array[EventData] = []
	for chapter: ChapterData in RUN.chapters:
		var own: Array[EventData] = chapter.events.filter(func(e: EventData) -> bool: return not base.has(e))
		own_per_chapter = own_per_chapter and own.size() == 2
		all_own.append_array(own)
	for event: EventData in all_own:
		formed = formed and not event.shrine and event.choices.size() >= 2 and event.choices.size() <= 3 and not event.title.is_empty()
		for choice: EventChoice in event.choices:
			formed = formed and not choice.label.is_empty() and not choice.outcome.is_empty()
			for effect: EventEffect in choice.effects + choice.fail_effects:
				formed = formed and (effect.type != EventEffect.Type.GRANT_UPGRADE or effect.upgrade != null) \
					and (effect.type != EventEffect.Type.NEXT_FIGHTS_AFFIX or effect.affix != null)
			formed = formed and (choice.chance >= 1.0 or not choice.fail_text.is_empty())
	_check("each of the %d chapters has 2 events of its own (%d in all), well-formed" % [RUN.chapters.size(), all_own.size()], own_per_chapter and formed and all_own.size() == 18)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	builder.build(builder.get_slots()[3], ARCHER)
	level.economy.earn(5000, Economy.Source.REFUND)
	await _frames(60)
	var resolved: int = 0
	var plain: int = 0
	for event: EventData in all_own:
		for choice: EventChoice in event.choices:
			var effects: Array[EventEffect] = choice.effects + choice.fail_effects
			if effects.any(func(e: EventEffect) -> bool: return e.type in [EventEffect.Type.EXTRA_FIGHT, EventEffect.Type.UPGRADE_CHOICE, EventEffect.Type.RELIC_CHOICE]):
				continue
			plain += 1
			if level.events.choice_blocker(choice).is_empty() and level.events.apply(choice) != null:
				resolved += 1
	_check("every plain biome answer can be taken and resolves (%d of %d)" % [resolved, plain], plain > 0 and resolved == plain)
	level.queue_free()
	await _frames(2)


func _test_effects() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(2)
	var resolver: EventResolver = level.events
	var economy: Economy = level.economy
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var health: HealthComponent = level.fortress.health
	economy.earn(1000 - economy.get_gold(), Economy.Source.REFUND)
	_apply(resolver, [_effect(EventEffect.Type.GOLD, 60)])
	_check("GOLD: +60", economy.get_gold() == 1060)
	_apply(resolver, [_effect(EventEffect.Type.GOLD_MULTIPLY, 0, 2.0)])
	_check("GOLD_MULTIPLY: doubled (%d)" % economy.get_gold(), economy.get_gold() == 2120)
	_apply(resolver, [_effect(EventEffect.Type.FORTRESS_DAMAGE, 500)])
	_check("FORTRESS_DAMAGE never kills the fortress (HP %d)" % health.current_health, health.current_health == 1)
	health.heal(1000)
	var oath: UpgradeData = load(E + "knights_oath.tres")
	var grant: EventEffect = _effect(EventEffect.Type.GRANT_UPGRADE)
	grant.upgrade = oath
	_apply(resolver, [grant])
	_check("GRANT_UPGRADE: a boon taken like an upgrade (fortress max %d, in the HUD row)" % health.max_health, health.max_health == 115
		and mods.get_taken().back() == oath and level.get_node("HUD").get_node("%UpgradeIcons").get_node_or_null("knights_oath") != null)
	_apply(resolver, [_effect(EventEffect.Type.LOSE_LAST_UPGRADE)])
	await _frames(1)
	_check("LOSE_LAST_UPGRADE: the boon is gone (max %d), and its icon" % health.max_health, health.max_health == 100 and mods.get_taken().is_empty()
		and level.get_node("HUD").get_node("%UpgradeIcons").get_node_or_null("knights_oath") == null)
	var lives: HeroLives = level.get_node("%HeroLives")
	_apply(resolver, [_effect(EventEffect.Type.LOSE_LIFE)])
	_apply(resolver, [_effect(EventEffect.Type.LOSE_LIFE)])
	_apply(resolver, [_effect(EventEffect.Type.LOSE_LIFE)])
	_check("LOSE_LIFE: lives go, but never the last (%d)" % lives.get_lives_left(), lives.get_lives_left() == 1)
	var spare: EventChoice = EventChoice.new()
	spare.need = EventChoice.Need.SPARE_LIFE
	_check("...and an answer needing a spare life is blocked now", resolver.choice_blocker(spare) == EventResolver.NEEDS_LIFE and resolver.apply(spare) == null)
	# Towers.
	var gift: EventChoice = EventChoice.new()
	gift.need = EventChoice.Need.UPGRADABLE_TOWER
	_check("no tower: a tower gift is blocked", resolver.choice_blocker(gift) == EventResolver.NEEDS_UPGRADABLE)
	builder.build(builder.get_slots()[3], ARCHER)
	builder.build(builder.get_slots()[4], ARCHER)
	await _frames(60)
	builder.upgrade(builder.get_slots()[4])
	_apply(resolver, [_effect(EventEffect.Type.FREE_TOWER_LEVEL)])
	_check("FREE_TOWER_LEVEL: the cheapest tower goes up a level, free", builder.get_slots()[3].tower.get_level() == 2)
	builder.upgrade(builder.get_slots()[4])
	_apply(resolver, [_effect(EventEffect.Type.DESTROY_BEST_TOWER), _effect(EventEffect.Type.FREE_EVOLUTION)])
	await _frames(1)
	_check("DESTROY_BEST_TOWER: the highest-level tower crumbles", builder.get_slots()[4].is_empty() and not builder.get_slots()[3].is_empty())
	var evolution: TowerEvolution = ARCHER.evolutions[0]
	_check("FREE_EVOLUTION: the next evolution costs 0 (%d)" % builder.evolution_cost(evolution), builder.evolution_cost(evolution) == 0)
	builder.upgrade(builder.get_slots()[3])
	var gold: int = economy.get_gold()
	builder.evolve(builder.get_slots()[3], 0)
	_check("...one evolution free, then full price again", economy.get_gold() == gold and builder.evolution_cost(evolution) == evolution.cost)
	# Merchant prices.
	_apply(resolver, [_effect(EventEffect.Type.MERCHANT_PRICES, 0, 1.2)])
	level.merchant.open()
	var price: int = level.merchant.get_repair_price()
	level.merchant.open()
	_check("MERCHANT_PRICES: the next visit +20%% (repair %d), then back (%d)" % [price, level.merchant.get_repair_price()],
		price == roundi(level.merchant.repair_price * 1.2) and level.merchant.get_repair_price() == level.merchant.repair_price)
	# Twists on the next fights.
	var twist: EventEffect = _effect(EventEffect.Type.NEXT_FIGHTS_AFFIX, 2)
	twist.affix = load(E + "lean_purse.tres")
	_apply(resolver, [twist])
	var first: Array[AffixData] = resolver.take_fight_affixes()
	var second: Array[AffixData] = resolver.take_fight_affixes()
	var third: Array[AffixData] = resolver.take_fight_affixes()
	_check("NEXT_FIGHTS_AFFIX: on the next 2 fights, then gone", first.size() == 1 and second.size() == 1 and third.is_empty())
	# Choices and the extra fight come back to Main.
	var outcome: EventOutcome = _apply(resolver, [_effect(EventEffect.Type.UPGRADE_CHOICE, 3), _effect(EventEffect.Type.EXTRA_FIGHT, 3)])
	_check("UPGRADE_CHOICE and EXTRA_FIGHT are left to Main", outcome.choices.size() == 1 and outcome.extra_fight != null)
	# Gold needs and the gamble.
	var pricey: EventChoice = EventChoice.new()
	pricey.need = EventChoice.Need.GOLD
	pricey.gold_cost = 60
	economy.try_spend(economy.get_gold() - 59)
	_check("an answer needing 60 gold is blocked with 59", resolver.choice_blocker(pricey) == EventResolver.NEEDS_GOLD)
	economy.earn(1, Economy.Source.REFUND)
	_check("...and takes the 60 when chosen", resolver.apply(pricey) != null and economy.get_gold() == 0)
	var whispers: EventData = load(E + "shrine_whispers.tres")
	var wins: int = 0
	for s: int in 40:
		resolver.set_seed(s)
		var result: EventOutcome = resolver.apply(whispers.choices[0])
		wins += 1 if not result.choices.is_empty() else 0
	resolver.take_fight_affixes()
	_check("the Shrine of Whispers is a real gamble (%d of 40 won)" % wins, wins > 8 and wins < 32)
	level.queue_free()
	await _frames(2)


func _test_main_flow() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_seed", 2)
	root.add_child(main)
	await _frames(3)
	var level: Level = main.call("get_level")
	var screen: EventScreen = main.get_node("%EventScreen")
	var map_screen: MapScreen = main.get_node("%MapScreen")
	# The Gravedigger's Cart: a plain answer.
	var gold: int = level.economy.get_gold()
	_visit_scene(main, "gravediggers_cart")
	await _frames(2)
	_check("an event node opens its scene: title, text, its answers", screen.visible and (screen.get_node("%Title") as Label).text == "The Gravedigger's Cart"
		and screen.get_choice_button(0).text == "Push it free")
	screen.get_choice_button(0).pressed.emit()
	await _frames(2)
	_check("the answer applies (+60 gold) and the result shows with Continue", level.economy.get_gold() == gold + 60
		and (screen.get_node("%Result") as Label).visible and screen.get_continue_button().visible)
	screen.get_continue_button().pressed.emit()
	await _frames(2)
	_check("Continue: back to the map", not screen.visible and map_screen.visible)
	# The Tinker with no tower and no upgrade: only Decline.
	_visit_scene(main, "the_tinker")
	await _frames(2)
	_check("answers whose needs aren't met are disabled and say why", screen.get_choice_button(0).disabled and screen.get_choice_button(1).disabled
		and not screen.get_choice_button(2).disabled and screen.get_choice_button(0).text.contains("no tower"))
	screen.get_choice_button(2).pressed.emit()
	screen.get_continue_button().pressed.emit()
	await _frames(2)
	# The Shrine of Blood: a life for two rare choices, one after the other.
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	_visit_scene(main, "shrine_blood")
	await _frames(2)
	screen.get_choice_button(0).pressed.emit()
	screen.get_continue_button().pressed.emit()
	await _frames(2)
	var first: Array[UpgradeData] = offers.get_offer()
	_check("Shrine of Blood: a life lost (%d left), then a rare choice" % level.hero_lives.get_lives_left(), level.hero_lives.get_lives_left() == 2
		and first.size() == 3 and first.all(func(d: UpgradeData) -> bool: return d.rarity == UpgradeData.Rarity.RARE))
	offers.pick(0)
	await _frames(2)
	_check("...then the second choice", offers.is_offer_open() and not map_screen.visible)
	offers.pick(0)
	await _frames(2)
	_check("...then the map", map_screen.visible and not level.is_active())
	# The Flooded Crypt: an extra fight now, with a rare choice after it.
	_visit_scene(main, "flooded_crypt")
	await _frames(2)
	screen.get_choice_button(0).pressed.emit()
	await _frames(2)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	_check("Open it: an extra fight of one wave starts", level.is_active() and not screen.visible and spawner.get_wave_count() == 1)
	spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
	cycle.start_wave()
	await _until(func() -> bool: return offers.is_offer_open(), 60 * 40)
	_check("...its reward: a rare choice of 3", offers.get_offer().size() == 3 and offers.get_offer().all(func(d: UpgradeData) -> bool: return d.rarity == UpgradeData.Rarity.RARE))
	offers.pick(0)
	await _frames(2)
	_check("...then the map", map_screen.visible)
	# The Night Fog: the next fight is faster and richer, and the map says so.
	_visit_scene(main, "night_fog")
	await _frames(2)
	screen.get_choice_button(0).pressed.emit()
	screen.get_continue_button().pressed.emit()
	await _frames(2)
	_check("the map's status names the twist waiting for the next fight", (map_screen.get_node("%Status") as Label).text.contains("Night Fog"))
	var map: RunMap = main.call("get_map")
	var battle: MapNode = null
	for node: MapNode in map.nodes:
		if node.kind == RunMap.Kind.BATTLE and node.row > 1:
			battle = node
	map.path.append(map.get_parents(battle)[0])
	map_screen.node_chosen.emit(battle)
	await _frames(2)
	_check("...and that fight's waves carry it (speed x%.2f, gold x%.2f)" % [spawner.waves[0].speed_multiplier, spawner.waves[0].gold_multiplier / battle.encounter.waves[0].gold_multiplier],
		is_equal_approx(spawner.waves[0].speed_multiplier, battle.encounter.waves[0].speed_multiplier * 1.15)
		and is_equal_approx(spawner.waves[0].gold_multiplier, battle.encounter.waves[0].gold_multiplier * 1.5))
	main.queue_free()
	await _frames(2)


## Moves the map to the scene's node (as if its parent had been visited) and picks it.
func _visit_scene(main: Node, id: StringName) -> void:
	var map: RunMap = main.call("get_map")
	var chapter: ChapterData = map.chapter
	var scene: EventData = null
	for candidate: EventData in chapter.events + chapter.shrines:
		if candidate.id == id:
			scene = candidate
	var node: MapNode = MapNode.new()
	node.index = map.nodes.size()
	node.row = 3
	node.kind = RunMap.Kind.SHRINE if scene.shrine else RunMap.Kind.EVENT
	node.event = scene
	map.nodes.append(node)
	var parent: MapNode = MapNode.new()
	parent.index = map.nodes.size()
	parent.links.append(node.index)
	map.nodes.append(parent)
	map.path.append(parent)
	(main.get_node("%MapScreen") as MapScreen).node_chosen.emit(node)


func _apply(resolver: EventResolver, effects: Array[EventEffect]) -> EventOutcome:
	var choice: EventChoice = EventChoice.new()
	choice.effects = effects
	return resolver.apply(choice)


func _effect(type: EventEffect.Type, amount: int = 0, factor: float = 1.0) -> EventEffect:
	var effect: EventEffect = EventEffect.new()
	effect.type = type
	effect.amount = amount
	effect.factor = factor
	return effect


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

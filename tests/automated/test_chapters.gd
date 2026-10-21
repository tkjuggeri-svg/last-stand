extends SceneTree
## Automated check for chapters (M7): the run's two chapters; chapter 2's waves ramp up from chapter 1
## (tougher and faster every row, every lane pressed, kill gold kept scarce), its tougher elites and its boss,
## the Tollkeeper, whose toll (telegraphed by a growing ring) silences the towers inside it for a while
## and no others; and, through main.tscn, the move from one chapter to the next: the chapter screen,
## towers packed up for the chapter's share of what they cost (not all of it), gold, upgrades and lives
## carried, the fortress +50%, a fresh level and map, the life buy-back available again, and the last
## chapter's boss winning the run.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const RUN: RunData = preload("res://data/run/run.tres")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const TOLLKEEPER: EnemyData = preload("res://data/enemies/tollkeeper.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const HONED: UpgradeData = preload("res://data/upgrades/honed_blade.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_toll()
	await _test_transition()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	_check("the run has 2 chapters", RUN.chapters.size() == 2 and RUN.chapters[1].display_name.begins_with("Chapter 2"))
	var one: ChapterData = RUN.chapters[0]
	var two: ChapterData = RUN.chapters[1]
	var tougher: bool = true
	var faster: bool = true
	var richer: bool = true
	var lanes: bool = true
	for row: int in range(1, 7):
		var a: EncounterData = one.encounters_for(one.battles, row)[0]
		var b: EncounterData = two.encounters_for(two.battles, row)[0]
		for i: int in 2:
			tougher = tougher and _toughness(b.waves[i]) > _toughness(a.waves[i]) * 1.5
			faster = faster and b.waves[i].speed_multiplier >= maxf(a.waves[i].speed_multiplier, 1.05)
			richer = richer and _gold(b.waves[i]) >= 290.0 and _gold(b.waves[i]) <= 460.0
			var used: Dictionary = {}
			for group: SpawnGroup in b.waves[i].groups:
				used[group.lane] = true
			lanes = lanes and used.size() == 3
	_check("chapter 2's battles: every wave much tougher than chapter 1's same row", tougher)
	_check("...faster, on every lane, with kill gold of 300-440 a wave (only 40% of the towers' cost carries over)", faster and richer and lanes)
	var leaders: bool = two.elites.all(func(e: EncounterData) -> bool: return e.leader != null and e.leader_health_scale > 1.0)
	_check("chapter 2's elites: their mini-bosses are tougher there", leaders)
	var last: WaveData = two.boss.waves.back()
	_check("chapter 2's boss fight ends with the Tollkeeper", last.groups.any(func(g: SpawnGroup) -> bool: return g.enemy == TOLLKEEPER) and not two.boss.strip_bosses)


func _test_toll() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	level.economy.earn(1000, Economy.Source.REFUND)
	var near_slot: BuildSlot = builder.get_slots()[3]
	var far_slot: BuildSlot = builder.get_slots()[6]
	builder.build(near_slot, ARCHER)
	builder.build(far_slot, ARCHER)
	await _frames(60)
	var boss: Enemy = _stationary(level, near_slot.global_position + Vector2(90, 40), TOLLKEEPER, 100000)
	var toll: TollAbility = boss.find_children("*", "TollAbility", false, false)[0]
	_check("the Tollkeeper's toll: a %.0f px ring, every %.0f s" % [toll.radius, toll.interval], toll.radius >= 200.0 and toll.telegraph_time >= 1.0)
	await _until(func() -> bool: return toll.is_telegraphing(), 60 * 8)
	var rings: Array[Node] = toll.find_children("*", "TelegraphMarker", false, false)
	_check("first it plants itself and a ring grows on the ground (the telegraph)", toll.is_telegraphing() and boss.is_busy()
		and rings.size() == 1 and is_equal_approx((rings[0] as TelegraphMarker).size, toll.radius))
	_check("...nothing is silenced yet", not near_slot.tower.get_silence().is_silenced())
	await _until(func() -> bool: return not toll.is_telegraphing(), 120)
	await _frames(1)
	_check("then it rings: the tower inside is silenced (darkened, a cracked bell over it)", near_slot.tower.get_silence().is_silenced()
		and (near_slot.tower.get_node("%SilenceMark") as CanvasItem).visible)
	_check("...the tower outside is not", not far_slot.tower.get_silence().is_silenced() and toll.get_silenced_count() == 1)
	var target: Enemy = _stationary(level, near_slot.global_position + Vector2(-80, 0), GHOUL, 10000)
	var hp_sum: Callable = func() -> int: return target.get_health().current_health + boss.get_health().current_health
	var before: int = hp_sum.call()
	await _frames(60 * 2)
	_check("a silenced tower doesn't fire (the enemies in its range untouched)", hp_sum.call() == before)
	await _until(func() -> bool: return not near_slot.tower.get_silence().is_silenced(), 60 * 4)
	before = hp_sum.call()
	await _frames(60)
	_check("...and fires again when the silence wears off", hp_sum.call() < before
		and not (near_slot.tower.get_node("%SilenceMark") as CanvasItem).visible)
	level.queue_free()
	await _frames(2)


func _test_transition() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_data", MapFixtures.boss_only_run(2, MapFixtures.encounter(1, 1), load(ARENA)))
	main.set("run_seed", 3)
	root.add_child(main)
	await _frames(2)
	var level: Level = await MapFixtures.enter_first_battle(main)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	level.economy.earn(500 - level.economy.get_gold(), Economy.Source.REFUND)
	builder.build(builder.get_slots()[3], ARCHER)
	await _frames(60)
	builder.upgrade(builder.get_slots()[3])
	var invested: int = builder.get_slots()[3].tower.invested
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(HONED)
	level.hero_lives.lose_life()
	level.fortress.health.take_damage(70)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	await _until(func() -> bool: return offers.is_offer_open(), 60 * 10)
	_check("chapter 1's boss beaten: its reward is a rare choice (and a repair)", offers.get_offer().all(func(d: UpgradeData) -> bool: return d.rarity == UpgradeData.Rarity.RARE))
	offers.pick(0)
	await _frames(2)
	var gold: int = level.economy.get_gold()
	var upgrades: Array[UpgradeData] = (level.get_node("%RunModifiers") as RunModifiers).get_taken()
	var hp: int = level.fortress.health.current_health
	var lives: int = level.hero_lives.get_lives_left()  # after the reward (a card may add a life)
	var screen: ChapterScreen = main.get_node("%ChapterScreen")
	var text: String = (screen.get_node("%Text") as Label).text
	var ratio: float = ChapterData.new().leave_refund  # the test run's chapters keep the default
	var refund: int = floori(invested * ratio)
	_check("the chapter screen: cleared, towers packed up for %d%% (+%d of %d), the next chapter's name" % [roundi(ratio * 100.0), refund, invested], screen.visible
		and ratio < 1.0 and (screen.get_node("%Title") as Label).text == "Test chapter 1 cleared!"
		and text.contains("%d%% of what they cost: +%d gold" % [roundi(ratio * 100.0), refund]) and text.contains("Test chapter 2"))
	screen.get_continue_button().pressed.emit()
	await _frames(3)
	var fresh: Level = main.call("get_level")
	var mods: RunModifiers = fresh.get_node("%RunModifiers")
	_check("Continue: a fresh level for chapter 2, its map shown", fresh != level and (main.get_node("%MapScreen") as MapScreen).visible
		and (main.get_node("%MapScreen").get_node("%Title") as Label).text == "Test chapter 2")
	_check("gold carried with the towers' refund (%d = %d + %d)" % [fresh.economy.get_gold(), gold, refund], fresh.economy.get_gold() == gold + refund)
	_check("no towers on the new field", (fresh.get_node("%TowerBuilder") as TowerBuilder).get_slots().all(func(s: BuildSlot) -> bool: return s.is_empty()))
	_check("upgrades carried (%d), shown in the HUD row" % mods.get_taken().size(), mods.get_taken() == upgrades
		and fresh.get_node("HUD").get_node("%UpgradeIcons").get_node_or_null("honed_blade") != null)
	_check("lives carried (%d of %d)" % [fresh.hero_lives.get_lives_left(), lives], fresh.hero_lives.get_lives_left() == lives and lives < fresh.hero_lives.get_max_lives())
	var max_health: int = fresh.fortress.health.max_health
	_check("the fortress: its HP +50%% (%d -> %d)" % [hp, fresh.fortress.health.current_health], fresh.fortress.health.current_health == mini(hp + roundi(max_health * 0.5), max_health))
	var shop: Quartermaster = fresh.get_node("%Quartermaster")
	_check("the life buy-back is for sale again (once per chapter)", shop.get_lives_for_sale() == 1)
	fresh = await MapFixtures.enter_first_battle(main)
	var victory: VictoryScreen = main.get_node("%VictoryScreen")
	(fresh.get_node("WaveSpawner") as WaveSpawner).enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
	(fresh.get_node("%RunCycle") as RunCycle).start_wave()
	await _until(func() -> bool: return victory.visible, 60 * 10)
	_check("the last chapter's boss wins the run", victory.visible and fresh.is_run_over())
	main.queue_free()
	await _frames(2)


func _toughness(wave: WaveData) -> float:
	var hp: float = 0.0
	for group: SpawnGroup in wave.groups:
		if not group.enemy.is_boss:
			hp += group.count * group.enemy.max_health
	return hp * wave.health_multiplier


func _gold(wave: WaveData) -> float:
	var gold: float = 0.0
	for group: SpawnGroup in wave.groups:
		if not group.enemy.is_boss:
			gold += group.count * group.enemy.gold_reward
	return gold * wave.gold_multiplier


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

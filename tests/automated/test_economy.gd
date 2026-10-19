extends SceneTree
## Automated check for the gold economy: Economy rules, kill rewards (once, never for fortress
## arrivals), the 10% perfect-defense bonus and its HUD display.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const OFF_LANE: Vector2 = Vector2(-200, 200)
## The test pins the level's starting gold, so the numbers below don't move with tuning.
const START_GOLD: int = 100
const GHOUL_DATA: EnemyData = preload("res://data/enemies/ghoul.tres")

var _failures: int = 0


func _initialize() -> void:
	await _test_economy_rules()
	await _test_kill_gold_once()
	await _test_fortress_arrival_pays_nothing()
	await _test_perfect_defense()
	await _test_one_leak_cancels_bonus()
	await _test_bonus_ratio_math()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_economy_rules() -> void:
	var economy: Economy = Economy.new()
	economy.starting_gold = 50
	root.add_child(economy)
	await _frames(1)
	var changes: Array[int] = []
	economy.gold_changed.connect(func(g: int) -> void: changes.append(g))
	_check("starts with starting_gold", economy.get_gold() == 50)
	economy.earn(0, Economy.Source.KILL)
	economy.earn(-20, Economy.Source.KILL)
	_check("earning zero or negative gold does nothing", economy.get_gold() == 50 and changes.is_empty())
	_check("cannot spend more than it has", not economy.try_spend(51) and economy.get_gold() == 50)
	_check("negative costs are refused", not economy.try_spend(-5) and economy.get_gold() == 50)
	_check("spending exactly everything leaves 0", economy.try_spend(50) and economy.get_gold() == 0)
	_check("gold never goes below 0", not economy.try_spend(1) and economy.get_gold() == 0)
	_check("gold_changed reported each change", changes == [0])
	economy.queue_free()
	await _frames(1)


func _test_kill_gold_once() -> void:
	# Two ghouls 3 s apart: checking before the second spawns keeps the wave open (no bonus yet).
	var level: Level = _make_level(2, 3.0)
	var economy: Economy = level.get_node("%Economy")
	await _frames(2)
	var ghoul: Enemy = (level.get_node("WaveSpawner") as WaveSpawner).get_child(0)
	var health: HealthComponent = ghoul.get_node("%HealthComponent")
	health.take_damage(100)
	health.take_damage(100)  # already dead
	(ghoul.get_node("%FortressHitbox") as Hitbox).register_hit(null)  # "reached the fortress" in the same frame
	await _frames(2)
	_check("a kill pays the ghoul's gold_reward exactly once (%d)" % economy.get_gold(), economy.get_gold() == START_GOLD + GHOUL_DATA.gold_reward)
	var gold_label: Label = level.get_node("HUD").get_node("%GoldLabel")
	_check("HUD shows the new gold", gold_label.text == str(START_GOLD + GHOUL_DATA.gold_reward))
	await _free(level)


func _test_fortress_arrival_pays_nothing() -> void:
	var level: Level = _make_level(1, 1.0)
	var economy: Economy = level.get_node("%Economy")
	var rewards: WaveRewards = level.get_node("%WaveRewards")
	var fortress: Fortress = level.get_node("Fortress")
	(level.get_node("Hero") as Node2D).position = OFF_LANE
	var bonuses: Array[int] = []
	rewards.perfect_defense_awarded.connect(func(b: int) -> void: bonuses.append(b))
	await _until(func() -> bool: return fortress.health.current_health < 100, 1200)
	await _frames(2)
	_check("a ghoul reaching the fortress pays no gold", fortress.health.current_health == 90 and economy.get_gold() == START_GOLD)
	_check("...and the wave pays no perfect-defense bonus", bonuses.is_empty())
	await _free(level)


func _test_perfect_defense() -> void:
	var level: Level = _make_level(10, 0.05)
	var economy: Economy = level.get_node("%Economy")
	var rewards: WaveRewards = level.get_node("%WaveRewards")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var feed: NotificationFeed = level.get_node("HUD").get_node("%NotificationFeed")
	var bonuses: Array[int] = []
	rewards.perfect_defense_awarded.connect(func(b: int) -> void: bonuses.append(b))
	var feed_texts: Array[String] = []
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(100))
	var cleared: Array[bool] = [false]
	spawner.wave_cleared.connect(func(_wave: int) -> void:
		cleared[0] = true
		for label: Node in feed.get_children():
			feed_texts.append((label as Label).text))
	await _until(func() -> bool: return cleared[0], 300)
	await _frames(1)
	var kill_gold: int = 10 * GHOUL_DATA.gold_reward
	var bonus: int = roundi(kill_gold * rewards.perfect_defense_ratio)
	_check("10 kills x %d gold + 10%% bonus = %d earned (gold %d)" % [GHOUL_DATA.gold_reward, kill_gold + bonus, economy.get_gold()],
		economy.get_gold() == START_GOLD + kill_gold + bonus)
	_check("bonus paid once, exactly %d (%s)" % [bonus, bonuses], bonuses == [bonus])
	_check("the HUD announces the perfect defense", feed_texts.has("Perfect defense! +%d gold" % bonus))
	# The same wave cannot pay again.
	_check("ending the wave again pays nothing", rewards.end_wave() == 0)
	spawner.wave_cleared.emit(1)
	await _frames(1)
	_check("a repeated wave_cleared pays nothing", economy.get_gold() == START_GOLD + kill_gold + bonus and bonuses.size() == 1)
	await _free(level)


func _test_one_leak_cancels_bonus() -> void:
	var level: Level = _make_level(3, 0.05)
	var economy: Economy = level.get_node("%Economy")
	var rewards: WaveRewards = level.get_node("%WaveRewards")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	(level.get_node("Hero") as Node2D).position = OFF_LANE
	var bonuses: Array[int] = []
	rewards.perfect_defense_awarded.connect(func(b: int) -> void: bonuses.append(b))
	var spawned: Array[int] = [0]
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		spawned[0] += 1
		if spawned[0] <= 2:  # kill two, let the third walk to the fortress
			(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(100))
	var cleared: Array[bool] = [false]
	spawner.wave_cleared.connect(func(_wave: int) -> void: cleared[0] = true)
	await _until(func() -> bool: return cleared[0], 1200)
	await _frames(1)
	_check("one ghoul reaching the fortress cancels the bonus", cleared[0] and bonuses.is_empty())
	_check("kill gold is still paid (gold %d)" % economy.get_gold(), economy.get_gold() == START_GOLD + 2 * GHOUL_DATA.gold_reward)
	await _free(level)


## The bonus maths through the public wave API (as the future wave system will use it).
func _test_bonus_ratio_math() -> void:
	var economy: Economy = Economy.new()
	economy.starting_gold = 0
	var rewards: WaveRewards = WaveRewards.new()
	rewards.economy = economy
	root.add_child(economy)
	root.add_child(rewards)
	await _frames(1)
	rewards.begin_wave()
	_check("a wave with no kills pays no bonus", rewards.end_wave() == 0)
	_check("end_wave without begin_wave pays nothing", rewards.end_wave() == 0)
	economy.queue_free()
	rewards.queue_free()
	await _frames(1)


func _make_level(count: int, interval: float) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	WaveFixtures.single_wave(spawner, count, interval)
	(level.get_node("%Economy") as Economy).starting_gold = START_GOLD
	root.add_child(level)
	return level


func _free(level: Node) -> void:
	level.queue_free()
	await _frames(2)


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

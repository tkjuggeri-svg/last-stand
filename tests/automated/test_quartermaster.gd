extends SceneTree
## Automated check for the between-waves gold sinks (Quartermaster) and their HUD panel: repairing
## the fortress (only damaged walls, only in the build phase, each repair dearer than the last, never
## past max HP, never without the gold) and buying back a lost hero life (only a lost one, once per
## run, dearer the later the wave); the panel shows the offers that apply and its buttons ask for them.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"

var _failures: int = 0


func _initialize() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(1, 1.0), WaveFixtures.make_wave(1, 1.0), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	var shop: Quartermaster = level.get_node("%Quartermaster")
	var economy: Economy = level.get_node("%Economy")
	var fortress: Fortress = level.get_node("Fortress")
	var panel: ServicesPanel = level.get_node("HUD").get_node("%ServicesPanel")
	await _test_repair(level, shop, economy, fortress, panel)
	await _test_life(level, shop, economy, panel)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	level.free()
	quit(_failures)


func _test_repair(level: Level, shop: Quartermaster, economy: Economy, fortress: Fortress, panel: ServicesPanel) -> void:
	var health: HealthComponent = fortress.health
	_check("whole walls: no repair, and the panel is hidden", shop.repair_blocker() == Quartermaster.WALLS_WHOLE and not shop.repair() and not panel.visible)
	health.take_damage(50)
	var gold: int = economy.get_gold()
	var cost: int = shop.repair_cost()
	var amount: int = roundi(health.max_health * shop.repair_fraction)
	_check("damaged walls: the panel offers a repair", panel.visible and panel.get_repair_button().visible and not panel.get_repair_button().disabled)
	panel.get_repair_button().pressed.emit()
	_check("the repair button repairs %d HP for %d gold" % [amount, cost], health.current_health == health.max_health - 50 + amount and economy.get_gold() == gold - cost)
	_check("the next repair costs more (%d -> %d)" % [cost, shop.repair_cost()], shop.repair_cost() > cost and shop.get_repair_count() == 1)
	economy.try_spend(economy.get_gold())
	var hp: int = health.current_health
	_check("without the gold: refused, nothing changes, the button is disabled", not shop.repair() and health.current_health == hp and shop.repair_blocker() == Quartermaster.NOT_ENOUGH_GOLD and panel.get_repair_button().disabled)
	economy.earn(5000, Economy.Source.KILL)
	while shop.repair():
		pass
	_check("repairs stop at max HP (%d / %d)" % [health.current_health, health.max_health], health.current_health == health.max_health and shop.repair_blocker() == Quartermaster.WALLS_WHOLE)
	health.take_damage(30)
	await WaveFixtures.start_wave(level)
	_check("during a wave: no repair, the panel is hidden", shop.repair_blocker() == Quartermaster.NOT_BETWEEN_WAVES and not shop.repair() and not panel.visible)
	await _until_build(level)


func _test_life(level: Level, shop: Quartermaster, economy: Economy, panel: ServicesPanel) -> void:
	var lives: HeroLives = level.get_node("%HeroLives")
	var hero: Hero = level.get_node("Hero")
	_check("no life lost: nothing to buy back", shop.life_blocker() == Quartermaster.NO_LIFE_LOST and not shop.buy_life() and not panel.get_life_button().visible)
	var cost_now: int = shop.life_cost()
	_check("a life costs more after a wave (%d at wave 2)" % cost_now, cost_now == shop.life_base_cost + shop.life_cost_per_wave)
	hero.health.take_damage(hero.health.current_health)
	await _frames(2)
	_check("the hero fell: a life is lost (%d left)" % lives.get_lives_left(), lives.get_lives_left() == lives.get_max_lives() - 1)
	economy.try_spend(economy.get_gold())
	economy.earn(cost_now - 1, Economy.Source.KILL)
	_check("one gold short: refused, the button is shown disabled", not shop.buy_life() and panel.get_life_button().visible and panel.get_life_button().disabled)
	economy.earn(1, Economy.Source.KILL)
	panel.get_life_button().pressed.emit()
	_check("the button buys the life back (%d lives, %d gold left)" % [lives.get_lives_left(), economy.get_gold()], lives.get_lives_left() == lives.get_max_lives() and economy.get_gold() == 0)
	await _frames(60 * 5)  # the respawn
	hero.health.take_damage(hero.health.current_health)
	await _frames(2)
	economy.earn(5000, Economy.Source.KILL)
	_check("only once per run: the next lost life can't be bought", shop.life_blocker() == Quartermaster.ALREADY_BOUGHT and not shop.buy_life() and lives.get_lives_left() == lives.get_max_lives() - 1 and not panel.get_life_button().visible)


func _until_build(level: Level) -> void:
	var cycle: RunCycle = level.get_node("%RunCycle")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	for _i: int in 60 * 40:
		for child: Node in spawner.get_children():
			if child is Enemy and (child as Enemy).is_alive():
				(child as Enemy).get_health().take_damage(1000)
		if cycle.get_phase() == RunCycle.Phase.BUILD:
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

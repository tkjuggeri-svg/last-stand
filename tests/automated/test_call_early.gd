extends SceneTree
## Automated check for calling the next wave early (M8): on a run map's fight (no choices between
## waves) the wave button only offers it once the running wave has sent all its enemies; it reads
## the bonus (half the living enemies' kill gold); calling (the button, or the start_wave key) pays it
## at once, starts the next wave with the earlier wave's living enemies still counted, and forfeits
## that wave's perfect-defense bonus; the last wave can't call another; with choices between waves (the
## standalone 15-wave run) it is never offered.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SANDBOX: String = "res://tests/test_call_early.tscn"
const ARENA: String = "res://levels/prototype_arena.tscn"

var _failures: int = 0


func _initialize() -> void:
	var level: Level = (load(SANDBOX) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveFixtures.make_wave(4, 0.3), WaveFixtures.make_wave(3, 0.3), WaveFixtures.make_wave(2, 0.3)]
	root.add_child(level)
	await _frames(2)
	var cycle: RunCycle = level.run_cycle
	var spawner: WaveSpawner = level.spawner
	var rewards: WaveRewards = level.get_node("HUD").get("rewards")
	var button: Button = level.get_node("HUD").get_node("%StartWaveButton")
	var perfect: Array[int] = [0]
	rewards.perfect_defense_awarded.connect(func(_bonus: int) -> void: perfect[0] += 1)
	cycle.start_wave()
	await _frames(3)
	_check("while the wave still sends enemies: no early call", not cycle.can_call_early() and not button.visible)
	await _frames(60)
	var bonus: int = rewards.early_call_bonus()
	var expected: float = 0.0
	for enemy: Enemy in spawner.get_living_enemies():
		expected += rewards.base_kill_reward(enemy)
	_check("all sent: the button offers the next wave now, +%d (\"%s\")" % [bonus, button.text], cycle.can_call_early() and button.visible
		and button.text.contains("+%d" % bonus) and bonus == roundi(expected * rewards.early_call_ratio) and bonus > 0)
	var gold: int = level.economy.get_gold()
	var living: int = spawner.get_living_count()
	button.pressed.emit()
	await _frames(1)
	_check("called: +%d gold at once, wave 2 runs, wave 1's %d enemies still counted (%d left)" % [level.economy.get_gold() - gold, living, spawner.get_remaining_count()],
		level.economy.get_gold() - gold >= bonus and spawner.get_wave_number() == 2 and cycle.get_phase() == RunCycle.Phase.COMBAT
		and spawner.get_remaining_count() == 3 + living)
	_check("...no perfect-defense bonus for the wave called early", perfect[0] == 0)
	await _frames(60)
	var key: InputEventAction = InputEventAction.new()
	key.action = &"start_wave"
	key.pressed = true
	Input.parse_input_event(key)
	await _frames(2)
	_check("the start_wave key calls early too: wave 3", spawner.get_wave_number() == 3)
	await _frames(40)
	_check("the last wave can't call another", not cycle.can_call_early() and not button.visible)
	for enemy: Enemy in spawner.get_living_enemies():
		enemy.get_health().take_damage(100000)
	await _frames(3)
	_check("every enemy dead: the fight is over", not spawner.is_wave_active() and spawner.get_remaining_count() == 0)
	level.queue_free()
	await _frames(2)

	var standalone: Level = (load(ARENA) as PackedScene).instantiate()
	(standalone.get_node("WaveSpawner") as WaveSpawner).waves = [WaveFixtures.make_wave(2, 0.2), WaveFixtures.make_wave(2, 0.2)]
	root.add_child(standalone)
	await _frames(2)
	standalone.run_cycle.start_wave()
	await _frames(40)
	_check("with choices between waves: never offered", not standalone.run_cycle.can_call_early() and not standalone.run_cycle.call_early())
	standalone.queue_free()
	await _frames(2)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

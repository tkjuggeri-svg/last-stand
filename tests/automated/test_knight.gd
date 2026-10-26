extends SceneTree
## Automated check for the Knight's own kit (M9 leftovers, M13 follow-up): the Bulwark passive, the cards
## Shield Bash, Oathkeeper, Rally and Iron Will, the relics Crown of Thorns and Banner of the Last Keep, who is
## offered them, and the hero stories in the War Room's hero panel.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const RUN: RunData = preload("res://data/run/run.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_kit()
	await _test_hub()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _card(id: String) -> UpgradeData:
	return load("res://data/upgrades/%s.tres" % id)


func _relic(id: String) -> RelicData:
	return load("res://data/relics/%s.tres" % id)


func _test_data() -> void:
	var knight: HeroData = RUN.get_hero("knight")
	var cards: Array[String] = ["shield_bash", "oathkeeper", "rally", "iron_will"]
	var relics: Array[String] = ["crown_of_thorns", "banner_of_the_last_keep"]
	_check("the Knight owns 4 sword-side cards and 2 relics of his own (%d cards, %d relics)" % [knight.exclusive_cards.size(), knight.exclusive_relics.size()],
		cards.all(func(id: String) -> bool: return knight.exclusive_cards.has(_card(id))) and relics.all(func(id: String) -> bool: return knight.exclusive_relics.has(_relic(id))))
	_check("Bulwark is his passive: 25%", is_equal_approx(knight.bulwark, 0.25) and RUN.get_hero("huntress").bulwark == 0.0)
	var stories: bool = true
	for hero: HeroData in RUN.heroes:
		stories = stories and not hero.story_name.is_empty() and not hero.story_line.is_empty() and hero.story_text.length() > 100
	_check("every hero has a story (Ser Aldric, Wren, Maren) and a portrait of their own", stories and RUN.heroes.map(func(h: HeroData) -> int: return h.portrait_index) == [0, 1, 2]
		and RUN.get_hero("knight").story_name == "Ser Aldric" and RUN.get_hero("huntress").story_name == "Wren" and RUN.get_hero("necromancer").story_name == "Maren")


func _level(hero_id: String) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Hero).data = RUN.get_hero(hero_id)
	root.add_child(level)
	await process_frame
	await process_frame
	level.apply_hero(RUN.get_hero(hero_id), RUN.heroes)
	return level


func _test_kit() -> void:
	var level: Level = await _level("knight")
	var hero: Hero = level.get_node("Hero")
	var mods: RunModifiers = level.modifiers
	_check("other heroes are not offered the Knight's cards, he is", level.offers.pool.has(_card("rally")) and level.offers.relic_pool.has(_relic("crown_of_thorns")))
	var other: Level = await _level("huntress")
	_check("...the Huntress's pool leaves them out", not other.offers.pool.has(_card("rally")) and not other.offers.relic_pool.has(_relic("crown_of_thorns")))
	other.queue_free()
	# Bulwark: only while swinging.
	await _frames(2)
	_check("Bulwark: standing still, hits do full damage", is_equal_approx(hero.health.damage_taken_multiplier, 1.0))
	hero.attack(hero.global_position + Vector2(100, 0))
	await _frames(2)
	_check("Bulwark: swinging, a hit does 75%% (%.2f)" % hero.health.damage_taken_multiplier, is_equal_approx(hero.health.damage_taken_multiplier, 0.75))
	mods.add_upgrade(_card("iron_will"))
	await _frames(2)
	_check("Iron Will: Bulwark holds to 55%% damage while swinging (%.2f)" % hero.health.damage_taken_multiplier, is_equal_approx(hero.health.damage_taken_multiplier, 0.55))
	await _frames(40)
	_check("...and the swing's cooldown ends it", is_equal_approx(hero.health.damage_taken_multiplier, 1.0))
	# Shield Bash.
	var ghoul: Enemy = level.spawner.spawn_extra(GHOUL, 0)
	await _frames(2)
	hero.global_position = ghoul.global_position
	hero.dash(Vector2.RIGHT)
	await _frames(2)
	_check("without Shield Bash a dash bashes nobody", (hero.get("_bashed") as Dictionary).is_empty())
	await _frames(150)  # the dash's own cooldown (2 s)
	mods.add_upgrade(_card("shield_bash"))
	hero.global_position = ghoul.global_position
	hero.dash(Vector2.RIGHT)
	await _frames(2)
	_check("Shield Bash: a dash knocks the ghoul it passes (once)", (hero.get("_bashed") as Dictionary).size() == 1)
	# Oathkeeper.
	var boss: Enemy = level.spawner.spawn_extra(LICH, 0)
	await _frames(2)
	var before: int = boss.get_health().current_health
	hero.call("_oathkeeper", boss)
	_check("without Oathkeeper no extra hit", boss.get_health().current_health == before)
	mods.add_upgrade(_card("oathkeeper"))
	hero.call("_oathkeeper", boss)
	_check("Oathkeeper: one more sword hit on a boss (%d -> %d)" % [before, boss.get_health().current_health], boss.get_health().current_health == before - hero.get("_attack_hitbox").damage)
	var ghoul_before: int = ghoul.get_health().current_health
	hero.call("_oathkeeper", ghoul)
	_check("...not on a regular enemy", ghoul.get_health().current_health == ghoul_before)
	# Rally.
	level.economy.earn(500, Economy.Source.REFUND)
	level.builder.build(level.builder.get_slots()[0], ARCHER)
	level.builder.build(level.builder.get_slots()[5], ARCHER)
	await _frames(60)
	var near: Tower = level.builder.get_slots()[0].tower
	var far: Tower = level.builder.get_slots()[5].tower
	hero.global_position = near.global_position + Vector2(40, 0)
	mods.add_upgrade(_card("rally"))
	level.builder.refresh_rally()
	_check("Rally: the tower near the Knight fires 10%% faster, the far one doesn't (%.2f, %.2f)" % [near.get_rally(), far.get_rally()],
		is_equal_approx(near.get_rally(), 0.1) and far.get_rally() == 0.0 and far.global_position.distance_to(hero.global_position) > 150.0)
	hero.global_position = far.global_position
	level.builder.refresh_rally()
	_check("...and follows him", near.get_rally() == 0.0 and is_equal_approx(far.get_rally(), 0.1))
	# Crown of Thorns.
	var attacker: Enemy = level.spawner.spawn_extra(GHOUL, 1)
	await _frames(2)
	var attacker_before: int = attacker.get_health().current_health
	hero.hit_by.emit(attacker)
	_check("without the Crown a hit costs the attacker nothing", attacker.get_health().current_health == attacker_before)
	mods.add_upgrade(_relic("crown_of_thorns"))
	hero.hit_by.emit(attacker)
	_check("Crown of Thorns: the attacker takes 8 (%d -> %d)" % [attacker_before, attacker.get_health().current_health], attacker.get_health().current_health == attacker_before - 8)
	# Banner of the Last Keep.
	_check("the fortress takes full hits before the Banner", is_equal_approx(level.fortress.health.damage_taken_multiplier, 1.0))
	mods.add_upgrade(_relic("banner_of_the_last_keep"))
	await _frames(3)
	_check("Banner of the Last Keep: 15%% less while he stands (%.2f)" % level.fortress.health.damage_taken_multiplier, is_equal_approx(level.fortress.health.damage_taken_multiplier, 0.85))
	hero.health.take_damage(100000)
	await _frames(3)
	_check("...and not once he has fallen", is_equal_approx(level.fortress.health.damage_taken_multiplier, 1.0))
	level.queue_free()
	await process_frame


func _test_hub() -> void:
	root.size = Vector2i(1280, 720)  # the base viewport: the story must fit even there
	var hub: HubScreen = (load("res://ui/hub/hub_screen.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	await process_frame
	var board: UnlockBoard = load("res://data/meta/unlock_board.tres")
	hub.refresh(SaveProfile.new(), board, RUN.get_hero("knight"), true)
	_check("the hero panel shows Ser Aldric's line and a button for his story", hub.get_hero_story_line().begins_with("Ser Aldric") and hub.get_hero_story_button().visible)
	hub.refresh(SaveProfile.new(), board, RUN.get_hero("necromancer"), true)
	_check("...and Maren's when she is picked", hub.get_hero_story_line().begins_with("Maren"))
	hub.show_page(HubScreen.Page.HEROES)
	_check("the pages switch: only the Heroes page shows", hub.get_page() == HubScreen.Page.HEROES)
	hub.get_hero_story_button().pressed.emit()
	await process_frame
	await process_frame
	var dialog: Window = hub.get_story_dialog()
	var view: Vector2 = Vector2(hub.get_viewport().get_visible_rect().size)
	_check("a hero's story opens inside the screen (dialog %s in %s)" % [dialog.size, view], dialog.visible and dialog.position.y >= 0 and dialog.position.y + dialog.size.y <= view.y)
	hub.refresh(SaveProfile.new(), board, null, false)
	_check("with no hero there is no story", not hub.get_hero_story_button().visible)
	hub.queue_free()


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1

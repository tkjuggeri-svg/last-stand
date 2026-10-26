extends SceneTree
## Automated check that every run card, event boon, fight twist, event and shrine answer and merchant
## item does something that matters in the current game, not just something.
## Cards: each stat a card can touch is read through a measure of what it does in play, on the scale
## it matters on (a tower's damage per second, the hero's swing rate, build time against a wave's
## length, gold per wave at a typical bank against a wave's kill gold, thorn damage on an enemy crossing
## the thorns against its HP, ...). A card must move at least one measure by MIN_IMPACT of its scale.
## A stat no measure reads fails the test: decide how it matters before a card uses it.
## Events and shrines: every answer but "Nothing happens." must change the run (gold by at least
## MIN_GOLD, the fortress, lives, upgrades, towers, coming fights or prices). Twists must change their
## waves; the merchant's repair must matter.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const UPGRADES_DIR: String = "res://data/upgrades"
const EVENTS_DIR: String = "res://data/events"
const AFFIXES_DIR: String = "res://data/affixes"
const RUN: RunData = preload("res://data/run/run.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BRUTE: EnemyData = preload("res://data/enemies/brute.tres")
const CULTIST: EnemyData = preload("res://data/enemies/cultist.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
## A card must move one measure by at least this share of its scale.
const MIN_IMPACT: float = 0.1
## An event's gold must be at least this much to count.
const MIN_GOLD: int = 50
## About how long a wave lasts, and how much gold a player keeps between waves (gold is scarce).
const WAVE_SECONDS: float = 40.0
const TYPICAL_BANK: float = 100.0
## A mid-run wave's kill gold, and a mid-run Ghoul's HP (wave 10's toughness).
const WAVE_GOLD: float = 250.0
const GHOUL_HP: float = 48.0
## Base hero values (hero.gd, hero_dash.gd) and the hero's own damage per second (10 every 0.4 s).
const HERO: Dictionary = {"damage": 10.0, "speed": 200.0, "health": 100.0, "cooldown": 0.4, "lives": 3.0, "dash": 2.0, "min_dash": 0.6}
const HERO_DPS: float = 25.0
## The fortress's walls (half its 104 px hurtbox) and a Ghoul's body.
const WALL_HALF: float = 52.0

var _failures: int = 0
## Stat names (with "tower.<id>." made generic) that the measures read.
var _known: Dictionary = {}


func _initialize() -> void:
	var catalog: Array[TowerData] = []
	for file: String in DirAccess.get_files_at("res://data/towers"):
		if file.ends_with(".tres"):
			catalog.append(load("res://data/towers".path_join(file)))
	_test_cards(catalog)
	_test_affixes()
	await _test_events()
	_test_merchant()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


# ---------------------------------------------------------------- cards

func _test_cards(catalog: Array[TowerData]) -> void:
	var cards: Array[UpgradeData] = []
	for file: String in DirAccess.get_files_at(UPGRADES_DIR):
		if file.ends_with(".tres"):
			cards.append(load(UPGRADES_DIR.path_join(file)))
	for file: String in DirAccess.get_files_at(EVENTS_DIR):
		if file.ends_with(".tres"):
			var resource: Resource = load(EVENTS_DIR.path_join(file))
			if resource is UpgradeData:
				cards.append(resource)
	var measures: Dictionary = _measures(catalog)
	for card: UpgradeData in cards:
		var unknown: Array[String] = []
		for modifier: StatModifier in card.modifiers:
			if not _known.has(_generic(modifier.stat)):
				unknown.append(String(modifier.stat))
		var store: RunModifiers = RunModifiers.new()
		var before: Dictionary = _read(measures, store)
		store.add_upgrade(card)
		var after: Dictionary = _read(measures, store)
		var best: String = ""
		var impact: float = 0.0
		for name: String in measures:
			var change: float = absf(after[name] - before[name]) / (measures[name][1] as float)
			if change > impact:
				impact = change
				best = name
		if card.instant_effect == RunModifiers.INSTANT_REPAIR_FORTRESS and card.effect_amount > impact:
			impact = card.effect_amount
			best = "fortress repaired now"
		store.free()
		_check("%s: %s %+d%%%s" % [card.display_name, best, roundi(impact * 100.0), "" if unknown.is_empty() else " (no measure for %s)" % ", ".join(unknown)],
			unknown.is_empty() and impact >= MIN_IMPACT)


## Every measure: name -> [Callable(RunModifiers) -> float, scale].
func _measures(catalog: Array[TowerData]) -> Dictionary:
	var m: Dictionary = {}
	_measure(m, "hero damage", [RunModifiers.HERO_DAMAGE], HERO["damage"], func(s: RunModifiers) -> float: return s.apply(HERO["damage"], [RunModifiers.HERO_DAMAGE]))
	_measure(m, "hero speed", [RunModifiers.HERO_MOVE_SPEED], HERO["speed"], func(s: RunModifiers) -> float: return s.apply(HERO["speed"], [RunModifiers.HERO_MOVE_SPEED]))
	_measure(m, "hero HP", [RunModifiers.HERO_MAX_HEALTH], HERO["health"], func(s: RunModifiers) -> float: return s.apply(HERO["health"], [RunModifiers.HERO_MAX_HEALTH]))
	_measure(m, "hero swing time", [RunModifiers.HERO_ATTACK_COOLDOWN], HERO["cooldown"], func(s: RunModifiers) -> float: return s.apply(HERO["cooldown"], [RunModifiers.HERO_ATTACK_COOLDOWN]))
	_measure(m, "hero reach", [RunModifiers.HERO_REACH], 1.0, func(s: RunModifiers) -> float: return s.apply(1.0, [RunModifiers.HERO_REACH]))
	# The Huntress's bolt (pierce 1, her Mark 15% for 3 s).
	_measure(m, "hero bolt enemies hit", [RunModifiers.HERO_BOLT_PIERCE], 2.0, func(s: RunModifiers) -> float: return 2.0 + s.apply_int(0, [RunModifiers.HERO_BOLT_PIERCE]))
	_measure(m, "hero mark strength", [RunModifiers.HERO_MARK_BONUS, RunModifiers.HERO_MARK_TIME], 0.45, func(s: RunModifiers) -> float:
		return s.apply(0.15, [RunModifiers.HERO_MARK_BONUS]) * s.apply(3.0, [RunModifiers.HERO_MARK_TIME]))
	# The Necromancer's skeletons (30 HP, 3 at a time) and what a fallen one gives back.
	_measure(m, "skeleton health", [RunModifiers.MINION_HEALTH], 30.0, func(s: RunModifiers) -> float: return 30.0 * s.apply(1.0, [RunModifiers.MINION_HEALTH]))
	_measure(m, "skeletons at a time", [RunModifiers.MINION_CAP], 3.0, func(s: RunModifiers) -> float: return 3.0 + s.apply(0.0, [RunModifiers.MINION_CAP]))
	_measure(m, "heal per fallen skeleton", [RunModifiers.HERO_SOUL_FEAST], HERO["health"] * 0.25, func(s: RunModifiers) -> float: return s.apply(0.0, [RunModifiers.HERO_SOUL_FEAST]))
	# The ultimates (M14): how fast the bar charges, the Knight's ring, the Huntress's volley, the Necromancer's skeletons.
	_measure(m, "ultimate charge speed", [RunModifiers.HERO_ULT_CHARGE], 1.0, func(s: RunModifiers) -> float: return s.apply(1.0, [RunModifiers.HERO_ULT_CHARGE]))
	_measure(m, "ultimate radius (px)", [RunModifiers.HERO_ULT_RADIUS], 160.0, func(s: RunModifiers) -> float: return s.apply(160.0, [RunModifiers.HERO_ULT_RADIUS]))
	_measure(m, "volley impacts", [RunModifiers.HERO_ULT_BOLTS], 12.0, func(s: RunModifiers) -> float: return 12.0 + s.apply(0.0, [RunModifiers.HERO_ULT_BOLTS]))
	_measure(m, "ultimate skeletons", [RunModifiers.HERO_ULT_SKELETONS], 5.0, func(s: RunModifiers) -> float: return 5.0 + s.apply(0.0, [RunModifiers.HERO_ULT_SKELETONS]))
	_measure(m, "hero lives", [RunModifiers.HERO_LIVES], HERO["lives"], func(s: RunModifiers) -> float: return s.apply(HERO["lives"], [RunModifiers.HERO_LIVES]))
	_measure(m, "dash cooldown", [RunModifiers.HERO_DASH_COOLDOWN], HERO["dash"], func(s: RunModifiers) -> float:
		return maxf(s.apply(HERO["dash"], [RunModifiers.HERO_DASH_COOLDOWN]), HERO["min_dash"]))
	# The Knight: Bulwark (25% of a hit shrugged off while swinging), Shield Bash's push, Oathkeeper's extra sword hits on a boss, Rally.
	_measure(m, "bulwark: share of a hit shrugged off", [RunModifiers.HERO_BULWARK], 0.5, func(s: RunModifiers) -> float: return s.apply(0.25, [RunModifiers.HERO_BULWARK]))
	_measure(m, "dash knock-back (px)", [RunModifiers.HERO_DASH_BASH], 60.0, func(s: RunModifiers) -> float: return s.apply(0.0, [RunModifiers.HERO_DASH_BASH]))
	_measure(m, "sword hits on a boss per swing", [RunModifiers.HERO_BOSS_HITS], 2.0, func(s: RunModifiers) -> float: return 1.0 + s.apply(0.0, [RunModifiers.HERO_BOSS_HITS]))
	_measure(m, "fire rate near the hero", [RunModifiers.HERO_RALLY], 0.3, func(s: RunModifiers) -> float: return s.apply(0.0, [RunModifiers.HERO_RALLY]))
	_measure(m, "dash trail damage", [RunModifiers.HERO_DASH_TRAIL], HERO_DPS, func(s: RunModifiers) -> float: return s.apply(0.0, [RunModifiers.HERO_DASH_TRAIL]))
	# Building: how much of a wave a fresh tower spends under construction.
	_measure(m, "build time", [RunModifiers.TOWER_BUILD_TIME], WAVE_SECONDS, func(s: RunModifiers) -> float:
		return s.apply(ARCHER.build_time, RunModifiers.tower_stats(RunModifiers.TOWER_BUILD_TIME, ARCHER.id)))
	for data: TowerData in catalog:
		var tier: TowerTier = data.stats_for(data.max_level())
		var id: StringName = data.id
		var base_dps: float = _dps(null, data, tier)
		_measure(m, "%s damage per second" % id, [RunModifiers.TOWER_DAMAGE, RunModifiers.TOWER_FIRE_INTERVAL, RunModifiers.TOWER_BURN], maxf(base_dps, 1.0),
			func(s: RunModifiers) -> float: return _dps(s, data, tier))
		_measure(m, "%s range" % id, [RunModifiers.TOWER_RANGE], tier.attack_range, func(s: RunModifiers) -> float:
			return s.apply(tier.attack_range, RunModifiers.tower_stats(RunModifiers.TOWER_RANGE, id)))
		if tier.slow_duration > 0.0:
			_measure(m, "%s slow time" % id, [RunModifiers.TOWER_SLOW_DURATION], tier.slow_duration, func(s: RunModifiers) -> float:
				return s.apply(tier.slow_duration, RunModifiers.tower_stats(RunModifiers.TOWER_SLOW_DURATION, id)))
		if tier.snare_hold > 0.0:
			_measure(m, "%s snare hold" % id, [RunModifiers.TOWER_SNARE_HOLD], tier.snare_hold, func(s: RunModifiers) -> float:
				return s.apply(tier.snare_hold, RunModifiers.tower_stats(RunModifiers.TOWER_SNARE_HOLD, id)))
		_measure(m, "%s enemies hit per shot" % id, [RunModifiers.TOWER_PIERCE], 1.0 + tier.pierce, func(s: RunModifiers) -> float:
			return 1.0 + s.apply_int(tier.pierce, RunModifiers.tower_stats(RunModifiers.TOWER_PIERCE, id)))
	_measure(m, "fortress HP", [RunModifiers.FORTRESS_MAX_HEALTH], 100.0, func(s: RunModifiers) -> float: return s.apply(100.0, [RunModifiers.FORTRESS_MAX_HEALTH]))
	# Thorns: what a Ghoul takes crossing the thorns before it reaches the walls, against its HP.
	_measure(m, "thorn damage per enemy", [RunModifiers.FORTRESS_THORNS], GHOUL_HP, func(s: RunModifiers) -> float:
		var crossing: float = maxf(Fortress.THORNS_RADIUS + GHOUL.body_radius - (WALL_HALF + GHOUL.body_radius), 0.0) / GHOUL.move_speed
		return s.apply(0.0, [RunModifiers.FORTRESS_THORNS]) * crossing)
	_measure(m, "kill gold", [RunModifiers.KILL_GOLD], 10.0, func(s: RunModifiers) -> float: return s.apply(10.0, [RunModifiers.KILL_GOLD]))
	# Gold paid after a wave (flat + interest on a typical bank), against a wave's kill gold.
	_measure(m, "gold per wave", [RunModifiers.WAVE_INCOME, RunModifiers.INTEREST, RunModifiers.INTEREST_CAP], WAVE_GOLD, func(s: RunModifiers) -> float:
		return s.apply(0.0, [RunModifiers.WAVE_INCOME]) + minf(TYPICAL_BANK * s.apply(0.0, [RunModifiers.INTEREST]), s.apply(0.0, [RunModifiers.INTEREST_CAP])))
	_measure(m, "upgrade prices", [RunModifiers.TOWER_UPGRADE_COST], 100.0, func(s: RunModifiers) -> float: return s.apply(100.0, [RunModifiers.TOWER_UPGRADE_COST]))
	return m


func _measure(m: Dictionary, name: String, stats: Array[StringName], scale: float, read: Callable) -> void:
	m[name] = [read, scale]
	for stat: StringName in stats:
		# Tower stats are bare suffixes ("damage"), read as "tower.damage" or "tower.<id>.damage".
		_known[_generic(stat) if String(stat).contains(".") else "tower.%s" % stat] = true


## A tower's damage per second at `tier` (its shots on its targets, plus its burning ground).
func _dps(store: RunModifiers, data: TowerData, tier: TowerTier) -> float:
	var damage: float = RunModifiers.value(store, tier.damage, RunModifiers.tower_stats(RunModifiers.TOWER_DAMAGE, data.id))
	var interval: float = maxf(RunModifiers.value(store, tier.fire_interval, RunModifiers.tower_stats(RunModifiers.TOWER_FIRE_INTERVAL, data.id)), 0.1)
	var burn: float = RunModifiers.value(store, tier.burn_dps, RunModifiers.tower_stats(RunModifiers.TOWER_BURN, data.id))
	return damage * tier.targets / interval + burn


func _read(measures: Dictionary, store: RunModifiers) -> Dictionary:
	var values: Dictionary = {}
	for name: String in measures:
		values[name] = (measures[name][0] as Callable).call(store)
	return values


## "tower.archer.pierce" -> "tower.pierce": every tower type's stat is measured as one.
func _generic(stat: StringName) -> String:
	var parts: PackedStringArray = String(stat).split(".")
	if parts.size() == 3 and parts[0] == "tower":
		return "tower.%s" % parts[2]
	return String(stat)


# ---------------------------------------------------------------- twists

func _test_affixes() -> void:
	var affixes: Array[AffixData] = []
	for dir: String in [AFFIXES_DIR, EVENTS_DIR]:
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".tres"):
				var resource: Resource = load(dir.path_join(file))
				if resource is AffixData:
					affixes.append(resource)
	var wave: WaveData = WaveData.new()
	for entry: Array in [[GHOUL, 10], [BRUTE, 2], [CULTIST, 2]]:
		var group: SpawnGroup = SpawnGroup.new()
		group.enemy = entry[0]
		group.count = entry[1]
		wave.groups.append(group)
	for affix: AffixData in affixes:
		var changed: WaveData = affix.apply(wave)
		var counts: Callable = func(w: WaveData) -> String:
			return ",".join(w.groups.map(func(g: SpawnGroup) -> String: return "%s%d" % [g.enemy.display_name, g.count]))
		var different: bool = changed.speed_multiplier != wave.speed_multiplier or changed.health_multiplier != wave.health_multiplier \
			or changed.gold_multiplier != wave.gold_multiplier or changed.spawn_shield != wave.spawn_shield or counts.call(changed) != counts.call(wave)
		_check("twist %s changes its waves" % affix.display_name, different)


# ---------------------------------------------------------------- events and shrines

func _test_events() -> void:
	var scenes: Array[EventData] = []
	for chapter: ChapterData in RUN.chapters:
		for scene: EventData in chapter.events + chapter.shrines:
			if not scenes.has(scene):
				scenes.append(scene)
	for scene: EventData in scenes:
		for choice: EventChoice in scene.choices:
			var nothing: bool = choice.effects.is_empty() and choice.fail_effects.is_empty()
			if nothing:
				_check("%s / %s: an honest no-op (\"Nothing happens.\")" % [scene.title, choice.label], choice.outcome == "Nothing happens.")
				continue
			var level: Level = await _fresh_level()
			var before: Dictionary = _snapshot(level)
			var outcome: EventOutcome = level.events.apply(choice)
			var after: Dictionary = _snapshot(level)
			var changes: Array[String] = []
			for key: String in before:
				if before[key] != after[key] and not (key == "gold" and absi(after[key] - before[key]) < MIN_GOLD):
					changes.append(key)
			if outcome != null and (not outcome.choices.is_empty() or outcome.extra_fight != null):
				changes.append("upgrade choice / extra fight")
			_check("%s / %s: changes %s" % [scene.title, choice.label, ", ".join(changes) if not changes.is_empty() else "NOTHING"], outcome != null and not changes.is_empty())
			level.free()


## A level as a run would have it mid-chapter: towers built (one upgradable), an upgrade taken, gold,
## a damaged fortress, all lives.
func _fresh_level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	for _i: int in 2:
		await physics_frame
	level.economy.earn(400, Economy.Source.REFUND)
	level.builder.build(level.builder.get_slots()[3], ARCHER)
	level.builder.build(level.builder.get_slots()[4], ARCHER)
	for _i: int in 50:
		await physics_frame
	level.builder.upgrade(level.builder.get_slots()[4])
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(load(UPGRADES_DIR.path_join("fletching.tres")))
	level.fortress.health.take_damage(30)
	return level


func _snapshot(level: Level) -> Dictionary:
	var towers: int = 0
	var levels: int = 0
	for slot: BuildSlot in level.builder.get_slots():
		if not slot.is_empty():
			towers += 1
			levels += slot.tower.get_level()
	return {"gold": level.economy.get_gold(), "fortress HP": level.fortress.health.current_health,
		"fortress max HP": level.fortress.health.max_health, "lives": level.hero_lives.get_lives_left(),
		"upgrades": (level.get_node("%RunModifiers") as RunModifiers).get_taken().size(), "towers": towers, "tower levels": levels,
		"coming fights": level.events.get_pending_affixes().size(), "free evolutions": level.builder.free_evolutions,
		"merchant prices": level.merchant.next_price_factor}


# ---------------------------------------------------------------- merchant

func _test_merchant() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var shop: Merchant = level.merchant
	_check("the merchant's repair matters (+%d%% of the fortress)" % roundi(shop.repair_fraction * 100.0), shop.repair_fraction >= MIN_IMPACT)
	_check("the merchant sells real cards (%d, from the upgrade pool)" % shop.card_count, shop.card_count >= 2 and shop.common_price > 0 and shop.rare_price > shop.common_price)
	level.free()


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

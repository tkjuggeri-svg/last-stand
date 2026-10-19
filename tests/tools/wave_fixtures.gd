class_name WaveFixtures
## Test helpers: give a level's WaveSpawner simple hand-made waves instead of the level's own.

const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")


## One wave of `count` enemies, one every `interval` seconds, on `lane`.
static func make_wave(count: int, interval: float, enemy: EnemyData = GHOUL, lane: int = 0, delay: float = 0.0) -> WaveData:
	var group: SpawnGroup = SpawnGroup.new()
	group.enemy = enemy
	group.count = count
	group.interval = interval
	group.lane = lane
	group.delay = delay
	var wave: WaveData = WaveData.new()
	wave.groups.append(group)
	return wave


## Replaces the spawner's waves with a single simple wave that starts as soon as the level is
## ready, skipping the build phase (call before the level enters the tree). A second, empty wave
## that never starts keeps the run from being won when the test wave is cleared.
static func single_wave(spawner: WaveSpawner, count: int, interval: float, enemy: EnemyData = GHOUL) -> void:
	spawner.waves = [make_wave(count, interval, enemy), WaveData.new()]
	spawner.autostart = true
	no_upgrades(spawner.get_parent())


## No upgrade offers between waves (a cleared wave goes straight to the build phase), for tests that
## aren't about upgrades. Call before or after the level enters the tree.
static func no_upgrades(level: Node) -> void:
	var offers: UpgradeOffers = level.get_node_or_null("%UpgradeOffers")
	if offers != null:
		offers.pool = []


## Ends the level's build phase like the Start button does. Await it: during a test's _initialize()
## a node added to the tree only becomes ready a frame later.
static func start_wave(level: Node) -> void:
	if not level.is_node_ready():
		await level.ready
	var cycle: RunCycle = level.get_node("%RunCycle")
	var started: bool = cycle.start_wave()
	assert(started, "the level was not in its build phase")

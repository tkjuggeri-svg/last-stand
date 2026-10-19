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


## Replaces the spawner's waves with a single simple wave (call before the level enters the tree).
static func single_wave(spawner: WaveSpawner, count: int, interval: float, enemy: EnemyData = GHOUL) -> void:
	spawner.waves = [make_wave(count, interval, enemy)]

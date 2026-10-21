extends Node2D
## Sandbox (F6): the Drowned Marsh with one wave of chapter 2's enemies on every road (Bloaters, Mire
## Priests behind Ghouls, Shieldbearers) and gold to build with, to try them by hand: burst a Bloater
## far from the fortress, kill a Priest while its ring grows, place towers ahead of and behind a
## Shieldbearer.

const MARSH: PackedScene = preload("res://levels/drowned_marsh.tscn")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BLOATER: EnemyData = preload("res://data/enemies/bloater.tres")
const PRIEST: EnemyData = preload("res://data/enemies/mire_priest.tres")
const SHIELD: EnemyData = preload("res://data/enemies/shieldbearer.tres")
const SANDBOX_GOLD: int = 2000


func _ready() -> void:
	var level: Level = MARSH.instantiate()
	var wave: WaveData = WaveData.new()
	for entry: Array in [[GHOUL, 10, 0], [PRIEST, 2, 0], [BLOATER, 3, 1], [SHIELD, 4, 2], [GHOUL, 8, 2]]:
		wave.groups.append(WaveFixtures.make_wave(entry[1], 2.5, entry[0], entry[2], 3.0).groups[0])
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [wave, WaveData.new()]
	WaveFixtures.no_upgrades(level)
	add_child(level)
	level.economy.earn(SANDBOX_GOLD, Economy.Source.REFUND)

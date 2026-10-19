class_name SpawnGroup
extends Resource
## One group of identical enemies inside a wave: `count` enemies on one lane, the first `delay`
## seconds after the wave starts, then one every `interval` seconds. Groups of a wave run in parallel.

@export var enemy: EnemyData
@export var count: int = 1
## Seconds between two spawns of this group.
@export var interval: float = 1.0
## Index into the level's lanes (WaveSpawner.lanes). 0 = the first lane.
@export var lane: int = 0
## Seconds after the wave starts before this group's first enemy appears.
@export var delay: float = 0.0


## Seconds after the wave start at which this group's `index`-th enemy (0-based) appears.
func spawn_time(index: int) -> float:
	return delay + interval * index

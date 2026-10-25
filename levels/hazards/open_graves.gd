class_name OpenGraves
extends LevelHazard
## The Crypt Road's mechanic: now and then the ground cracks on a road (a ring warns, data.warning s) and
## `count` enemies (Ghouls) climb out of it, joining the wave from the middle of the road instead of its
## start: a defence placed there meets them, one placed at the start does not. Each wave beyond the
## third adds one more (data.amount: a share of the wave number).

## Where on a road it can open (shares of its length): not at the start, not at the fortress.
const FROM: float = 0.3
const TO: float = 0.8

@export var enemy: EnemyData

var _wave: int = 1


func _on_started(wave_number: int) -> void:
	_wave = wave_number


func _strike() -> void:
	var spot: Dictionary = _lane_point(FROM, TO)
	var at: Vector2 = spot["at"]
	var lane: int = spot["lane"]
	_warn(at, data.radius, func() -> void: rise(at, lane))


## The dead climb out at `at` on road `lane` (also called by tests).
func rise(at: Vector2, lane: int) -> void:
	var total: int = data.count + int(floorf(_wave * data.amount))
	for i: int in total:
		spawner.spawn_at(enemy, lane, at + Vector2.from_angle(TAU * i / maxi(total, 1)) * 16.0)

class_name SplitAbility
extends EnemyAbility
## The Bloater's mechanic: killed, it bursts and `count` young (Bloatlings: small, fast) crawl out of
## the gas around where it fell, and walk on along its lane. Its pulsing gas sacs are the warning (its
## idle art) and its death bursts into a gas cloud. Nothing happens if it is used up at the fortress
## instead. Never used on a timer.

@export var minion: EnemyData
@export var count: int = 3
## How far from the body the young land.
@export var spread: float = 18.0


func setup(owner_enemy: Enemy) -> void:
	super(owner_enemy)
	assert(minion != null, "SplitAbility needs a minion")


func _can_start() -> bool:
	return false


func on_owner_died() -> void:
	var turn: float = enemy.get_heading().angle()
	for i: int in count:
		enemy.request_summon(minion, enemy.global_position + Vector2.from_angle(turn + TAU * (i + 0.5) / count) * spread)

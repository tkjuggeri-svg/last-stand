class_name AttackerLimit
extends Node
## Limits how many enemies may attack its owner at the same time. An attacker claims a slot before
## its wind-up and releases it when the strike is over (or when it dies), so others take turns.
## Add it as a child named "AttackerLimit" to anything enemies attack.

const NODE_NAME: StringName = &"AttackerLimit"

@export var max_attackers: int = 2

var _attackers: Array[Object] = []


## The limit on `target`, or null if it has none (then anyone may attack it).
static func find_on(target: Node) -> AttackerLimit:
	return target.get_node_or_null(NodePath(NODE_NAME)) as AttackerLimit


## Returns true if the attacker holds (or now got) a slot.
func try_claim(attacker: Object) -> bool:
	_forget_freed()
	if _attackers.has(attacker):
		return true
	if _attackers.size() >= max_attackers:
		return false
	_attackers.append(attacker)
	return true


func release(attacker: Object) -> void:
	_attackers.erase(attacker)


func get_attacker_count() -> int:
	_forget_freed()
	return _attackers.size()


## Safety net: attackers release their slot when they leave the tree, but never let a freed one
## block a slot. (A plain loop: freed objects can't be passed to a typed lambda.)
func _forget_freed() -> void:
	for i: int in range(_attackers.size() - 1, -1, -1):
		if not is_instance_valid(_attackers[i]):
			_attackers.remove_at(i)

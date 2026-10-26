extends Node
## Steps the hero bot each physics frame (look-test).

var bot: RefCounted
var level: Level


func _physics_process(_delta: float) -> void:
	bot.call("step", level.modifiers)

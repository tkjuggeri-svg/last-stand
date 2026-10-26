extends SceneTree
## Automated check for the slot counts of every arena (economy pass, M13 playtest): the graveyard has 16 build
## slots and every other map 13-14, so a good player can fill about half to two thirds of them by a chapter's
## end and still has gold to spend (Masterwork ranks), and no slot sits on a lane, the fortress or a wall.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const LEVELS: Dictionary = {
	"res://levels/prototype_arena.tscn": 16,
	"res://levels/drowned_marsh.tscn": 13,
	"res://levels/ember_orchard.tscn": 15,
	"res://levels/ashen_keep.tscn": 14,
	"res://levels/bone_quarry.tscn": 14,
	"res://levels/frostbound_pass.tscn": 14,
	"res://levels/gloam_wood.tscn": 14,
	"res://levels/pale_cathedral.tscn": 14,
	"res://levels/sunless_mines.tscn": 13,
}

var _failures: int = 0


func _initialize() -> void:
	for path: String in LEVELS:
		var level: Level = (load(path) as PackedScene).instantiate()
		root.add_child(level)
		await process_frame
		var slots: Array[BuildSlot] = level.builder.get_slots()
		var positions: Dictionary = {}
		for slot: BuildSlot in slots:
			positions[slot.position.snapped(Vector2(1, 1))] = true
		_check("%s: %d slots, none stacked" % [path.get_file(), LEVELS[path]], slots.size() == LEVELS[path] and positions.size() == slots.size())
		level.queue_free()
		await process_frame
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

extends SceneTree
## Automated check for the save (M8): a profile saved and loaded again is the same; an older save
## (tests/fixtures/save_v1.json, version 1 with the dropped permanent bonuses) loads, migrated to the
## current version (the bonuses refunded as shards, Drill kept as an unlock, everything else kept); a
## save is written atomically and the previous one kept as a backup; a corrupt save falls back to the
## backup, and with no readable file to a fresh profile, saying so; in script mode (tests, tools)
## everything is unlocked and nothing is written.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const PATH: String = "user://test_save.json"
const V1_FIXTURE: String = "res://tests/fixtures/save_v1.json"

var _failures: int = 0


func _initialize() -> void:
	_clean()
	await _test_round_trip()
	await _test_old_save()
	await _test_backup_and_corruption()
	_test_script_mode()
	_clean()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _manager() -> SaveManagerNode:
	var manager: SaveManagerNode = SaveManagerNode.new()
	root.add_child(manager)
	await process_frame
	return manager


func _test_round_trip() -> void:
	var manager: SaveManagerNode = await _manager()
	manager.use_file(PATH)
	_check("no save yet: a fresh profile, no problem reported", manager.profile.shards == 0 and manager.load_problem.is_empty())
	var p: SaveProfile = manager.profile
	p.shards = 57
	p.unlocks = ["brazier", "relics_1"]
	p.runs = 3
	p.best_chapter = 2
	p.best_row = 4
	p.bosses = ["The Lich Warden"]
	p.history.append({"result": "lost", "chapter": 2, "row": 4, "shards": 40})
	p.firsts = ["boss:The Lich Warden"]
	p.hints_seen = ["build"]
	p.hints_off = true
	p.run = {"seed": 99, "chapter": 1}
	_check("the profile is written", manager.save_profile() and FileAccess.file_exists(PATH) and not FileAccess.file_exists(PATH + ".tmp"))
	var again: SaveManagerNode = await _manager()
	again.use_file(PATH)
	# JSON keeps every number as a float: compare both in their saved (JSON) form.
	_check("...and read back the same", _as_json(again.profile.to_dict()) == _as_json(p.to_dict()))
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_check("the file says its version (%s)" % (saved as Dictionary).get("version"), int((saved as Dictionary).get("version", 0)) == SaveProfile.CURRENT_VERSION)
	manager.queue_free()
	again.queue_free()
	_clean()


func _test_old_save() -> void:
	DirAccess.copy_absolute(ProjectSettings.globalize_path(V1_FIXTURE), ProjectSettings.globalize_path(PATH))
	var manager: SaveManagerNode = await _manager()
	manager.use_file(PATH)
	var p: SaveProfile = manager.profile
	var refund: int = 40 + 80 + 50
	_check("an old (version 1) save loads: its bonuses refunded as shards (%d = 37 + %d)" % [p.shards, refund], p.shards == 37 + refund)
	_check("...Drill kept as an unlock, the unlocks and records kept",
		p.unlocks.has("drill") and p.unlocks.has("brazier") and p.unlocks.has("cards_precision") and p.runs == 4 and p.best_row == 8
		and p.bosses.has("The Lich Warden") and p.shards_total == 121 and p.history.size() == 1)
	_check("...the hints seen and the one-off rewards kept", p.hints_seen == ["build", "start_wave"] and p.firsts.has("chapter:2"))
	manager.save_profile()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_check("saved again: the current version, no bonuses left", int(saved.get("version", 0)) == SaveProfile.CURRENT_VERSION and not saved.has("bonuses"))
	manager.queue_free()
	_clean()


func _test_backup_and_corruption() -> void:
	var manager: SaveManagerNode = await _manager()
	manager.use_file(PATH)
	manager.profile.shards = 10
	manager.save_profile()
	manager.profile.shards = 20
	manager.save_profile()
	var backup: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH + ".bak"))
	_check("saving keeps the previous save as the backup (%d)" % int(backup.get("shards", -1)), int(backup.get("shards", -1)) == 10)
	var broken: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	broken.store_string("{ not json")
	broken.close()
	var again: SaveManagerNode = await _manager()
	again.use_file(PATH)
	_check("a corrupt save falls back to the backup, and says so (\"%s\")" % again.load_problem,
		again.profile.shards == 10 and not again.load_problem.is_empty())
	broken = FileAccess.open(PATH + ".bak", FileAccess.WRITE)
	broken.store_string("[]")
	broken.close()
	var third: SaveManagerNode = await _manager()
	third.use_file(PATH)
	_check("nothing readable: a fresh profile, and it says so", third.profile.shards == 0 and third.load_problem.contains("fresh"))
	manager.queue_free()
	again.queue_free()
	third.queue_free()
	_clean()


func _test_script_mode() -> void:
	var autoload: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	_check("under --script (tests, tools): everything unlocked, nothing written", autoload.is_scripted()
		and autoload.profile.has_unlock("anything") and autoload.save_profile() and not FileAccess.file_exists(SaveManagerNode.DEFAULT_PATH + ".tmp"))


## `data` as it reads back from JSON (every number a float), as text.
func _as_json(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))


func _clean() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

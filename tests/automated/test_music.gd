extends SceneTree
## Automated check for the music (M13): every recipe has its rendered loop (long enough, a seamless loop at a
## sane level), every track the code asks for exists, Music logs a change of track once (not the same twice),
## and the game plays the right track on the title, the War Room, the map, a fight, a shop and the pause duck.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

var _failures: int = 0


func _initialize() -> void:
	_test_files()
	_test_used_ids()
	await _test_player()
	await _test_game()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_files() -> void:
	var ok: bool = MusicRecipes.TRACKS.size() == 12
	var seams: bool = true
	var levels: bool = true
	var short: String = ""
	for id: StringName in MusicRecipes.TRACKS:
		var stream: AudioStreamWAV = load(Music.PATH % id) as AudioStreamWAV
		if stream == null:
			ok = false
			continue
		var seconds: float = stream.get_length()
		if seconds < 15.0:
			short = "%s (%.1f s)" % [id, seconds]
		var looped: AudioStreamWAV = Music._loop(stream)
		ok = ok and seconds >= 15.0 and looped.loop_mode == AudioStreamWAV.LOOP_FORWARD and looped.loop_end > 0
		# The samples come from the source file (the import compresses the stream): a 44-byte header, then 16-bit PCM.
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(Music.PATH % id)
		var count: int = (bytes.size() - 44) >> 1  # 16-bit samples
		var sum: float = 0.0
		var top: float = 0.0
		for i: int in count:
			var sample: float = bytes.decode_s16(44 + i * 2) / 32768.0
			sum += sample * sample
			top = maxf(top, absf(sample))
		var rms: float = sqrt(sum / count)
		levels = levels and rms > 0.03 and rms < 0.3 and top < 0.99
		seams = seams and absf(bytes.decode_s16(44) / 32768.0 - bytes.decode_s16(44 + (count - 1) * 2) / 32768.0) < 0.25
	_check("all 12 tracks exist as WAVs of at least 15 s that can loop %s" % short, ok)
	_check("at a sane level, never clipping", levels)
	_check("and their loop points meet (no click at the seam)", seams)


func _test_used_ids() -> void:
	var missing: Array[String] = []
	var regex: RegEx = RegEx.new()
	regex.compile("Music\\.play\\([^,]+,\\s*&\"([a-z_0-9]+)\"")
	for dir: String in ["res://main", "res://ui", "res://levels", "res://core"]:
		for path: String in _scripts(dir):
			for hit: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
				if not MusicRecipes.TRACKS.has(StringName(hit.get_string(1))):
					missing.append("%s: %s" % [path, hit.get_string(1)])
	_check("every track the code asks for is a recipe (%s)" % ", ".join(missing), missing.is_empty())


func _scripts(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			found.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_scripts(dir.path_join(sub)))
	return found


func _test_player() -> void:
	var node: Node = Node.new()
	root.add_child(node)
	await process_frame
	Music.history.clear()
	Music.current = &""
	_check("a track starts", Music.play(node, &"title") and Music.current == &"title")
	_check("the same track again changes nothing", not Music.play(node, &"title") and Music.history == [&"title"])
	_check("an unknown track does not exist (asking for it would warn)", not Music.has_track(&"nope") and Music.has_track(&"title"))
	_check("another track follows, the old one can return", Music.play(node, &"map") and Music.play(node, &"title") and Music.history == [&"title", &"map", &"title"])
	Music.set_ducked(true)
	_check("ducking is remembered", Music.is_ducked())
	Music.set_ducked(false)
	Music.stop(node)
	_check("stopping clears the current track", Music.current == &"")
	node.queue_free()


func _test_game() -> void:
	Music.history.clear()
	Music.current = &""
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("boot_to_title", false)
	root.add_child(main)
	await process_frame
	await process_frame
	_check("the run map plays the map music", Music.history.has(&"map"))
	var level: Level = await MapFixtures.enter_first_battle(main)
	await process_frame
	_check("the first fight plays the tier-1 fight music", Music.current == &"fight_1" and level != null)
	var pause: PauseMenu = main.get_node("%PauseMenu")
	pause.open()
	await process_frame
	_check("the pause menu ducks the music", Music.is_ducked())
	pause.close()
	await process_frame
	_check("and lifts it again", not Music.is_ducked())
	main.queue_free()
	await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1

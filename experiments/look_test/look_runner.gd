extends SceneTree
## The look-test runner (experiment branch look-test): plays the stage with one look variant, saves
## screenshots, and measures the frame rate (vsync off). Needs a window (not --headless).
##   godot --path . --resolution 1280x720 --script res://experiments/look_test/look_runner.gd -- \
##     --variant=base|a|b --out=exports/look-test [--seconds=20] [--shots=4,10,16] [--measure] [--tag=compat]
## Add `--write-movie <file>.avi --fixed-fps 30` before `--script` to record the same run as a video.

var _variant: String = "base"
var _out: String = "exports/look-test"
var _seconds: float = 20.0
var _shots: Array[float] = [4.0, 10.0, 16.0]
var _measure: bool = false
## Movie mode: play this many frames (the movie writer's clock is not the wall clock); 0: play `_seconds`.
var _movie_frames: int = 0
var _tag: String = "compat"
## Seconds at the start left out of the measurement (the first wave spawns, shaders compile).
const WARMUP: float = 3.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="):
			_variant = arg.trim_prefix("--variant=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--shots="):
			_shots.clear()
			for part: String in arg.trim_prefix("--shots=").split(","):
				_shots.append(float(part))
		elif arg.begins_with("--movie-frames="):
			_movie_frames = int(arg.trim_prefix("--movie-frames="))
		elif arg == "--measure":
			_measure = true
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	if _measure:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_run.call_deferred()


func _run() -> void:
	var host: Node = Node.new()
	root.add_child(host)
	var level: Level
	var presenter: Node = null
	if _variant == "b":
		presenter = (load("res://experiments/look_test/variant_b/look_b.gd") as GDScript).new()
		host.add_child(presenter)
	level = await LookStage.build(host, self)
	if _variant == "a":
		presenter = (load("res://experiments/look_test/variant_a/look_a.gd") as GDScript).new()
		host.add_child(presenter)
		presenter.call("attach", level)
	elif _variant == "b":
		presenter.call("attach", level)
	for _i: int in 10:
		await process_frame
	LookStage.add_bot(level)
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	var started: int = Time.get_ticks_usec()
	var times: Array[float] = []
	var last: int = started
	var next_shot: int = 0
	var elapsed: float = 0.0
	var skip_next: bool = false
	var most_enemies: int = 0
	var frame_count: int = 0
	while (elapsed < _seconds) if _movie_frames == 0 else (frame_count < _movie_frames):
		frame_count += 1
		await process_frame
		var now: int = Time.get_ticks_usec()
		elapsed = (now - started) / 1000000.0
		if elapsed > WARMUP and not skip_next:
			times.append((now - last) / 1000.0)
		skip_next = false
		last = now
		most_enemies = maxi(most_enemies, (level.get_node("WaveSpawner") as WaveSpawner).get_living_count())
		if next_shot < _shots.size() and elapsed >= _shots[next_shot]:
			var file: String = "%s/%s_%s_t%02d.png" % [_out, _variant, _tag, int(_shots[next_shot])]
			root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
			print("saved ", file)
			next_shot += 1
			skip_next = true  # saving the PNG stalls the next frame; it is not what is measured
			last = Time.get_ticks_usec()
	if _measure:
		_report(times, most_enemies)
	quit()


func _report(times: Array[float], most_enemies: int) -> void:
	var sorted: Array[float] = times.duplicate()
	sorted.sort()
	var total: float = 0.0
	for t: float in times:
		total += t
	var worst_count: int = maxi(int(sorted.size() / 100.0), 1)
	var worst_sum: float = 0.0
	for i: int in worst_count:
		worst_sum += sorted[sorted.size() - 1 - i]
	var text: String = "%s (%s): %d frames, avg %.1f fps (%.2f ms), 1%% low %.1f fps, worst frame %.1f ms, enemies up to %d | %s %s" % [
		_variant, _tag, times.size(), 1000.0 * times.size() / total, total / times.size(),
		1000.0 / (worst_sum / worst_count), sorted.back(), most_enemies,
		RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method()]
	print(text)
	var file: FileAccess = FileAccess.open(ProjectSettings.globalize_path("%s/fps_%s_%s.txt" % [_out, _variant, _tag]), FileAccess.WRITE)
	file.store_line(text)
	file.close()

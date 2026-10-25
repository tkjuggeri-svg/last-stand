class_name Music
## Plays the game's music (M13; the tracks: tools/audio/music_recipes.gd, rendered to assets/audio/music/).
## No autoload, like Sfx: Music.play(node, id) crossfades to track `id` on the Music bus, using two players
## kept under the tree's root so the music goes on across scenes and while the game is paused. A track
## returned to resumes where it was left. Asking for the track already playing does nothing. The pause menu
## ducks it. Display only: nothing in the game depends on it. In headless runs (tests, tools) nothing is
## played, but every change of track is logged (`history`).

const PATH: String = "res://assets/audio/music/%s.wav"
const BUS: StringName = &"Music"
## Seconds of the crossfade, and how far the music ducks (dB) under the pause menu.
const FADE: float = 1.2
const DUCK_DB: float = -9.0
const SILENT_DB: float = -60.0
const LOG_SIZE: int = 100

## The tracks played, newest last (tests read it).
static var history: Array[StringName] = []
static var current: StringName = &""

static var _players: Array[AudioStreamPlayer] = []
static var _active: int = 0
static var _positions: Dictionary = {}
static var _ducked: bool = false
static var _headless: bool = DisplayServer.get_name() == "headless"


## True if track `id` exists.
static func has_track(id: StringName) -> bool:
	return ResourceLoader.exists(PATH % id)


## Crossfades to track `id`. Returns false if nothing changed (unknown id, already playing, `node` not in the tree).
static func play(node: Node, id: StringName) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree() or id == current:
		return false
	if not has_track(id):
		push_warning("Unknown music track: %s" % id)
		return false
	_remember_position()
	current = id
	history.append(id)
	if history.size() > LOG_SIZE:
		history.pop_front()
	if not _headless:
		_crossfade(node.get_tree(), id)
	return true


## Fades the music out.
static func stop(node: Node) -> void:
	if current == &"" or not is_instance_valid(node) or not node.is_inside_tree():
		return
	_remember_position()
	current = &""
	if not _headless and not _players.is_empty():
		_fade(node.get_tree(), _players[_active], SILENT_DB, true)


## Ducks the music under a menu (or lifts it again).
static func set_ducked(on: bool) -> void:
	_ducked = on
	if _headless or _players.is_empty() or not is_instance_valid(_players[_active]):
		return
	var tree: SceneTree = _players[_active].get_tree()
	if tree != null and current != &"":
		_fade(tree, _players[_active], _level_db(), false)


static func is_ducked() -> bool:
	return _ducked


static func _level_db() -> float:
	return DUCK_DB if _ducked else 0.0


static func _remember_position() -> void:
	if current != &"" and not _players.is_empty() and is_instance_valid(_players[_active]) and _players[_active].playing:
		_positions[current] = _players[_active].get_playback_position()


static func _crossfade(tree: SceneTree, id: StringName) -> void:
	_ensure_players(tree)
	var outgoing: AudioStreamPlayer = _players[_active]
	_active = 1 - _active
	var incoming: AudioStreamPlayer = _players[_active]
	incoming.stream = _loop(load(PATH % id) as AudioStreamWAV)
	incoming.volume_db = SILENT_DB
	incoming.play(float(_positions.get(id, 0.0)))
	_fade(tree, incoming, _level_db(), false)
	_fade(tree, outgoing, SILENT_DB, true)


## A looping copy of `track` (the import does not keep the loop of a generated WAV).
static func _loop(track: AudioStreamWAV) -> AudioStreamWAV:
	var looped: AudioStreamWAV = track.duplicate() as AudioStreamWAV
	looped.loop_mode = AudioStreamWAV.LOOP_FORWARD
	looped.loop_begin = 0
	looped.loop_end = roundi(track.get_length() * track.mix_rate)
	return looped


static func _ensure_players(tree: SceneTree) -> void:
	_players = _players.filter(func(p: AudioStreamPlayer) -> bool: return is_instance_valid(p))
	while _players.size() < 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(player)
		_players.append(player)


static func _fade(tree: SceneTree, player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	var tween: Tween = tree.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ignore_time_scale(true)  # the pause menu stops game time; the music must still move
	tween.tween_property(player, "volume_db", to_db, FADE)
	if stop_after:
		tween.tween_callback(func() -> void:
			if is_instance_valid(player) and player != _players[_active]:
				player.stop())

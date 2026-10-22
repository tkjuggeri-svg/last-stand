class_name Sfx
## Plays the game's sound effects (M8.5; the sounds and their mix: data/audio/sfx_library.tres, made by
## tools/audio/). No autoload: Sfx.play(node, id) makes a one-shot player on the SFX bus, under the
## tree's root so it outlives the node that asked (an enemy that dies). A world sound is heard from
## where `node` is (2D, panned, quieter far off); the others are centred (UI, announcements) and also
## play while the game is paused (the choice screens). Each sound has a voice limit and a minimum
## spacing, so fifty deaths in a frame don't stack. Display only: nothing in the game depends on it.
## In headless runs (tests, tools) nothing is played, but every accepted sound is logged (`history`).

const LIBRARY_PATH: String = "res://data/audio/sfx_library.tres"
const BUS: StringName = &"SFX"
## A world sound fades to nothing this far (px) from the camera's centre.
const MAX_DISTANCE: float = 1700.0
## How fast it fades with distance (AudioStreamPlayer2D.attenuation: gentle).
const ATTENUATION: float = 0.6
## How many accepted sounds the log keeps (tests).
const LOG_SIZE: int = 200

## The last accepted sounds, newest last (tests read it).
static var history: Array[StringName] = []

static var _library: SfxLibrary
static var _playing: Dictionary = {}
static var _last_msec: Dictionary = {}
static var _headless: bool = DisplayServer.get_name() == "headless"


## Plays sound `id` for `node` (from where it is, for a world sound). Returns false if it was skipped
## (an unknown id, its voice limit, too soon after the last one, or `node` not in the tree).
static func play(node: Node, id: StringName) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	var entry: SfxEntry = _entry(id)
	if entry == null:
		push_warning("Unknown sound: %s" % id)
		return false
	var now: int = Time.get_ticks_msec()
	if int(_playing.get(id, 0)) >= entry.voices or now - int(_last_msec.get(id, -1000000)) < roundi(entry.interval * 1000.0):
		return false
	_last_msec[id] = now
	history.append(id)
	if history.size() > LOG_SIZE:
		history.pop_front()
	if _headless:
		return true
	_start(node, entry)
	return true


## True if the library has sound `id`.
static func has(id: StringName) -> bool:
	return _entry(id) != null


## Forgets the log, the voices and the spacing (tests).
static func reset() -> void:
	history.clear()
	_playing.clear()
	_last_msec.clear()


static func _start(node: Node, entry: SfxEntry) -> void:
	var player: Node
	if entry.world and node is Node2D:
		var positional: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		positional.max_distance = MAX_DISTANCE
		positional.attenuation = ATTENUATION
		positional.position = (node as Node2D).global_position
		_setup(positional, entry)
		player = positional
	else:
		var flat: AudioStreamPlayer = AudioStreamPlayer.new()
		_setup(flat, entry)
		flat.process_mode = Node.PROCESS_MODE_ALWAYS
		player = flat
	var id: StringName = entry.id
	_playing[id] = int(_playing.get(id, 0)) + 1
	player.tree_exiting.connect(func() -> void: _playing[id] = maxi(int(_playing.get(id, 1)) - 1, 0))
	player.connect(&"finished", player.queue_free)
	node.get_tree().root.add_child(player)
	player.call(&"play")


static func _setup(player: Node, entry: SfxEntry) -> void:
	player.set(&"stream", entry.stream)
	player.set(&"volume_db", entry.volume_db)
	player.set(&"bus", BUS)
	player.set(&"pitch_scale", 1.0 + randf_range(-entry.jitter, entry.jitter))


static func _entry(id: StringName) -> SfxEntry:
	if _library == null:
		_library = load(LIBRARY_PATH) as SfxLibrary
	return _library.find(id) if _library != null else null

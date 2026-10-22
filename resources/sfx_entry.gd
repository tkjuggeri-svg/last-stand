class_name SfxEntry
extends Resource
## One sound effect and its place in the mix (M8.5). Written by tools/audio/build_sfx_library.gd from
## SfxRecipes; played by Sfx.

@export var id: StringName = &""
@export var stream: AudioStream
@export var volume_db: float = -10.0
## At most this many at once (more are skipped).
@export var voices: int = 2
## Seconds: never two closer than this.
@export var interval: float = 0.05
## Random pitch change, +- this share.
@export var jitter: float = 0.0
## Heard from where it happens (2D, panned), else centred (UI, announcements).
@export var world: bool = false

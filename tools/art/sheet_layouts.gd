extends RefCounted
## Spritesheet layouts shared by generate_art.gd (which draws the sheets) and
## build_sprite_frames.gd (which slices them into SpriteFrames).
## Animations are [name, row, frame_count, fps, loop]. One art pixel = 2 world pixels (ART_SCALE).

const ART_SCALE: int = 2

const HERO: Dictionary = {
	"png": "res://assets/sprites/hero/hero.png",
	"frames": "res://entities/hero/hero_frames.tres",
	"size": Vector2i(24, 24),
	"anims": [
		["idle_down", 0, 2, 2.5, true],
		["idle_up", 1, 2, 2.5, true],
		["idle_side", 2, 2, 2.5, true],
		["walk_down", 3, 4, 8.0, true],
		["walk_up", 4, 4, 8.0, true],
		["walk_side", 5, 4, 8.0, true],
		["attack_down", 6, 3, 15.0, false],
		["attack_up", 7, 3, 15.0, false],
		["attack_side", 8, 3, 15.0, false],
		["death", 9, 4, 6.0, false],
	],
}

## Sword swing trail in 8 directions: swing_0 points right, then every 45 degrees clockwise.
const SWING: Dictionary = {
	"png": "res://assets/sprites/effects/swing.png",
	"frames": "res://entities/hero/swing_frames.tres",
	"size": Vector2i(72, 72),
	"anims": [
		["swing_0", 0, 3, 20.0, false],
		["swing_1", 1, 3, 20.0, false],
		["swing_2", 2, 3, 20.0, false],
		["swing_3", 3, 3, 20.0, false],
		["swing_4", 4, 3, 20.0, false],
		["swing_5", 5, 3, 20.0, false],
		["swing_6", 6, 3, 20.0, false],
		["swing_7", 7, 3, 20.0, false],
	],
}

const GHOUL: Dictionary = {
	"png": "res://assets/sprites/enemies/ghoul.png",
	"frames": "res://entities/enemies/ghoul_frames.tres",
	"size": Vector2i(20, 20),
	"anims": [
		["idle_down", 0, 2, 3.0, true],
		["idle_up", 1, 2, 3.0, true],
		["idle_side", 2, 2, 3.0, true],
		["walk_down", 3, 4, 6.0, true],
		["walk_up", 4, 4, 6.0, true],
		["walk_side", 5, 4, 6.0, true],
		["death", 6, 5, 10.0, false],
		["attack_down", 7, 3, 6.0, false],
		["attack_up", 8, 3, 6.0, false],
		["attack_side", 9, 3, 6.0, false],
	],
}

const HIT_SPARK: Dictionary = {
	"png": "res://assets/sprites/effects/hit_spark.png",
	"frames": "res://entities/effects/hit_spark_frames.tres",
	"size": Vector2i(12, 12),
	"anims": [["spark", 0, 3, 20.0, false]],
}

const DUST: Dictionary = {
	"png": "res://assets/sprites/effects/dust.png",
	"frames": "res://entities/effects/dust_frames.tres",
	"size": Vector2i(20, 20),
	"anims": [["dust", 0, 5, 12.0, false]],
}

## All sheets that become SpriteFrames.
const ANIMATED: Array[Dictionary] = [HERO, SWING, GHOUL, HIT_SPARK, DUST]

## Single-row sheet used directly by a Sprite2D (hframes): healthy, damaged, badly damaged, destroyed.
## The 48x48 keep (= the 96 px collision box) sits at (2, 2) inside each frame; the rest is drop shadow.
const FORTRESS: Dictionary = {
	"png": "res://assets/sprites/fortress/fortress.png",
	"size": Vector2i(52, 52),
	"frames_count": 4,
}

const GROUND_PNG: String = "res://assets/sprites/environment/prototype_arena_ground.png"
## Width of the visible stone wall band drawn outside the playable floor, in world pixels.
const WALL_BAND: int = 32

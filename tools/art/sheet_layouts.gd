extends RefCounted
## Spritesheet layouts shared by generate_art.gd (which draws the sheets) and
## build_sprite_frames.gd (which slices them into SpriteFrames).
## Animations are [name, row, frame_count, fps, loop]. One art pixel = 2 world pixels (ART_SCALE).

const ART_SCALE: int = 2

const HERO: Dictionary = {
	"png": "res://assets/sprites/hero/hero.png",
	"frames": "res://entities/hero/hero_frames.tres",
	"size": Vector2i(32, 40),
	"anims": [
		["idle_down", 0, 4, 5.0, true],
		["idle_up", 1, 4, 5.0, true],
		["idle_side", 2, 4, 5.0, true],
		["walk_down", 3, 6, 11.0, true],
		["walk_up", 4, 6, 11.0, true],
		["walk_side", 5, 6, 11.0, true],
		["attack_down", 6, 4, 20.0, false],
		["attack_up", 7, 4, 20.0, false],
		["attack_side", 8, 4, 20.0, false],
		["death", 9, 6, 8.0, false],
	],
}

## Sword swing trail in 8 directions: swing_0 points right, then every 45 degrees clockwise.
const SWING: Dictionary = {
	"png": "res://assets/sprites/effects/swing.png",
	"frames": "res://entities/hero/swing_frames.tres",
	"size": Vector2i(72, 72),
	"anims": [
		["swing_0", 0, 4, 24.0, false],
		["swing_1", 1, 4, 24.0, false],
		["swing_2", 2, 4, 24.0, false],
		["swing_3", 3, 4, 24.0, false],
		["swing_4", 4, 4, 24.0, false],
		["swing_5", 5, 4, 24.0, false],
		["swing_6", 6, 4, 24.0, false],
		["swing_7", 7, 4, 24.0, false],
	],
}

const GHOUL: Dictionary = {
	"png": "res://assets/sprites/enemies/ghoul.png",
	"frames": "res://entities/enemies/ghoul_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [
		["idle_down", 0, 4, 5.0, true],
		["idle_up", 1, 4, 5.0, true],
		["idle_side", 2, 4, 5.0, true],
		["walk_down", 3, 6, 8.0, true],
		["walk_up", 4, 6, 8.0, true],
		["walk_side", 5, 6, 8.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 6, 12.0, false],
		["attack_up", 8, 6, 12.0, false],
		["attack_side", 9, 6, 12.0, false],
	],
}

const HIT_SPARK: Dictionary = {
	"png": "res://assets/sprites/effects/hit_spark.png",
	"frames": "res://entities/effects/hit_spark_frames.tres",
	"size": Vector2i(16, 16),
	"anims": [["spark", 0, 4, 24.0, false]],
}

const DUST: Dictionary = {
	"png": "res://assets/sprites/effects/dust.png",
	"frames": "res://entities/effects/dust_frames.tres",
	"size": Vector2i(24, 24),
	"anims": [["dust", 0, 6, 14.0, false]],
}

## The three towers (24x32 art = 48x64 world px; the base sits at the bottom of the frame).
const TOWERS: Dictionary = {
	"png": "res://assets/sprites/towers/towers.png",
	"frames": "res://entities/towers/tower_frames.tres",
	"size": Vector2i(24, 32),
	"anims": [
		["archer_idle", 0, 2, 2.0, true],
		["archer_fire", 1, 3, 12.0, false],
		["cannon_idle", 2, 2, 2.0, true],
		["cannon_fire", 3, 3, 10.0, false],
		["frost_idle", 4, 2, 3.0, true],
		["frost_fire", 5, 3, 12.0, false],
	],
}

## Arrows in 8 directions (arrow_0 points right, then every 45 degrees clockwise), cannonball, frost bolt.
const PROJECTILES: Dictionary = {
	"png": "res://assets/sprites/towers/projectiles.png",
	"frames": "res://entities/towers/projectile_frames.tres",
	"size": Vector2i(12, 12),
	"anims": [
		["arrow_0", 0, 1, 1.0, false],
		["arrow_1", 1, 1, 1.0, false],
		["arrow_2", 2, 1, 1.0, false],
		["arrow_3", 3, 1, 1.0, false],
		["arrow_4", 4, 1, 1.0, false],
		["arrow_5", 5, 1, 1.0, false],
		["arrow_6", 6, 1, 1.0, false],
		["arrow_7", 7, 1, 1.0, false],
		["cannonball", 8, 1, 1.0, false],
		["frost_bolt", 9, 2, 8.0, true],
	],
}

const EXPLOSION: Dictionary = {
	"png": "res://assets/sprites/effects/explosion.png",
	"frames": "res://entities/effects/explosion_frames.tres",
	"size": Vector2i(56, 56),
	"anims": [["explosion", 0, 5, 14.0, false]],
}

const FROST_FX: Dictionary = {
	"png": "res://assets/sprites/effects/frost.png",
	"frames": "res://entities/effects/frost_frames.tres",
	"size": Vector2i(20, 20),
	"anims": [["frost_burst", 0, 4, 14.0, false], ["frost_aura", 1, 2, 4.0, true]],
}

## All sheets that become SpriteFrames.
const ANIMATED: Array[Dictionary] = [HERO, SWING, GHOUL, HIT_SPARK, DUST, TOWERS, PROJECTILES, EXPLOSION, FROST_FX]

## Build slot pad for a Sprite2D (hframes 2): normal, highlighted (the hero is close).
const BUILD_SLOT: Dictionary = {
	"png": "res://assets/sprites/towers/build_slot.png",
	"size": Vector2i(28, 20),
}

## Single-row sheet used directly by a Sprite2D (hframes): healthy, damaged, badly damaged, destroyed.
## The 48x48 keep (= the 96 px collision box) sits at (2, 2) inside each frame; the rest is drop shadow.
const FORTRESS: Dictionary = {
	"png": "res://assets/sprites/fortress/fortress.png",
	"size": Vector2i(52, 52),
	"frames_count": 4,
}

## Small UI icons (single images, drawn at the same 2x scale as everything else).
const COIN_PNG: String = "res://assets/sprites/ui/coin.png"

const GROUND_PNG: String = "res://assets/sprites/environment/prototype_arena_ground.png"
## Width of the visible stone wall band drawn outside the playable floor, in world pixels.
const WALL_BAND: int = 32

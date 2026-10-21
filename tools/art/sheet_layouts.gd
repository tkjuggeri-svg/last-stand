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

## Long Reach swing trails ("swing_<direction>_<tier>", tier 1-4 = reach x1.15 .. x1.6), 128x128.
const SWING_LONG: Dictionary = {
	"png": "res://assets/sprites/effects/swing_long.png",
	"frames": "res://entities/hero/swing_long_frames.tres",
	"size": Vector2i(128, 128),
	"anims": [
		["swing_0_1", 0, 4, 24.0, false],
		["swing_1_1", 1, 4, 24.0, false],
		["swing_2_1", 2, 4, 24.0, false],
		["swing_3_1", 3, 4, 24.0, false],
		["swing_4_1", 4, 4, 24.0, false],
		["swing_5_1", 5, 4, 24.0, false],
		["swing_6_1", 6, 4, 24.0, false],
		["swing_7_1", 7, 4, 24.0, false],
		["swing_0_2", 8, 4, 24.0, false],
		["swing_1_2", 9, 4, 24.0, false],
		["swing_2_2", 10, 4, 24.0, false],
		["swing_3_2", 11, 4, 24.0, false],
		["swing_4_2", 12, 4, 24.0, false],
		["swing_5_2", 13, 4, 24.0, false],
		["swing_6_2", 14, 4, 24.0, false],
		["swing_7_2", 15, 4, 24.0, false],
		["swing_0_3", 16, 4, 24.0, false],
		["swing_1_3", 17, 4, 24.0, false],
		["swing_2_3", 18, 4, 24.0, false],
		["swing_3_3", 19, 4, 24.0, false],
		["swing_4_3", 20, 4, 24.0, false],
		["swing_5_3", 21, 4, 24.0, false],
		["swing_6_3", 22, 4, 24.0, false],
		["swing_7_3", 23, 4, 24.0, false],
		["swing_0_4", 24, 4, 24.0, false],
		["swing_1_4", 25, 4, 24.0, false],
		["swing_2_4", 26, 4, 24.0, false],
		["swing_3_4", 27, 4, 24.0, false],
		["swing_4_4", 28, 4, 24.0, false],
		["swing_5_4", 29, 4, 24.0, false],
		["swing_6_4", 30, 4, 24.0, false],
		["swing_7_4", 31, 4, 24.0, false],
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

## The Grave Hound: same rows as the Ghoul; "walk" is a fast gallop. Attack: 4 wind-up frames at
## 16 fps = the data's 0.25 s, then the bite.
const HOUND: Dictionary = {
	"png": "res://assets/sprites/enemies/hound.png",
	"frames": "res://entities/enemies/hound_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [
		["idle_down", 0, 4, 6.0, true],
		["idle_up", 1, 4, 6.0, true],
		["idle_side", 2, 4, 6.0, true],
		["walk_down", 3, 6, 14.0, true],
		["walk_up", 4, 6, 14.0, true],
		["walk_side", 5, 6, 14.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 6, 16.0, false],
		["attack_up", 8, 6, 16.0, false],
		["attack_side", 9, 6, 16.0, false],
	],
}

## The Brute: 48x48 frames (feet on art row 44). A slow, heavy walk; attack: 6 wind-up frames at
## 10 fps = the data's 0.6 s, then the slam and a recover frame.
const BRUTE: Dictionary = {
	"png": "res://assets/sprites/enemies/brute.png",
	"frames": "res://entities/enemies/brute_frames.tres",
	"size": Vector2i(48, 48),
	"anims": [
		["idle_down", 0, 4, 4.0, true],
		["idle_up", 1, 4, 4.0, true],
		["idle_side", 2, 4, 4.0, true],
		["walk_down", 3, 6, 6.0, true],
		["walk_up", 4, 6, 6.0, true],
		["walk_side", 5, 6, 6.0, true],
		["death", 6, 7, 10.0, false],
		["attack_down", 7, 8, 10.0, false],
		["attack_up", 8, 8, 10.0, false],
		["attack_side", 9, 8, 10.0, false],
	],
}

## The Cultist: same rows as the Ghoul; the walk is a glide. Attack: 6 wind-up frames at 12 fps
## = the data's 0.5 s (the witchfire swells overhead), then the release and a recover frame.
const CULTIST: Dictionary = {
	"png": "res://assets/sprites/enemies/cultist.png",
	"frames": "res://entities/enemies/cultist_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [
		["idle_down", 0, 4, 6.0, true],
		["idle_up", 1, 4, 6.0, true],
		["idle_side", 2, 4, 6.0, true],
		["walk_down", 3, 6, 8.0, true],
		["walk_up", 4, 6, 8.0, true],
		["walk_side", 5, 6, 8.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 8, 12.0, false],
		["attack_up", 8, 8, 12.0, false],
		["attack_side", 9, 8, 12.0, false],
	],
}

## The Cultist's witchfire bolt (flying, looped) and its burst.
const CULTIST_FX: Dictionary = {
	"png": "res://assets/sprites/enemies/cultist_fx.png",
	"frames": "res://entities/enemies/cultist_fx_frames.tres",
	"size": Vector2i(16, 16),
	"anims": [["bolt", 0, 2, 10.0, true], ["burst", 1, 4, 18.0, false]],
}

## Bosses: 64x64 frames (feet on art row 58, boss_art_kit.gd). Attack: 6 wind-up frames at 10 fps =
## the data's 0.6 s, then the blow. Abilities: "cast" is 6 frames at 5 fps = the 1.2 s telegraph.
## The Gravelord (wave 5): raises the dead.
const GRAVELORD: Dictionary = {
	"png": "res://assets/sprites/enemies/gravelord.png",
	"frames": "res://entities/enemies/bosses/gravelord_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [
		["idle_down", 0, 4, 4.0, true],
		["idle_up", 1, 4, 4.0, true],
		["idle_side", 2, 4, 4.0, true],
		["walk_down", 3, 6, 6.0, true],
		["walk_up", 4, 6, 6.0, true],
		["walk_side", 5, 6, 6.0, true],
		["death", 6, 8, 10.0, false],
		["attack_down", 7, 8, 10.0, false],
		["attack_up", 8, 8, 10.0, false],
		["attack_side", 9, 8, 10.0, false],
		["cast_down", 10, 6, 5.0, false],
		["cast_up", 11, 6, 5.0, false],
		["cast_side", 12, 6, 5.0, false],
	],
}

## The Bone Colossus (wave 10): braces (looped through the 1.0 s telegraph), charges, is stunned.
const COLOSSUS: Dictionary = {
	"png": "res://assets/sprites/enemies/colossus.png",
	"frames": "res://entities/enemies/bosses/colossus_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [
		["idle_down", 0, 4, 4.0, true],
		["idle_up", 1, 4, 4.0, true],
		["idle_side", 2, 4, 4.0, true],
		["walk_down", 3, 6, 6.0, true],
		["walk_up", 4, 6, 6.0, true],
		["walk_side", 5, 6, 6.0, true],
		["death", 6, 8, 10.0, false],
		["attack_down", 7, 8, 10.0, false],
		["attack_up", 8, 8, 10.0, false],
		["attack_side", 9, 8, 10.0, false],
		["brace_down", 10, 4, 8.0, true],
		["brace_up", 11, 4, 8.0, true],
		["brace_side", 12, 4, 8.0, true],
		["charge_down", 13, 4, 12.0, true],
		["charge_up", 14, 4, 12.0, true],
		["charge_side", 15, 4, 12.0, true],
		["stun_down", 16, 4, 6.0, true],
		["stun_up", 17, 4, 6.0, true],
		["stun_side", 18, 4, 6.0, true],
	],
}

## The Lich Warden (wave 15): wards the enemies around it.
const LICH: Dictionary = {
	"png": "res://assets/sprites/enemies/lich.png",
	"frames": "res://entities/enemies/bosses/lich_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [
		["idle_down", 0, 4, 4.0, true],
		["idle_up", 1, 4, 4.0, true],
		["idle_side", 2, 4, 4.0, true],
		["walk_down", 3, 6, 6.0, true],
		["walk_up", 4, 6, 6.0, true],
		["walk_side", 5, 6, 6.0, true],
		["death", 6, 8, 10.0, false],
		["attack_down", 7, 8, 10.0, false],
		["attack_up", 8, 8, 10.0, false],
		["attack_side", 9, 8, 10.0, false],
		["cast_down", 10, 6, 5.0, false],
		["cast_up", 11, 6, 5.0, false],
		["cast_side", 12, 6, 5.0, false],
	],
}

## The Tollkeeper (chapter 2's boss, M7): the toll heaves the bell up and swings it.
const TOLLKEEPER: Dictionary = {
	"png": "res://assets/sprites/enemies/tollkeeper.png",
	"frames": "res://entities/enemies/bosses/tollkeeper_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [
		["idle_down", 0, 4, 4.0, true],
		["idle_up", 1, 4, 4.0, true],
		["idle_side", 2, 4, 4.0, true],
		["walk_down", 3, 6, 6.0, true],
		["walk_up", 4, 6, 6.0, true],
		["walk_side", 5, 6, 6.0, true],
		["death", 6, 8, 10.0, false],
		["attack_down", 7, 8, 10.0, false],
		["attack_up", 8, 8, 10.0, false],
		["attack_side", 9, 8, 10.0, false],
		["toll_down", 10, 6, 6.0, false],
		["toll_up", 11, 6, 6.0, false],
		["toll_side", 12, 6, 6.0, false],
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

## The three towers (32x48 art = 64x96 world px; the base rests on art row 45, the sprite is placed so
## that is +4 world px below the slot centre). Per tower: idle, fire, build (rising in scaffolding)
## and sell (dismantled into rubble, played by the TowerDismantle effect); levels 2 and 3 add their
## own idle and fire ("<id>_idle_2", ...).
const TOWERS: Dictionary = {
	"png": "res://assets/sprites/towers/towers.png",
	"frames": "res://entities/towers/tower_frames.tres",
	"size": Vector2i(32, 48),
	"anims": [
		["archer_idle", 0, 4, 5.0, true],
		["archer_fire", 1, 4, 12.0, false],
		["archer_build", 2, 6, 10.0, false],
		["archer_sell", 3, 6, 10.0, false],
		["cannon_idle", 4, 4, 5.0, true],
		["cannon_fire", 5, 5, 12.0, false],
		["cannon_build", 6, 6, 10.0, false],
		["cannon_sell", 7, 6, 10.0, false],
		["frost_idle", 8, 4, 6.0, true],
		["frost_fire", 9, 4, 12.0, false],
		["frost_build", 10, 6, 10.0, false],
		["frost_sell", 11, 6, 10.0, false],
		# Upgraded levels (2 and 3): their own idle and fire.
		["archer_idle_2", 12, 4, 5.0, true],
		["archer_fire_2", 13, 4, 12.0, false],
		["archer_idle_3", 14, 4, 5.0, true],
		["archer_fire_3", 15, 4, 12.0, false],
		["cannon_idle_2", 16, 4, 5.0, true],
		["cannon_fire_2", 17, 5, 12.0, false],
		["cannon_idle_3", 18, 4, 5.0, true],
		["cannon_fire_3", 19, 5, 12.0, false],
		["frost_idle_2", 20, 4, 6.0, true],
		["frost_fire_2", 21, 4, 12.0, false],
		["frost_idle_3", 22, 4, 6.0, true],
		["frost_fire_3", 23, 4, 12.0, false],
		# M5 towers: Brazier, Bone Ballista.
		["brazier_idle", 24, 4, 6.0, true],
		["brazier_fire", 25, 4, 12.0, false],
		["brazier_build", 26, 6, 10.0, false],
		["brazier_sell", 27, 6, 10.0, false],
		["brazier_idle_2", 28, 4, 6.0, true],
		["brazier_fire_2", 29, 4, 12.0, false],
		["brazier_idle_3", 30, 4, 6.0, true],
		["brazier_fire_3", 31, 4, 12.0, false],
		["ballista_idle", 32, 4, 5.0, true],
		["ballista_fire", 33, 4, 12.0, false],
		["ballista_build", 34, 6, 10.0, false],
		["ballista_sell", 35, 6, 10.0, false],
		["ballista_idle_2", 36, 4, 5.0, true],
		["ballista_fire_2", 37, 4, 12.0, false],
		["ballista_idle_3", 38, 4, 5.0, true],
		["ballista_fire_3", 39, 4, 12.0, false],
		# Evolutions (level 4, evolution_art.gd): idle and fire, named by the evolution's id.
		["sniper_nest_idle", 40, 4, 5.0, true],
		["sniper_nest_fire", 41, 4, 12.0, false],
		["volley_tower_idle", 42, 4, 5.0, true],
		["volley_tower_fire", 43, 4, 12.0, false],
		["siege_mortar_idle", 44, 4, 5.0, true],
		["siege_mortar_fire", 45, 4, 12.0, false],
		["grapeshot_battery_idle", 46, 4, 5.0, true],
		["grapeshot_battery_fire", 47, 4, 12.0, false],
		["glacier_spire_idle", 48, 4, 6.0, true],
		["glacier_spire_fire", 49, 4, 12.0, false],
		["shatter_shrine_idle", 50, 4, 6.0, true],
		["shatter_shrine_fire", 51, 4, 12.0, false],
		["pyre_of_souls_idle", 52, 4, 8.0, true],
		["pyre_of_souls_fire", 53, 4, 12.0, false],
		["beacon_flame_idle", 54, 4, 8.0, true],
		["beacon_flame_fire", 55, 4, 12.0, false],
		["harpoon_idle", 56, 4, 5.0, true],
		["harpoon_fire", 57, 4, 12.0, false],
		["repeater_idle", 58, 4, 5.0, true],
		["repeater_fire", 59, 4, 12.0, false],
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
		["cannonball", 8, 2, 10.0, true],
		["frost_bolt", 9, 4, 12.0, true],
		["cannonball_heavy", 10, 2, 10.0, true],
		["fire_glob", 11, 2, 12.0, true],
		["bolt_0", 12, 1, 1.0, false],
		["bolt_1", 13, 1, 1.0, false],
		["bolt_2", 14, 1, 1.0, false],
		["bolt_3", 15, 1, 1.0, false],
		["bolt_4", 16, 1, 1.0, false],
		["bolt_5", 17, 1, 1.0, false],
		["bolt_6", 18, 1, 1.0, false],
		["bolt_7", 19, 1, 1.0, false],
		# Evolution shots (evolution_art.gd).
		["sniper_shot_0", 20, 1, 1.0, false],
		["sniper_shot_1", 21, 1, 1.0, false],
		["sniper_shot_2", 22, 1, 1.0, false],
		["sniper_shot_3", 23, 1, 1.0, false],
		["sniper_shot_4", 24, 1, 1.0, false],
		["sniper_shot_5", 25, 1, 1.0, false],
		["sniper_shot_6", 26, 1, 1.0, false],
		["sniper_shot_7", 27, 1, 1.0, false],
		["harpoon_0", 28, 1, 1.0, false],
		["harpoon_1", 29, 1, 1.0, false],
		["harpoon_2", 30, 1, 1.0, false],
		["harpoon_3", 31, 1, 1.0, false],
		["harpoon_4", 32, 1, 1.0, false],
		["harpoon_5", 33, 1, 1.0, false],
		["harpoon_6", 34, 1, 1.0, false],
		["harpoon_7", 35, 1, 1.0, false],
		["mortar_shell", 36, 2, 10.0, true],
	],
}

const EXPLOSION: Dictionary = {
	"png": "res://assets/sprites/effects/explosion.png",
	"frames": "res://entities/effects/explosion_frames.tres",
	"size": Vector2i(56, 56),
	"anims": [["explosion", 0, 7, 16.0, false]],
}

## The big shells' blast (cannon level 3): 72x72 art = a 144 px blast.
const EXPLOSION_LARGE: Dictionary = {
	"png": "res://assets/sprites/effects/explosion_large.png",
	"frames": "res://entities/effects/explosion_large_frames.tres",
	"size": Vector2i(72, 72),
	"anims": [["explosion_large", 0, 7, 16.0, false]],
}

## The frost nova (frost level 3): 48x48 art = a 96 px ring.
const FROST_NOVA: Dictionary = {
	"png": "res://assets/sprites/effects/frost_nova.png",
	"frames": "res://entities/effects/frost_nova_frames.tres",
	"size": Vector2i(48, 48),
	"anims": [["frost_nova", 0, 6, 16.0, false]],
}

## Burning ground (looping): hellfire shells and the brazier's fire.
const BURN: Dictionary = {
	"png": "res://assets/sprites/effects/burn.png",
	"frames": "res://entities/effects/burn_frames.tres",
	"size": Vector2i(48, 32),
	"anims": [["burn", 0, 4, 10.0, true], ["soul_burn", 1, 4, 10.0, true]],
}

## Evolution effects (evolution_art.gd). The soul burst (Pyre of Souls): 56x56 art.
const SOUL_BURST: Dictionary = {
	"png": "res://assets/sprites/effects/soul_burst.png",
	"frames": "res://entities/effects/soul_burst_frames.tres",
	"size": Vector2i(56, 56),
	"anims": [["soul_burst", 0, 7, 16.0, false]],
}

## Arrow rain (Volley Tower): 64x64 art = a 128 px shower.
const EVOLUTION_FX: Dictionary = {
	"png": "res://assets/sprites/effects/evolution_fx.png",
	"frames": "res://entities/effects/evolution_fx_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [["arrow_rain", 0, 5, 16.0, false]],
}

## The grapeshot blast (Grapeshot Battery) in 8 directions (grapeshot_0 right, then clockwise).
const GRAPESHOT: Dictionary = {
	"png": "res://assets/sprites/effects/grapeshot.png",
	"frames": "res://entities/effects/grapeshot_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [["grapeshot_0", 0, 4, 18.0, false], ["grapeshot_1", 1, 4, 18.0, false], ["grapeshot_2", 2, 4, 18.0, false],
		["grapeshot_3", 3, 4, 18.0, false], ["grapeshot_4", 4, 4, 18.0, false], ["grapeshot_5", 5, 4, 18.0, false],
		["grapeshot_6", 6, 4, 18.0, false], ["grapeshot_7", 7, 4, 18.0, false]],
}

## Status marks: an enemy frozen solid, a vulnerable enemy's cracked rune, a boosted tower's ember.
const STATUS: Dictionary = {
	"png": "res://assets/sprites/effects/status.png",
	"frames": "res://entities/effects/status_frames.tres",
	"size": Vector2i(24, 28),
	"anims": [["frozen", 0, 2, 3.0, true], ["shattered", 1, 4, 8.0, true], ["beacon_ember", 2, 4, 8.0, true],
		["silenced", 3, 4, 6.0, true]],
}

const FROST_FX: Dictionary = {
	"png": "res://assets/sprites/effects/frost.png",
	"frames": "res://entities/effects/frost_frames.tres",
	"size": Vector2i(20, 20),
	"anims": [["frost_burst", 0, 5, 16.0, false], ["frost_aura", 1, 4, 6.0, true]],
}

## Chapter 2's enemies (M7.5). The Bloater (40x40: swollen, pulsing gas sacs; its death bursts) and
## its Bloatlings (24x24, the same creature drawn small); the Mire Priest (its heal: 0-3 the staff
## rises, the telegraph; 4-5 the pulse); the Shieldbearer (its shield always toward where it walks).
const BLOATER: Dictionary = {
	"png": "res://assets/sprites/enemies/bloater.png",
	"frames": "res://entities/enemies/bloater_frames.tres",
	"size": Vector2i(40, 40),
	"anims": [
		["idle_down", 0, 4, 6.0, true],
		["idle_up", 1, 4, 6.0, true],
		["idle_side", 2, 4, 6.0, true],
		["walk_down", 3, 6, 7.0, true],
		["walk_up", 4, 6, 7.0, true],
		["walk_side", 5, 6, 7.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 6, 10.0, false],
		["attack_up", 8, 6, 10.0, false],
		["attack_side", 9, 6, 10.0, false],
	],
}

const BLOATLING: Dictionary = {
	"png": "res://assets/sprites/enemies/bloatling.png",
	"frames": "res://entities/enemies/bloatling_frames.tres",
	"size": Vector2i(24, 24),
	"anims": [
		["idle_down", 0, 4, 6.0, true],
		["idle_up", 1, 4, 6.0, true],
		["idle_side", 2, 4, 6.0, true],
		["walk_down", 3, 6, 14.0, true],
		["walk_up", 4, 6, 14.0, true],
		["walk_side", 5, 6, 14.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 6, 18.0, false],
		["attack_up", 8, 6, 18.0, false],
		["attack_side", 9, 6, 18.0, false],
	],
}

const MIRE_PRIEST: Dictionary = {
	"png": "res://assets/sprites/enemies/mire_priest.png",
	"frames": "res://entities/enemies/mire_priest_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [
		["idle_down", 0, 4, 6.0, true],
		["idle_up", 1, 4, 6.0, true],
		["idle_side", 2, 4, 6.0, true],
		["walk_down", 3, 6, 8.0, true],
		["walk_up", 4, 6, 8.0, true],
		["walk_side", 5, 6, 8.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 6, 12.0, false],
		["attack_up", 8, 6, 12.0, false],
		["attack_side", 9, 6, 12.0, false],
		["heal_down", 10, 6, 6.0, false],
		["heal_up", 11, 6, 6.0, false],
		["heal_side", 12, 6, 6.0, false],
	],
}

const SHIELDBEARER: Dictionary = {
	"png": "res://assets/sprites/enemies/shieldbearer.png",
	"frames": "res://entities/enemies/shieldbearer_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [
		["idle_down", 0, 4, 6.0, true],
		["idle_up", 1, 4, 6.0, true],
		["idle_side", 2, 4, 6.0, true],
		["walk_down", 3, 6, 9.0, true],
		["walk_up", 4, 6, 9.0, true],
		["walk_side", 5, 6, 9.0, true],
		["death", 6, 7, 12.0, false],
		["attack_down", 7, 6, 12.0, false],
		["attack_up", 8, 6, 12.0, false],
		["attack_side", 9, 6, 12.0, false],
	],
}

## Rings around the hero wading in marsh water (marsh_art.gd), 32x16 art, looping.
const RIPPLE: Dictionary = {
	"png": "res://assets/sprites/effects/ripple.png",
	"frames": "res://entities/effects/ripple_frames.tres",
	"size": Vector2i(32, 16),
	"anims": [["ripple", 0, 4, 6.0, true]],
}

## All sheets that become SpriteFrames.
const ANIMATED: Array[Dictionary] = [BLOATER, BLOATLING, MIRE_PRIEST, SHIELDBEARER, RIPPLE, HERO, SWING, SWING_LONG, GHOUL, HOUND, BRUTE, CULTIST, CULTIST_FX, GRAVELORD, COLOSSUS, LICH, TOLLKEEPER, HIT_SPARK, DUST, TOWERS, PROJECTILES, EXPLOSION, EXPLOSION_LARGE, FROST_NOVA, BURN, FROST_FX, FORTRESS_FX, SOUL_BURST, EVOLUTION_FX, GRAPESHOT, STATUS]

## Build slot pad for a Sprite2D (hframes 2): normal, highlighted (the hero is close).
const BUILD_SLOT: Dictionary = {
	"png": "res://assets/sprites/towers/build_slot.png",
	"size": Vector2i(28, 20),
}

## Single-row sheet used directly by a Sprite2D (hframes): healthy, damaged, badly damaged, destroyed.
## 3/4 view: the 48x48 footprint (= the 96 px collision box) is the lower part of each 96x96 frame
## (art rect 24,40 - 72,88); walls, towers and roofs rise above it.
const FORTRESS: Dictionary = {
	"png": "res://assets/sprites/fortress/fortress.png",
	"size": Vector2i(96, 96),
	"frames_count": 4,
}

## Animated pieces placed on the fortress: waving banners, fires (damage) and wall braziers.
const FORTRESS_FX: Dictionary = {
	"png": "res://assets/sprites/fortress/fortress_fx.png",
	"frames": "res://entities/fortress/fortress_fx_frames.tres",
	"size": Vector2i(16, 24),
	"anims": [
		["banner", 0, 4, 6.0, true],
		["banner_torn", 1, 4, 6.0, true],
		["fire", 2, 6, 12.0, true],
		["brazier", 3, 4, 10.0, true],
	],
}

## Environment props (Sprite2D, hframes 12; see EnvironmentArt.PROPS for the order). 32x48 frames
## standing on art row 44: the level places them with offset (0, -20) so the node sits on the base.
const PROPS_PNG: String = "res://assets/sprites/environment/props.png"
const PROPS_COUNT: int = 12
## The graveyard crypt (64x64, standing on art row 60).
const CRYPT_PNG: String = "res://assets/sprites/environment/crypt.png"
## Ambient particle mote (fireflies, drifting ash).
const MOTE_PNG: String = "res://assets/sprites/effects/mote.png"

## Particle texture for smoke (fortress fires).
const SMOKE_PNG: String = "res://assets/sprites/effects/smoke_puff.png"

## UI textures are saved pre-scaled to 2x (StyleBoxTexture/TextureRect draw texels 1:1).
const COIN_PNG: String = "res://assets/sprites/ui/coin.png"
const UI_DIR: String = "res://assets/sprites/ui/"
## Relic icons, one PNG per relic id (32x32, pre-scaled 2x), and the Ossuary Bell's bone pickup.
const RELIC_ICON_DIR: String = "res://assets/sprites/ui/relics/"
const BONE_PNG: String = "res://assets/sprites/effects/bone_pickup.png"
## Run upgrade icons, one PNG per upgrade id (32x32, pre-scaled 2x).
const UPGRADE_ICON_DIR: String = "res://assets/sprites/ui/upgrades/"
## The pixel font (bitmap FontFile, 12 px cell incl. outline; the theme draws it at 24 = 2x).
const FONT: String = "res://assets/fonts/pixel_font.res"
const FONT_ATLAS_PNG: String = "res://assets/fonts/pixel_font_atlas.png"

const GROUND_PNG: String = "res://assets/sprites/environment/prototype_arena_ground.png"
## The Drowned Marsh (chapter 2): its baked ground, props (Sprite2D, hframes 8; MarshArt.PROPS) and the
## drowned chapel the dead come out of (64x64, standing on art row 60).
const MARSH_LEVEL: String = "res://levels/drowned_marsh.tscn"
const MARSH_GROUND_PNG: String = "res://assets/sprites/environment/drowned_marsh_ground.png"
const MARSH_PROPS_PNG: String = "res://assets/sprites/environment/marsh_props.png"
const CHAPEL_PNG: String = "res://assets/sprites/environment/drowned_chapel.png"
## Width of the visible stone wall band drawn outside the playable floor, in world pixels.
const WALL_BAND: int = 32

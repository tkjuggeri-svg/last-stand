extends RefCounted
## Spritesheet layouts shared by generate_art.gd (which draws the sheets) and
## build_sprite_frames.gd (which slices them into SpriteFrames).
## Animations are [name, row, frame_count, fps, loop]. Sizes are in the sheet's own pixels. The world
## sprites are hand-drawn at double resolution (docs/ART_HANDOFF.md): one sheet pixel = 1 world pixel,
## sprite nodes at scale 1. The code-drawn art still in use (the grounds, a few small effects) keeps
## one art pixel = 2 world pixels (ART_SCALE). World sprites drawn in code at the double resolution
## (Canvas detail FINE) are art-pixel drawings rasterised twice as fine, so they match the hand-drawn ones.

const ART_SCALE: int = 2
const FINE: int = 2

## Vector sheets (M15, docs/M15_VECTOR.md): baked by tools/art/vector/bake_sheets.gd at VECTOR_SCALE sheet pixels per
## world pixel ("scale"; SheetSprite draws them at 1 / scale). "size" is in sheet pixels; "origin" is where the
## painter's (0, 0), the feet, sits from the frame's centre in world pixels (the sprite node's offset, negated).
const VECTOR_SCALE: int = 2

## The Knight (vector, KnightPainter). About twice the old frames at the same durations (M15 Q7).
const HERO: Dictionary = {
	"png": "res://assets/sprites/hero/hero.png",
	"frames": "res://entities/hero/hero_frames.tres",
	"vector": "knight",
	"scale": VECTOR_SCALE,
	"size": Vector2i(112, 128) * VECTOR_SCALE,
	"origin": Vector2(0, 16),
	"anims": [
		["idle_down", 0, 8, 10.0, true],
		["idle_up", 1, 8, 10.0, true],
		["idle_side", 2, 8, 10.0, true],
		["walk_down", 3, 12, 22.0, true],
		["walk_up", 4, 12, 22.0, true],
		["walk_side", 5, 12, 22.0, true],
		["attack_down", 6, 8, 40.0, false],
		["attack_up", 7, 8, 40.0, false],
		["attack_side", 8, 8, 40.0, false],
		["death", 9, 12, 16.0, false],
		["dash_down", 10, 4, 20.0, true],
		["dash_up", 11, 4, 20.0, true],
		["dash_side", 12, 4, 20.0, true],
	],
}

## The Knight's old 13 animation rows, which the Huntress and Necromancer sheets (pixel, 64x80) still use.
const HERO_PIXEL_ANIMS: Array = [
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
	["dash_down", 10, 3, 20.0, true],
	["dash_up", 11, 3, 20.0, true],
	["dash_side", 12, 3, 20.0, true],
]

## The Huntress (M9): the Knight's animation rows with her own sheet (64x80 frames, the Knight's code-drawn size).
const HUNTRESS: Dictionary = {
	"png": "res://assets/sprites/hero/huntress.png",
	"frames": "res://entities/hero/huntress_frames.tres",
	"size": Vector2i(64, 80),
	"anims": HERO_PIXEL_ANIMS,
}

## Enemy variants (M10, variant_art.gd): the base enemy's sheet layout, their own sheets.
const SIEGE_RAM: Dictionary = {
	"png": "res://assets/sprites/enemies/siege_ram.png",
	"frames": "res://entities/enemies/siege_ram_frames.tres",
	"size": BRUTE_PIXEL["size"] + Vector2i(24, 8),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": BRUTE_PIXEL["anims"],
}
const BLACK_KNIGHT: Dictionary = {
	"png": "res://assets/sprites/enemies/black_knight.png",
	"frames": "res://entities/enemies/black_knight_frames.tres",
	"size": SHIELDBEARER["size"] + Vector2i(16, 24),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": SHIELDBEARER["anims"],
}
const FALLEN_MARSHAL: Dictionary = {
	"png": "res://assets/sprites/enemies/fallen_marshal.png",
	"frames": "res://entities/enemies/bosses/fallen_marshal_frames.tres",
	"size": COLOSSUS["size"] + Vector2i(24, 24),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": COLOSSUS["anims"],
}

const CINDER_GHOUL: Dictionary = {
	"png": "res://assets/sprites/enemies/cinder_ghoul.png",
	"frames": "res://entities/enemies/cinder_ghoul_frames.tres",
	"size": GHOUL_PIXEL["size"] + Vector2i(12, 12),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": GHOUL_PIXEL["anims"],
}

const SCARECROW: Dictionary = {
	"png": "res://assets/sprites/enemies/scarecrow.png",
	"frames": "res://entities/enemies/scarecrow_frames.tres",
	"size": BRUTE_PIXEL["size"],
	"anims": BRUTE_PIXEL["anims"],
}

const PYRE_WARDEN: Dictionary = {
	"png": "res://assets/sprites/enemies/pyre_warden.png",
	"frames": "res://entities/enemies/bosses/pyre_warden_frames.tres",
	"size": LICH["size"] + Vector2i(16, 28),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": LICH["anims"],
}

const FROST_WRAITH: Dictionary = {
	"png": "res://assets/sprites/enemies/frost_wraith.png",
	"frames": "res://entities/enemies/frost_wraith_frames.tres",
	"size": CULTIST_PIXEL["size"] + Vector2i(12, 12),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": CULTIST_PIXEL["anims"],
}

const RIME_BRUTE: Dictionary = {
	"png": "res://assets/sprites/enemies/rime_brute.png",
	"frames": "res://entities/enemies/rime_brute_frames.tres",
	"size": BRUTE_PIXEL["size"] + Vector2i(16, 12),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": BRUTE_PIXEL["anims"],
}

const WINTER_WARDEN: Dictionary = {
	"png": "res://assets/sprites/enemies/winter_warden.png",
	"frames": "res://entities/enemies/bosses/winter_warden_frames.tres",
	"size": LICH["size"] + Vector2i(12, 24),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": LICH["anims"],
}

const BURROWER: Dictionary = {
	"png": "res://assets/sprites/enemies/burrower.png",
	"frames": "res://entities/enemies/burrower_frames.tres",
	"size": HOUND_PIXEL["size"],
	"anims": HOUND_PIXEL["anims"],
}

const LAMP_WIGHT: Dictionary = {
	"png": "res://assets/sprites/enemies/lamp_wight.png",
	"frames": "res://entities/enemies/lamp_wight_frames.tres",
	"size": MIRE_PRIEST["size"] + Vector2i(24, 12),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": MIRE_PRIEST["anims"],
}

const DEEP_WARDEN: Dictionary = {
	"png": "res://assets/sprites/enemies/deep_warden.png",
	"frames": "res://entities/enemies/bosses/deep_warden_frames.tres",
	"size": TOLLKEEPER["size"] + Vector2i(12, 12),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": TOLLKEEPER["anims"],
}

const BONE_HURLER: Dictionary = {
	"png": "res://assets/sprites/enemies/bone_hurler.png",
	"frames": "res://entities/enemies/bone_hurler_frames.tres",
	"size": CULTIST_PIXEL["size"] + Vector2i(12, 8),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": CULTIST_PIXEL["anims"],
}

const RUBBLE_BRUTE: Dictionary = {
	"png": "res://assets/sprites/enemies/rubble_brute.png",
	"frames": "res://entities/enemies/rubble_brute_frames.tres",
	"size": BRUTE_PIXEL["size"],
	"anims": BRUTE_PIXEL["anims"],
}

const QUARRY_COLOSSUS: Dictionary = {
	"png": "res://assets/sprites/enemies/quarry_colossus.png",
	"frames": "res://entities/enemies/bosses/quarry_colossus_frames.tres",
	"size": COLOSSUS["size"] + Vector2i(16, 12),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": COLOSSUS["anims"],
}

const STALKER: Dictionary = {
	"png": "res://assets/sprites/enemies/stalker.png",
	"frames": "res://entities/enemies/stalker_frames.tres",
	"size": HOUND_PIXEL["size"] + Vector2i(16, 8),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": HOUND_PIXEL["anims"],
}

const HOLLOW_TREANT: Dictionary = {
	"png": "res://assets/sprites/enemies/hollow_treant.png",
	"frames": "res://entities/enemies/hollow_treant_frames.tres",
	"size": BRUTE_PIXEL["size"] + Vector2i(24, 24),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": BRUTE_PIXEL["anims"],
}

const HOLLOW_STAG: Dictionary = {
	"png": "res://assets/sprites/enemies/hollow_stag.png",
	"frames": "res://entities/enemies/bosses/hollow_stag_frames.tres",
	"size": GRAVELORD["size"] + Vector2i(24, 48),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": GRAVELORD["anims"],
}

const CHORISTER: Dictionary = {
	"png": "res://assets/sprites/enemies/chorister.png",
	"frames": "res://entities/enemies/chorister_frames.tres",
	"size": MIRE_PRIEST["size"] + Vector2i(16, 32),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": MIRE_PRIEST["anims"],
}

const INQUISITOR: Dictionary = {
	"png": "res://assets/sprites/enemies/inquisitor.png",
	"frames": "res://entities/enemies/inquisitor_frames.tres",
	"size": SHIELDBEARER["size"] + Vector2i(12, 24),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": SHIELDBEARER["anims"],
}

const PALE_BISHOP: Dictionary = {
	"png": "res://assets/sprites/enemies/pale_bishop.png",
	"frames": "res://entities/enemies/bosses/pale_bishop_frames.tres",
	"size": LICH["size"] + Vector2i(24, 48),  # + the art pass's padding (variant_decor.gd PADS)
	"anims": LICH["anims"],
}

## The Necromancer (M9): the Knight's layout again.
const NECROMANCER: Dictionary = {
	"png": "res://assets/sprites/hero/necromancer.png",
	"frames": "res://entities/hero/necromancer_frames.tres",
	"size": Vector2i(64, 80),
	"anims": HERO_PIXEL_ANIMS,
}

## The skeleton minion, side view facing right (the game mirrors it), 32x32 art.
const SKELETON: Dictionary = {
	"png": "res://assets/sprites/minions/skeleton.png",
	"frames": "res://entities/minions/skeleton_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [
		["idle", 0, 4, 5.0, true],
		["walk", 1, 6, 10.0, true],
		["attack", 2, 4, 16.0, false],
		["death", 3, 5, 8.0, false],
	],
}

## The Necromancer's soul bolt in 8 directions (soul_bolt_0 flies right, then every 45 degrees clockwise).
const SOUL_BOLT: Dictionary = {
	"png": "res://assets/sprites/hero/soul_bolt.png",
	"frames": "res://entities/hero/soul_bolt_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [
		["soul_bolt_0", 0, 2, 12.0, true], ["soul_bolt_1", 1, 2, 12.0, true], ["soul_bolt_2", 2, 2, 12.0, true], ["soul_bolt_3", 3, 2, 12.0, true],
		["soul_bolt_4", 4, 2, 12.0, true], ["soul_bolt_5", 5, 2, 12.0, true], ["soul_bolt_6", 6, 2, 12.0, true], ["soul_bolt_7", 7, 2, 12.0, true],
	],
}

## Sword swing trail in 8 directions: swing_0 points right, then every 45 degrees clockwise.
## The hero's sword swing (vector, EffectsPainter; M15): one crescent per 45 degrees, 8 frames at 48 fps (the old 4 at 24).
## The reach tiers of Long Reach scale it at runtime (SheetSprite.extra_scale) instead of having sheets of their own. The
## cell is 192x192 world px centred on the hero's origin.
const SWING: Dictionary = {
	"png": "res://assets/sprites/effects/swing.png",
	"frames": "res://entities/hero/swing_frames.tres",
	"vector": "effects",
	"scale": VECTOR_SCALE,
	"size": Vector2i(192, 192) * VECTOR_SCALE,
	"anims": [
		["swing_0", 0, 8, 48.0, false],
		["swing_1", 1, 8, 48.0, false],
		["swing_2", 2, 8, 48.0, false],
		["swing_3", 3, 8, 48.0, false],
		["swing_4", 4, 8, 48.0, false],
		["swing_5", 5, 8, 48.0, false],
		["swing_6", 6, 8, 48.0, false],
		["swing_7", 7, 8, 48.0, false],
	],
}

## Long Reach swing trails ("swing_<direction>_<tier>", tier 1-4 = reach x1.15 .. x1.6), 128x128.

const GHOUL_PIXEL: Dictionary = {
	"size": Vector2i(64, 64),
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

## The Ghoul (vector, GhoulPainter; M15). Twice the old frames at the same durations: idle 0.8 s, walk 0.75 s, attack
## 0.5 s (the strike lands at 0.36 s, the data's 0.35 s wind-up), death 0.6 s. The cell is 80x80 world px with the feet
## 23 px below its centre (the old sprite's 25).
const GHOUL: Dictionary = {
	"png": "res://assets/sprites/enemies/ghoul.png",
	"frames": "res://entities/enemies/ghoul_frames.tres",
	"vector": "ghoul",
	"scale": VECTOR_SCALE,
	"size": Vector2i(80, 80) * VECTOR_SCALE,
	"origin": Vector2(0, 23),
	"anims": [
		["idle_down", 0, 8, 10.0, true],
		["idle_up", 1, 8, 10.0, true],
		["idle_side", 2, 8, 10.0, true],
		["walk_down", 3, 12, 16.0, true],
		["walk_up", 4, 12, 16.0, true],
		["walk_side", 5, 12, 16.0, true],
		["death", 6, 12, 20.0, false],
		["attack_down", 7, 12, 24.0, false],
		["attack_up", 8, 12, 24.0, false],
		["attack_side", 9, 12, 24.0, false],
	],
}

## The Grave Hound: same rows as the Ghoul; "walk" is a fast gallop. Attack: 4 wind-up frames at
## 16 fps = the data's 0.25 s, then the bite.
const HOUND_PIXEL: Dictionary = {
	"size": Vector2i(64, 64),
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
## The Grave Hound (vector, HoundPainter; M15): twice the old frames at the same durations (idle 0.67 s, gallop 0.43 s,
## attack 0.375 s with the bite at 0.22 s against the data's 0.25 s wind-up, death 0.6 s).
const HOUND: Dictionary = {
	"png": "res://assets/sprites/enemies/hound.png",
	"frames": "res://entities/enemies/hound_frames.tres",
	"vector": "hound",
	"scale": VECTOR_SCALE,
	"size": Vector2i(72, 64) * VECTOR_SCALE,
	"origin": Vector2(0, 22),
	"anims": [
		["idle_down", 0, 8, 12.0, true],
		["idle_up", 1, 8, 12.0, true],
		["idle_side", 2, 8, 12.0, true],
		["walk_down", 3, 12, 28.0, true],
		["walk_up", 4, 12, 28.0, true],
		["walk_side", 5, 12, 28.0, true],
		["death", 6, 12, 20.0, false],
		["attack_down", 7, 12, 32.0, false],
		["attack_up", 8, 12, 32.0, false],
		["attack_side", 9, 12, 32.0, false],
	],
}

## The Brute: 48x48 frames (feet on art row 44). A slow, heavy walk; attack: 6 wind-up frames at
## 10 fps = the data's 0.6 s, then the slam and a recover frame.
const BRUTE_PIXEL: Dictionary = {
	"size": Vector2i(96, 96),
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
## The Brute (vector, BrutePainter; M15): idle 1.0 s, walk 1.0 s, attack 0.8 s (the slam lands at 0.6 s, the data's wind-up),
## death 0.7 s. A 112x112 cell with the feet 38 px below its centre (the raised fists reach the top).
const BRUTE: Dictionary = {
	"png": "res://assets/sprites/enemies/brute.png",
	"frames": "res://entities/enemies/brute_frames.tres",
	"vector": "brute",
	"scale": VECTOR_SCALE,
	"size": Vector2i(112, 112) * VECTOR_SCALE,
	"origin": Vector2(0, 38),
	"anims": [
		["idle_down", 0, 8, 8.0, true],
		["idle_up", 1, 8, 8.0, true],
		["idle_side", 2, 8, 8.0, true],
		["walk_down", 3, 12, 12.0, true],
		["walk_up", 4, 12, 12.0, true],
		["walk_side", 5, 12, 12.0, true],
		["death", 6, 14, 20.0, false],
		["attack_down", 7, 16, 20.0, false],
		["attack_up", 8, 16, 20.0, false],
		["attack_side", 9, 16, 20.0, false],
	],
}

## The Cultist: same rows as the Ghoul; the walk is a glide. Attack: 6 wind-up frames at 12 fps
## = the data's 0.5 s (the witchfire swells overhead), then the release and a recover frame.
const CULTIST_PIXEL: Dictionary = {
	"size": Vector2i(64, 64),
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
## The Cultist (vector, CultistPainter; M15): idle 0.67 s, walk 0.75 s, attack 0.67 s (the orb is thrown at 0.5 s, the
## data's wind-up), death 0.6 s.
const CULTIST: Dictionary = {
	"png": "res://assets/sprites/enemies/cultist.png",
	"frames": "res://entities/enemies/cultist_frames.tres",
	"vector": "cultist",
	"scale": VECTOR_SCALE,
	"size": Vector2i(64, 64) * VECTOR_SCALE,
	"origin": Vector2(0, 25),
	"anims": [
		["idle_down", 0, 8, 12.0, true],
		["idle_up", 1, 8, 12.0, true],
		["idle_side", 2, 8, 12.0, true],
		["walk_down", 3, 12, 16.0, true],
		["walk_up", 4, 12, 16.0, true],
		["walk_side", 5, 12, 16.0, true],
		["death", 6, 12, 20.0, false],
		["attack_down", 7, 16, 24.0, false],
		["attack_up", 8, 16, 24.0, false],
		["attack_side", 9, 16, 24.0, false],
	],
}

## The Cultist's witchfire bolt (flying, looped) and its burst.
const CULTIST_FX: Dictionary = {
	"png": "res://assets/sprites/enemies/cultist_fx.png",
	"frames": "res://entities/enemies/cultist_fx_frames.tres",
	"size": Vector2i(32, 32),
	"anims": [["bolt", 0, 2, 10.0, true], ["burst", 1, 4, 18.0, false]],
}

## Bosses: 64x64 frames (feet on art row 58, boss_art_kit.gd). Attack: 6 wind-up frames at 10 fps =
## the data's 0.6 s, then the blow. Abilities: "cast" is 6 frames at 5 fps = the 1.2 s telegraph.
## The Gravelord (wave 5): raises the dead.
const GRAVELORD: Dictionary = {
	"png": "res://assets/sprites/enemies/gravelord.png",
	"frames": "res://entities/enemies/bosses/gravelord_frames.tres",
	"size": Vector2i(128, 128),
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
	"size": Vector2i(128, 128),
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
	"size": Vector2i(128, 128),
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
	"size": Vector2i(128, 128),
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

## The hit spark (vector, EffectsPainter; M15): 8 frames at 48 fps (the old 4 at 24), a 48x48 world cell.
const HIT_SPARK: Dictionary = {
	"png": "res://assets/sprites/effects/hit_spark.png",
	"frames": "res://entities/effects/hit_spark_frames.tres",
	"vector": "effects",
	"scale": VECTOR_SCALE,
	"size": Vector2i(48, 48) * VECTOR_SCALE,
	"anims": [["spark", 0, 8, 48.0, false]],
}

## The dust puff (vector, EffectsPainter; M15): 12 frames at 28 fps (the old 6 at 14), a 64x64 world cell.
const DUST: Dictionary = {
	"png": "res://assets/sprites/effects/dust.png",
	"frames": "res://entities/effects/dust_frames.tres",
	"vector": "effects",
	"scale": VECTOR_SCALE,
	"size": Vector2i(64, 64) * VECTOR_SCALE,
	"anims": [["dust", 0, 12, 28.0, false]],
}

## The three towers (32x48 art = 64x96 world px; the base rests on art row 45, the sprite is placed so
## that is +4 world px below the slot centre). Per tower: idle, fire, build (rising in scaffolding)
## and sell (dismantled into rubble, played by the TowerDismantle effect); levels 2 and 3 add their
## own idle and fire ("<id>_idle_2", ...).
## The five base towers (vector; TowerPainter; M15): three levels with idle and fire, plus build and sell. Twice the old
## frames at the same durations. The cell is 96x120 world px, the feet 56 px below its centre. The evolutions (level 4)
## are in TOWER_EVOLUTIONS (pixel art until M15 phase P6).
const TOWERS: Dictionary = {
	"png": "res://assets/sprites/towers/towers.png",
	"frames": "res://entities/towers/tower_frames.tres",
	"vector": "tower",
	"scale": VECTOR_SCALE,
	"size": Vector2i(96, 120) * VECTOR_SCALE,
	"origin": Vector2(0, 56),
	"anims": [
		["archer_idle", 0, 8, 10.0, true],
		["archer_fire", 1, 8, 24.0, false],
		["archer_build", 2, 12, 20.0, false],
		["archer_sell", 3, 12, 20.0, false],
		["cannon_idle", 4, 8, 10.0, true],
		["cannon_fire", 5, 10, 24.0, false],
		["cannon_build", 6, 12, 20.0, false],
		["cannon_sell", 7, 12, 20.0, false],
		["frost_idle", 8, 8, 12.0, true],
		["frost_fire", 9, 8, 24.0, false],
		["frost_build", 10, 12, 20.0, false],
		["frost_sell", 11, 12, 20.0, false],
		["archer_idle_2", 12, 8, 10.0, true],
		["archer_fire_2", 13, 8, 24.0, false],
		["archer_idle_3", 14, 8, 10.0, true],
		["archer_fire_3", 15, 8, 24.0, false],
		["cannon_idle_2", 16, 8, 10.0, true],
		["cannon_fire_2", 17, 10, 24.0, false],
		["cannon_idle_3", 18, 8, 10.0, true],
		["cannon_fire_3", 19, 10, 24.0, false],
		["frost_idle_2", 20, 8, 12.0, true],
		["frost_fire_2", 21, 8, 24.0, false],
		["frost_idle_3", 22, 8, 12.0, true],
		["frost_fire_3", 23, 8, 24.0, false],
		["brazier_idle", 24, 8, 12.0, true],
		["brazier_fire", 25, 8, 24.0, false],
		["brazier_build", 26, 12, 20.0, false],
		["brazier_sell", 27, 12, 20.0, false],
		["brazier_idle_2", 28, 8, 12.0, true],
		["brazier_fire_2", 29, 8, 24.0, false],
		["brazier_idle_3", 30, 8, 12.0, true],
		["brazier_fire_3", 31, 8, 24.0, false],
		["ballista_idle", 32, 8, 10.0, true],
		["ballista_fire", 33, 8, 24.0, false],
		["ballista_build", 34, 12, 20.0, false],
		["ballista_sell", 35, 12, 20.0, false],
		["ballista_idle_2", 36, 8, 10.0, true],
		["ballista_fire_2", 37, 8, 24.0, false],
		["ballista_idle_3", 38, 8, 10.0, true],
		["ballista_fire_3", 39, 8, 24.0, false],
	],
}

## The ten evolutions' idle and fire (level 4), still pixel art (cut from the old tower sheet; redrawn in M15 phase P6).
const TOWER_EVOLUTIONS: Dictionary = {
	"png": "res://assets/sprites/towers/tower_evolutions.png",
	"frames": "res://entities/towers/tower_evolution_frames.tres",
	"size": Vector2i(64, 96),
	"anims": [
		["sniper_nest_idle", 0, 4, 5.0, true],
		["sniper_nest_fire", 1, 4, 12.0, false],
		["volley_tower_idle", 2, 4, 5.0, true],
		["volley_tower_fire", 3, 4, 12.0, false],
		["siege_mortar_idle", 4, 4, 5.0, true],
		["siege_mortar_fire", 5, 4, 12.0, false],
		["grapeshot_battery_idle", 6, 4, 5.0, true],
		["grapeshot_battery_fire", 7, 4, 12.0, false],
		["glacier_spire_idle", 8, 4, 6.0, true],
		["glacier_spire_fire", 9, 4, 12.0, false],
		["shatter_shrine_idle", 10, 4, 6.0, true],
		["shatter_shrine_fire", 11, 4, 12.0, false],
		["pyre_of_souls_idle", 12, 4, 8.0, true],
		["pyre_of_souls_fire", 13, 4, 12.0, false],
		["beacon_flame_idle", 14, 4, 8.0, true],
		["beacon_flame_fire", 15, 4, 12.0, false],
		["harpoon_idle", 16, 4, 5.0, true],
		["harpoon_fire", 17, 4, 12.0, false],
		["repeater_idle", 18, 4, 5.0, true],
		["repeater_fire", 19, 4, 12.0, false],
	],
}

## Arrows in 8 directions (arrow_0 points right, then every 45 degrees clockwise), cannonball, frost bolt.
## The towers' shots (vector, EffectsPainter; M15): pre-drawn in 8 directions, a 40x40 world cell; the spinning ones have more frames.
const PROJECTILES: Dictionary = {
	"png": "res://assets/sprites/towers/projectiles.png",
	"frames": "res://entities/towers/projectile_frames.tres",
	"vector": "effects",
	"scale": VECTOR_SCALE,
	"size": Vector2i(40, 40) * VECTOR_SCALE,
	"anims": [
		["arrow_0", 0, 1, 1.0, false],
		["arrow_1", 1, 1, 1.0, false],
		["arrow_2", 2, 1, 1.0, false],
		["arrow_3", 3, 1, 1.0, false],
		["arrow_4", 4, 1, 1.0, false],
		["arrow_5", 5, 1, 1.0, false],
		["arrow_6", 6, 1, 1.0, false],
		["arrow_7", 7, 1, 1.0, false],
		["cannonball", 8, 4, 20.0, true],
		["frost_bolt", 9, 8, 24.0, true],
		["cannonball_heavy", 10, 4, 20.0, true],
		["fire_glob", 11, 4, 24.0, true],
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
		["mortar_shell", 36, 4, 20.0, true],
	],
}

const EXPLOSION: Dictionary = {
	"png": "res://assets/sprites/effects/explosion.png",
	"frames": "res://entities/effects/explosion_frames.tres",
	"size": Vector2i(112, 112),
	"anims": [["explosion", 0, 7, 16.0, false]],
}

## The big shells' blast (cannon level 3): 72x72 art = a 144 px blast.
const EXPLOSION_LARGE: Dictionary = {
	"png": "res://assets/sprites/effects/explosion_large.png",
	"frames": "res://entities/effects/explosion_large_frames.tres",
	"size": Vector2i(144, 144),
	"anims": [["explosion_large", 0, 7, 16.0, false]],
}

## The frost nova (frost level 3): 48x48 art = a 96 px ring.
const FROST_NOVA: Dictionary = {
	"png": "res://assets/sprites/effects/frost_nova.png",
	"frames": "res://entities/effects/frost_nova_frames.tres",
	"size": Vector2i(96, 96),
	"anims": [["frost_nova", 0, 6, 16.0, false]],
}

## The Knight's Last Stand ring (M14): world-resolution frames, one row per radius (160 px, and 224 px with Wider Circle).
const ULTIMATE_RING: Dictionary = {
	"png": "res://assets/sprites/effects/ultimate_ring.png",
	"frames": "res://entities/effects/ultimate_ring_frames.tres",
	"size": Vector2i(480, 480),
	"anims": [["ring", 0, 6, 20.0, false], ["ring_wide", 1, 6, 20.0, false]],
}

## Burning ground (looping): hellfire shells and the brazier's fire.
const BURN: Dictionary = {
	"png": "res://assets/sprites/effects/burn.png",
	"frames": "res://entities/effects/burn_frames.tres",
	"size": Vector2i(96, 64),
	"anims": [["burn", 0, 4, 10.0, true], ["soul_burn", 1, 4, 10.0, true]],
}

## Evolution effects (evolution_art.gd). The soul burst (Pyre of Souls): 56x56 art.
const SOUL_BURST: Dictionary = {
	"png": "res://assets/sprites/effects/soul_burst.png",
	"frames": "res://entities/effects/soul_burst_frames.tres",
	"size": Vector2i(112, 112),
	"anims": [["soul_burst", 0, 7, 16.0, false]],
}

## Arrow rain (Volley Tower): 64x64 art = a 128 px shower.
const EVOLUTION_FX: Dictionary = {
	"png": "res://assets/sprites/effects/evolution_fx.png",
	"frames": "res://entities/effects/evolution_fx_frames.tres",
	"size": Vector2i(128, 128),
	"anims": [["arrow_rain", 0, 5, 16.0, false]],
}

## The grapeshot blast (Grapeshot Battery) in 8 directions (grapeshot_0 right, then clockwise).
const GRAPESHOT: Dictionary = {
	"png": "res://assets/sprites/effects/grapeshot.png",
	"frames": "res://entities/effects/grapeshot_frames.tres",
	"size": Vector2i(128, 128),
	"anims": [["grapeshot_0", 0, 4, 18.0, false], ["grapeshot_1", 1, 4, 18.0, false], ["grapeshot_2", 2, 4, 18.0, false],
		["grapeshot_3", 3, 4, 18.0, false], ["grapeshot_4", 4, 4, 18.0, false], ["grapeshot_5", 5, 4, 18.0, false],
		["grapeshot_6", 6, 4, 18.0, false], ["grapeshot_7", 7, 4, 18.0, false]],
}

## Status marks: an enemy frozen solid, a vulnerable enemy's cracked rune, a boosted tower's ember.
const STATUS: Dictionary = {
	"png": "res://assets/sprites/effects/status.png",
	"frames": "res://entities/effects/status_frames.tres",
	"size": Vector2i(48, 56),
	"anims": [["frozen", 0, 2, 3.0, true], ["shattered", 1, 4, 8.0, true], ["beacon_ember", 2, 4, 8.0, true],
		["silenced", 3, 4, 6.0, true]],
}

const FROST_FX: Dictionary = {
	"png": "res://assets/sprites/effects/frost.png",
	"frames": "res://entities/effects/frost_frames.tres",
	"size": Vector2i(40, 40),
	"anims": [["frost_burst", 0, 5, 16.0, false], ["frost_aura", 1, 4, 6.0, true]],
}

## Chapter 2's enemies (M7.5). The Bloater (40x40: swollen, pulsing gas sacs; its death bursts) and
## its Bloatlings (24x24, the same creature drawn small); the Mire Priest (its heal: 0-3 the staff
## rises, the telegraph; 4-5 the pulse); the Shieldbearer (its shield always toward where it walks).
const BLOATER: Dictionary = {
	"png": "res://assets/sprites/enemies/bloater.png",
	"frames": "res://entities/enemies/bloater_frames.tres",
	"size": Vector2i(80, 80),
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
	"size": Vector2i(48, 48),
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
	"size": Vector2i(64, 64),
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
	"size": Vector2i(64, 64),
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
	"size": Vector2i(64, 32),
	"anims": [["ripple", 0, 4, 6.0, true]],
}

## All sheets that become SpriteFrames.
## The graveyard's twelve props (vector, EnvPainter.PROPS; M15): 64x96 world cells, the feet 40 px below the centre. The
## other maps keep props.png (pixel) until their phases.
const GRAVEYARD_PROPS: Dictionary = {
	"png": "res://assets/sprites/environment/graveyard_props.png",
	"vector": "env_props",
	"scale": VECTOR_SCALE,
	"size": Vector2i(64, 96) * VECTOR_SCALE,
	"origin": Vector2(0, 40),
	"columns": 12,
}
## The crypt (vector; M15): a 128x128 world cell, the feet 58 px below the centre.
const CRYPT: Dictionary = {
	"png": "res://assets/sprites/environment/crypt.png",
	"vector": "env_crypt",
	"scale": VECTOR_SCALE,
	"size": Vector2i(128, 128) * VECTOR_SCALE,
	"origin": Vector2(0, 58),
	"columns": 1,
}
## The build pad (two frames: plain and highlighted) and the rubble that blocks a slot (vector; M15): 56x40 world cells.
const BUILD_PAD: Dictionary = {
	"png": "res://assets/sprites/towers/build_slot.png",
	"vector": "env_pad",
	"scale": VECTOR_SCALE,
	"size": Vector2i(56, 40) * VECTOR_SCALE,
	"origin": Vector2.ZERO,
	"columns": 2,
}
const SLOT_RUBBLE: Dictionary = {
	"png": "res://assets/sprites/towers/slot_rubble.png",
	"vector": "env_rubble",
	"scale": VECTOR_SCALE,
	"size": Vector2i(56, 40) * VECTOR_SCALE,
	"origin": Vector2.ZERO,
	"columns": 1,
}

## The arena grounds baked from a level's own geometry (floor, roads, fortress, crypts, pads) by bake_sheets.gd with
## GroundPainter, at "scale" texture px per world px, floor plus the visible wall band all round (the level's TiledGround
## draws it at 1 / scale). The other maps' grounds stay pixel until their phases.
const GROUNDS: Array[Dictionary] = [
	{"png": "res://assets/sprites/environment/prototype_arena_ground.png", "level": "res://levels/prototype_arena.tscn", "vector": "ground", "scale": VECTOR_SCALE, "band": 32.0},
]

## Static vector sheets (a Sprite2D's hframes: one row of cells), baked by bake_sheets.gd; no SpriteFrames.
const STATIC: Array[Dictionary] = [FORTRESS, GRAVEYARD_PROPS, CRYPT, BUILD_PAD, SLOT_RUBBLE]

const ANIMATED: Array[Dictionary] = [BLOATER, BLOATLING, MIRE_PRIEST, SHIELDBEARER, RIPPLE, HERO, HUNTRESS, NECROMANCER, SIEGE_RAM, BLACK_KNIGHT, FALLEN_MARSHAL, CINDER_GHOUL, SCARECROW, PYRE_WARDEN, FROST_WRAITH, RIME_BRUTE, WINTER_WARDEN, BURROWER, LAMP_WIGHT, DEEP_WARDEN, BONE_HURLER, RUBBLE_BRUTE, QUARRY_COLOSSUS, STALKER, HOLLOW_TREANT, HOLLOW_STAG, CHORISTER, INQUISITOR, PALE_BISHOP, SKELETON, SOUL_BOLT, SWING, GHOUL, HOUND, BRUTE, CULTIST, CULTIST_FX, GRAVELORD, COLOSSUS, LICH, TOLLKEEPER, HIT_SPARK, DUST, TOWERS, TOWER_EVOLUTIONS, HUNTRESS_TOWERS, NECRO_TOWERS, COMBO_TOWERS, HUNTRESS_FX, PROJECTILES, EXPLOSION, EXPLOSION_LARGE, FROST_NOVA, ULTIMATE_RING, BURN, FROST_FX, FORTRESS_FX, SOUL_BURST, EVOLUTION_FX, GRAPESHOT, STATUS]

## The Huntress's towers (M9, huntress_towers_art.gd): rows of 4-6 frames, 64x96 each.
const HUNTRESS_TOWERS: Dictionary = {
	"png": "res://assets/sprites/towers/huntress_towers.png",
	"frames": "res://entities/towers/huntress_tower_frames.tres",
	"size": Vector2i(64, 96),
	"anims": [
		["trap_layer_idle", 0, 4, 5.0, true],
		["trap_layer_fire", 1, 4, 12.0, false],
		["trap_layer_build", 2, 6, 10.0, false],
		["trap_layer_sell", 3, 6, 10.0, false],
		["trap_layer_idle_2", 4, 4, 5.0, true],
		["trap_layer_fire_2", 5, 4, 12.0, false],
		["trap_layer_idle_3", 6, 4, 5.0, true],
		["trap_layer_fire_3", 7, 4, 12.0, false],
		["bear_pit_idle", 8, 4, 5.0, true],
		["bear_pit_fire", 9, 4, 12.0, false],
		["caltrop_field_idle", 10, 4, 5.0, true],
		["caltrop_field_fire", 11, 4, 12.0, false],
		["hawk_perch_idle", 12, 4, 5.0, true],
		["hawk_perch_fire", 13, 4, 12.0, false],
		["hawk_perch_build", 14, 6, 10.0, false],
		["hawk_perch_sell", 15, 6, 10.0, false],
		["hawk_perch_idle_2", 16, 4, 5.0, true],
		["hawk_perch_fire_2", 17, 4, 12.0, false],
		["hawk_perch_idle_3", 18, 4, 5.0, true],
		["hawk_perch_fire_3", 19, 4, 12.0, false],
		["falconer_idle", 20, 4, 5.0, true],
		["falconer_fire", 21, 4, 12.0, false],
		["eye_of_the_hunt_idle", 22, 4, 5.0, true],
		["eye_of_the_hunt_fire", 23, 4, 12.0, false],
		["watchtower_idle", 24, 4, 5.0, true],
		["watchtower_fire", 25, 4, 12.0, false],
		["watchtower_build", 26, 6, 10.0, false],
		["watchtower_sell", 27, 6, 10.0, false],
		["watchtower_idle_2", 28, 4, 5.0, true],
		["watchtower_fire_2", 29, 4, 12.0, false],
		["watchtower_idle_3", 30, 4, 5.0, true],
		["watchtower_fire_3", 31, 4, 12.0, false],
		["signal_fire_idle", 32, 4, 5.0, true],
		["signal_fire_fire", 33, 4, 12.0, false],
		["marksmans_roost_idle", 34, 4, 5.0, true],
		["marksmans_roost_fire", 35, 4, 12.0, false],
	],
}

## The Necromancer's towers (M9, necro_towers_art.gd): the Huntress's towers' layout.
const NECRO_TOWERS: Dictionary = {
	"png": "res://assets/sprites/towers/necro_towers.png",
	"frames": "res://entities/towers/necro_tower_frames.tres",
	"size": Vector2i(64, 96),
	"anims": [
		["bone_pit_idle", 0, 4, 5.0, true],
		["bone_pit_fire", 1, 4, 12.0, false],
		["bone_pit_build", 2, 6, 10.0, false],
		["bone_pit_sell", 3, 6, 10.0, false],
		["bone_pit_idle_2", 4, 4, 5.0, true],
		["bone_pit_fire_2", 5, 4, 12.0, false],
		["bone_pit_idle_3", 6, 4, 5.0, true],
		["bone_pit_fire_3", 7, 4, 12.0, false],
		["charnel_gate_idle", 8, 4, 5.0, true],
		["charnel_gate_fire", 9, 4, 12.0, false],
		["plague_pit_idle", 10, 4, 5.0, true],
		["plague_pit_fire", 11, 4, 12.0, false],
		["soul_siphon_idle", 12, 4, 5.0, true],
		["soul_siphon_fire", 13, 4, 12.0, false],
		["soul_siphon_build", 14, 6, 10.0, false],
		["soul_siphon_sell", 15, 6, 10.0, false],
		["soul_siphon_idle_2", 16, 4, 5.0, true],
		["soul_siphon_fire_2", 17, 4, 12.0, false],
		["soul_siphon_idle_3", 18, 4, 5.0, true],
		["soul_siphon_fire_3", 19, 4, 12.0, false],
		["soul_harvester_idle", 20, 4, 5.0, true],
		["soul_harvester_fire", 21, 4, 12.0, false],
		["wither_beam_idle", 22, 4, 5.0, true],
		["wither_beam_fire", 23, 4, 12.0, false],
		["ossuary_idle", 24, 4, 5.0, true],
		["ossuary_fire", 25, 4, 12.0, false],
		["ossuary_build", 26, 6, 10.0, false],
		["ossuary_sell", 27, 6, 10.0, false],
		["ossuary_idle_2", 28, 4, 5.0, true],
		["ossuary_fire_2", 29, 4, 12.0, false],
		["ossuary_idle_3", 30, 4, 5.0, true],
		["ossuary_fire_3", 31, 4, 12.0, false],
		["bone_storm_idle", 32, 4, 5.0, true],
		["bone_storm_fire", 33, 4, 12.0, false],
		["death_knell_idle", 34, 4, 5.0, true],
		["death_knell_fire", 35, 4, 12.0, false],
	],
}

## The six combo evolutions (M9, combo_towers_art.gd): an idle and a fire row each, 64x96 frames.
const COMBO_TOWERS: Dictionary = {
	"png": "res://assets/sprites/towers/combo_towers.png",
	"frames": "res://entities/towers/combo_tower_frames.tres",
	"size": Vector2i(64, 96),
	"anims": [
		["heart_of_the_pyre_idle", 0, 4, 5.0, true],
		["heart_of_the_pyre_fire", 1, 4, 12.0, false],
		["stillwater_idle", 2, 4, 5.0, true],
		["stillwater_fire", 3, 4, 12.0, false],
		["headsmans_bolt_idle", 4, 4, 5.0, true],
		["headsmans_bolt_fire", 5, 4, 12.0, false],
		["sky_tyrant_idle", 6, 4, 5.0, true],
		["sky_tyrant_fire", 7, 4, 12.0, false],
		["legion_idle", 8, 4, 5.0, true],
		["legion_fire", 9, 4, 12.0, false],
		["banner_guard_idle", 10, 4, 5.0, true],
		["banner_guard_fire", 11, 4, 12.0, false],
	],
}

## The snare, the spiked patch and the hawk in 8 directions (hawk_0 flies right, then every 45 degrees clockwise).
const HUNTRESS_FX: Dictionary = {
	"png": "res://assets/sprites/towers/huntress_fx.png",
	"frames": "res://entities/towers/huntress_fx_frames.tres",
	"size": Vector2i(64, 64),
	"anims": [
		["snare_armed", 0, 2, 3.0, true],
		["snare_sprung", 1, 3, 14.0, false],
		["patch", 2, 4, 6.0, true],
		["hawk_0", 3, 2, 12.0, true],
		["hawk_1", 4, 2, 12.0, true],
		["hawk_2", 5, 2, 12.0, true],
		["hawk_3", 6, 2, 12.0, true],
		["hawk_4", 7, 2, 12.0, true],
		["hawk_5", 8, 2, 12.0, true],
		["hawk_6", 9, 2, 12.0, true],
		["hawk_7", 10, 2, 12.0, true],
	],
}

## Build slot pad for a Sprite2D (hframes 2): normal, highlighted (the hero is close).
const BUILD_SLOT: Dictionary = {
	"png": "res://assets/sprites/towers/build_slot.png",
	"size": Vector2i(56, 40),
}

## Single-row sheet used directly by a Sprite2D (hframes): healthy, damaged, badly damaged, destroyed.
## 3/4 view: the 48x48 footprint (= the 96 px collision box) is the lower part of each 96x96 frame
## (art rect 24,40 - 72,88); walls, towers and roofs rise above it.
## The fortress's four looks (vector, FortressPainter; M15): healthy, damaged, badly damaged, destroyed; drawn at node
## coordinates (the scene's origin is the keep's collision-box centre, "origin" puts it 32 px below the cell's centre,
## where the sprite sits). A static sheet: one row of "columns" cells, baked by bake_sheets.gd.
const FORTRESS: Dictionary = {
	"png": "res://assets/sprites/fortress/fortress.png",
	"vector": "fortress",
	"scale": VECTOR_SCALE,
	"size": Vector2i(192, 192) * VECTOR_SCALE,
	"origin": Vector2(0, 32),
	"columns": 4,
	"frames_count": 4,
	"static": true,
}

## Animated pieces placed on the fortress: waving banners, fires (damage) and wall braziers.
## The fortress decor (vector, FortressPainter.decor_frame; M15): the hanging banner, the torn banner, a torch flame and a
## fire, 48x64 world cells centred on each decor sprite.
const FORTRESS_FX: Dictionary = {
	"png": "res://assets/sprites/fortress/fortress_fx.png",
	"frames": "res://entities/fortress/fortress_fx_frames.tres",
	"vector": "fortress_fx",
	"scale": VECTOR_SCALE,
	"size": Vector2i(48, 64) * VECTOR_SCALE,
	"anims": [
		["banner", 0, 8, 12.0, true],
		["banner_torn", 1, 8, 12.0, true],
		["fire", 2, 12, 24.0, true],
		["brazier", 3, 8, 20.0, true],
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

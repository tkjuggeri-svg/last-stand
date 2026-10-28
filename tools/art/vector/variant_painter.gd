class_name VariantPainter
## The enemy and boss variants of M15 P4b (docs/M15_P4_MAPS.md): a variant is a base painter's figure (Ghoul, Hound,
## Cultist, Brute, Lich, Colossus, Gravelord) recoloured by a palette ramp (a luminance gradient map in a shader on the
## baked cell, so the painter's shading, outline and glows stay) with its own silhouette drawn over it
## (variant_extras.gd: flames, ice, antlers, a shield, a bell ...). A variant keeps its base's animation rows and timings;
## only the attack's rate follows the variant's own wind-up (sheet_layouts.gd `_attack_rate`).
## parts(id) gives bake_sheets.gd what it needs: the frame painter, the figure's scale, the extras and the material.

## Per base: the frame painter, its scale, the attack's shape (wind-up end, strike peak, pull back) and the head's anchor
## per facing (pose units: feet at y 0), the figure's rest height for the extras.
const BASES: Dictionary = {
	"ghoul": {"scale": 1.15, "shape": Vector3(0.55, 0.727, -0.3), "head": {"down": Vector2(0, -26), "up": Vector2(0, -27), "side": Vector2(12.5, -20)}},
	"hound": {"scale": 1.15, "shape": Vector3(0.5, 0.727, -0.35), "head": {"down": Vector2(0, -15.5), "up": Vector2(0, -15.5), "side": Vector2(17, -16)}},
	"cultist": {"scale": 1.15, "shape": Vector3(0.6, 0.8, 0.0), "head": {"down": Vector2(0, -26), "up": Vector2(0, -26), "side": Vector2(0.5, -26)}},
	"brute": {"scale": 1.12, "shape": Vector3(0.6, 0.8, -1.0), "head": {"down": Vector2(0, -47), "up": Vector2(0, -47), "side": Vector2(3, -47)}},
	"lich": {"scale": 1.3, "shape": Vector3(0.58, 0.82, -1.0), "head": {"down": Vector2(0, -63), "up": Vector2(0, -63), "side": Vector2(0, -63)}},
	"colossus": {"scale": 1.3, "shape": Vector3(0.6, 0.82, -1.0), "head": {"down": Vector2(0, -63), "up": Vector2(0, -63), "side": Vector2(0, -63)}},
	"gravelord": {"scale": 1.3, "shape": Vector3(0.58, 0.82, -1.0), "head": {"down": Vector2(0, -63), "up": Vector2(0, -63), "side": Vector2(0, -63)}},
}

## Per variant: its base, the palette ramp (dark, mid, light), how far the ramp replaces the base colours, the figure's
## growth against its base, and the hue turn (in turns of the colour wheel) of the saturated colours the ramp keeps: the
## eyes, orbs and flames, which is how a violet fire becomes orange.
const VARIANTS: Dictionary = {
	"cinder_ghoul": {"base": "ghoul", "ramp": [Color("0c0708"), Color("5a3a30"), Color("f0a868")], "amount": 0.92, "grow": 1.0, "hue": 0.07},
	"scarecrow": {"base": "brute", "ramp": [Color("100c06"), Color("6e5230"), Color("e8cd7c")], "amount": 0.95, "grow": 0.92, "hue": 0.54},
	"bone_hurler": {"base": "cultist", "ramp": [Color("100e0b"), Color("7a7058"), Color("f4ecd2")], "amount": 0.92, "grow": 1.0, "hue": -0.23},
	"rubble_brute": {"base": "brute", "ramp": [Color("0e0d0f"), Color("6a665e"), Color("d8cfbc")], "amount": 0.9, "grow": 1.0, "hue": 0.5},
	"bloater": {"base": "brute", "ramp": [Color("0a1006"), Color("56703a"), Color("c8da7e")], "amount": 0.9, "grow": 1.0, "hue": -0.4},
	"bloatling": {"base": "ghoul", "ramp": [Color("0a1006"), Color("5c7a3a"), Color("d2e68a")], "amount": 0.9, "grow": 0.62, "hue": 0.2},
	"mire_priest": {"base": "cultist", "ramp": [Color("060f0e"), Color("2e6a62"), Color("9ae0c8")], "amount": 0.92, "grow": 1.0, "hue": 0.17},
	"shieldbearer": {"base": "brute", "ramp": [Color("0a0c12"), Color("56647c"), Color("cfdcec")], "amount": 0.9, "grow": 0.9, "hue": 0.0},
	"frost_wraith": {"base": "cultist", "ramp": [Color("060b16"), Color("5a86b4"), Color("f0faff")], "amount": 0.95, "grow": 1.05, "hue": 0.22},
	"rime_brute": {"base": "brute", "ramp": [Color("070b16"), Color("6f93be"), Color("f2fbff")], "amount": 0.92, "grow": 1.0, "hue": -0.1},
	"stalker": {"base": "hound", "ramp": [Color("050c07"), Color("2f5a38"), Color("a6d68a")], "amount": 0.92, "grow": 1.0, "hue": 0.07},
	"hollow_treant": {"base": "brute", "ramp": [Color("060904"), Color("486a2e"), Color("c4d27c")], "amount": 0.95, "grow": 1.15, "hue": 0.5},
	"pyre_warden": {"base": "lich", "ramp": [Color("0c0405"), Color("6a2a1c"), Color("ffb060")], "amount": 0.92, "grow": 1.0, "hue": 0.31},
	"winter_warden": {"base": "lich", "ramp": [Color("050a16"), Color("4a78b0"), Color("eef8ff")], "amount": 0.94, "grow": 1.0, "hue": -0.25},
	"quarry_colossus": {"base": "colossus", "ramp": [Color("0e0c0a"), Color("7a6a52"), Color("e0d0a8")], "amount": 0.92, "grow": 1.0, "hue": 0.35},
	"hollow_stag": {"base": "gravelord", "ramp": [Color("050a06"), Color("3a5a30"), Color("b8d890")], "amount": 0.92, "grow": 1.0, "hue": 0.0},
	"tollkeeper": {"base": "gravelord", "ramp": [Color("050c0c"), Color("2c5a58"), Color("9cd8c4")], "amount": 0.92, "grow": 1.0, "hue": 0.1},
}

## A variant's ramp brightened so the figure stays readable against the maps' grounds (test_readability: mean luminance
## against every ground, in grayscale): the mid colour by `gain`, the light and the dark by less.
const GAIN: Dictionary = {"cinder_ghoul": 1.16, "scarecrow": 1.36, "rubble_brute": 1.3, "mire_priest": 1.18, "shieldbearer": 1.2, "stalker": 1.95, "hollow_treant": 1.6,
	"pyre_warden": 1.75, "hollow_stag": 1.28, "tollkeeper": 1.65}

const SHADER_CODE: String = """
shader_type canvas_item;
uniform vec3 dark;
uniform vec3 mid;
uniform vec3 light;
uniform float amount;
uniform float hue;
vec3 turn(vec3 c, float t) {
	float a = t * 6.2831853;
	vec3 k = vec3(0.57735);
	return c * cos(a) + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - cos(a));
}
void fragment() {
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 mapped = l < 0.5 ? mix(dark, mid, l * 2.0) : mix(mid, light, (l - 0.5) * 2.0);
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	COLOR.rgb = clamp(mix(turn(c, hue), mapped, amount * (1.0 - smoothstep(0.42, 0.62, sat))), 0.0, 1.0);
}
"""

static var _shader: Shader


## What bake_sheets.gd needs for variant `id`: [frame painter, figure scale, extras painter, material].
static func parts(id: String) -> Array:
	var v: Dictionary = VARIANTS[id]
	var base: String = String(v.base)
	var figure: float = float(BASES[base].scale) * float(v.grow)
	return [
		func(ci: CanvasItem, anim: String, index: int, count: int) -> void: _base_frame(ci, base, anim, index, count),
		figure,
		func(ci: CanvasItem, anim: String, index: int, count: int) -> void: _extras(ci, id, anim, index, count),
		material(id, v),
	]


static func material(id: String, v: Dictionary) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _shader
	var ramp: Array = v.ramp
	var gain: float = float(GAIN.get(id, 1.0))
	mat.set_shader_parameter("dark", _scaled(ramp[0], pow(gain, 0.3)))
	mat.set_shader_parameter("mid", _scaled(ramp[1], gain))
	mat.set_shader_parameter("light", _scaled(ramp[2], pow(gain, 0.6)))
	mat.set_shader_parameter("amount", float(v.amount))
	mat.set_shader_parameter("hue", float(v.hue))
	return mat


static func _scaled(c: Color, by: float) -> Vector3:
	return Vector3(minf(c.r * by, 1.0), minf(c.g * by, 1.0), minf(c.b * by, 1.0))


static func _base_frame(ci: CanvasItem, base: String, anim: String, index: int, count: int) -> void:
	# The boss rows named for a variant's own move ("toll") play the base's cast.
	var named: String = anim.replace("toll_", "cast_").replace("heal_", "idle_")
	match base:
		"ghoul":
			GhoulPainter.frame(ci, named, index, count)
		"hound":
			HoundPainter.frame(ci, named, index, count)
		"cultist":
			CultistPainter.frame(ci, named, index, count)
		"brute":
			BrutePainter.frame(ci, named, index, count)
		"lich":
			LichPainter.frame(ci, named, index, count)
		"colossus":
			ColossusPainter.frame(ci, named, index, count)
		_:
			GravelordPainter.frame(ci, named, index, count)


## The variant's own silhouette over the recoloured base, with the live pose the base had (`head` is the base's head anchor at rest;
## the paint call is already shifted by the bob, the glows add it themselves).
static func _extras(ci: CanvasItem, id: String, anim: String, index: int, count: int) -> void:
	var v: Dictionary = VARIANTS[id]
	var base: String = String(v.base)
	var a: Dictionary = VectorFrames.parse(anim.replace("toll_", "cast_"))
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	var state: String = a.state
	var facing: String = a.facing
	var shape: Vector3 = BASES[base].shape
	var lunge: float = 0.0
	if state == "attack":
		lunge = VectorFrames.attack_curve(progress, shape.x, shape.y, shape.z)
	var head: Vector2 = BASES[base].head[facing]
	var bob: float = _bob(base, state, cycle)
	var pose: Dictionary = {
		"id": id, "base": base, "facing": facing, "state": state, "cycle": cycle, "progress": progress, "lunge": lunge,
		"bob": bob, "head": head, "walk": state == "walk", "anim": anim,
	}
	if state == "death":
		VariantExtras.death(ci, pose)
		return
	ci.draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	VariantExtras.paint(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	VariantExtras.glows(ci, pose)


## The base painter's vertical bob, so an extra attached to the figure rides with it.
static func _bob(base: String, state: String, cycle: float) -> float:
	var walking: bool = state == "walk"
	var wave: float = absf(sin(cycle * TAU))
	match base:
		"ghoul":
			return -wave * 1.2 if walking else sin(cycle * TAU) * 0.4
		"hound":
			return -wave * 2.2 if walking else sin(cycle * TAU) * 0.5
		"cultist":
			return -wave * 0.8 if walking else sin(cycle * TAU) * 0.5
		"brute":
			return -wave * 1.6 if walking else sin(cycle * TAU) * 0.7
		"lich":
			var lift: float = sin(cycle * TAU) * 1.6
			return -6.0 - (lift * 0.6 if walking else lift)
		"colossus":
			return -wave * 1.5 if walking else sin(cycle * TAU) * 0.5
		_:
			return -wave * 1.2 if walking else sin(cycle * TAU) * 0.6

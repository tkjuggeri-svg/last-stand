extends SceneTree
## Draws all LAST STAND pixel art (original, made entirely in code) and saves it as PNG sheets.
## Characters are hand-written pixel grids (one character = one palette colour) composed per frame;
## effects, the fortress and the arena ground are drawn procedurally with fixed seeds.
##
## Regenerate everything (from the project folder):
##   godot --headless --path . --script res://tools/art/generate_art.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/art/build_sprite_frames.gd

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")

const DIRS_4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# --- Hero parts (facing down / up / side = right). No outlines: an outline pass adds them. ---
const HERO_HEAD_DOWN: Array[String] = [
	"...RR...",
	"..sSSs..",
	".sSSSSs.",
	"sSSSSSSs",
	"sdoddods",
	"sSSdSSSs",
	".dssssd.",
]
const HERO_HEAD_UP: Array[String] = [
	"...RR...",
	"..sSSs..",
	".sSSSSs.",
	"sSSSSSSs",
	"sSSSSSSs",
	"ssSSSSss",
	".dssssd.",
]
const HERO_HEAD_SIDE: Array[String] = [
	".RR.....",
	"RRsSSs..",
	".sSSSSs.",
	"sSSSSSSs",
	"sSSSdooo",
	"sSSSSSds",
	".dssssd.",
]
const HERO_TORSO_DOWN: Array[String] = [
	"SSsdRRRRdsSS",
	"sSddRRyRddSs",
	"sd.dRyyyd.ds",
	"sd.dRRyRd.ds",
	"kk.BbbbbB.kk",
	"...RRRRRR...",
	"...rrrrrr...",
]
const HERO_TORSO_UP: Array[String] = [
	"SSsRRRRRRsSS",
	"sSdRRRRRRdSs",
	"sd.RRRRRR.ds",
	"sd.rRRRRr.ds",
	"kk.rRRRRr.kk",
	"...rRRRRr...",
	"...rrrrrr...",
]
const HERO_TORSO_SIDE: Array[String] = [
	"RRsSSSs...",
	"RRsSSds...",
	"RrdRRRs...",
	"RrdRyRkk..",
	"rr.BbbB...",
	"..RRRR....",
	"..rrrr....",
]
const HERO_LEGS_FRONT: Array[Array] = [
	["...sS..Ss...", "...sd..ds...", "...BB..BB..."],
	["...sS..Ss...", "...sd..BB...", "...BB......."],
	["...sS..Ss...", "...BB..ds...", ".......BB..."],
]
const HERO_LEGS_SIDE: Array[Array] = [
	["...sS.....", "...sd.....", "...BBB...."],
	["..sS.Ss...", ".sd...ds..", ".BB....BB."],
	["...sSs....", "..sd.ds...", "..BB.BB..."],
]

# --- Ghoul parts ---
const GHOUL_HEAD_DOWN: Array[String] = [
	"..gGGg..",
	".gGGGGg.",
	"gGGGGGGg",
	"gGEGGEGg",
	"gGGGGGGg",
	".gqmmqg.",
	"..gggg..",
]
const GHOUL_HEAD_UP: Array[String] = [
	"..gGGg..",
	".gGGGGg.",
	"gGGGGGGg",
	"gGGGGGGg",
	"gGGGGGGg",
	".gGGGGg.",
	"..gggg..",
]
const GHOUL_HEAD_SIDE: Array[String] = [
	"..gGGg.",
	".gGGGGg",
	"gGGGGEG",
	"gGGGGGG",
	".gGGqmm",
	"..ggg..",
]
const GHOUL_TORSO_DOWN: Array[String] = [
	".gGcCCCCcGg.",
	"gGgcCCCCcgGg",
	"gG.cCcCCc.Gg",
	"gG.ccCCcc.Gg",
	"Gg..cCCc..gG",
	"nn..cccc..nn",
]
const GHOUL_TORSO_UP: Array[String] = [
	".gGcCCCCcGg.",
	"gGgcCqCCcgGg",
	"gG.cCqCCc.Gg",
	"gG.cCqCCc.Gg",
	"Gg..cCCc..gG",
	"nn..cccc..nn",
]
const GHOUL_TORSO_SIDE: Array[String] = [
	"..cCCC....",
	".cCCCCg...",
	".cCCcGGg..",
	"..cCc.gGg.",
	"..ccc..gGn",
	"..cc....nn",
]
const GHOUL_LEGS_FRONT: Array[Array] = [
	["....gg.gg...", "....qg.gq...", "....qq.qq..."],
	["....gg.gg...", "....qg.qq...", "....qq......"],
	["....gg.gg...", "....qq.gq...", ".......qq..."],
]
const GHOUL_LEGS_SIDE: Array[Array] = [
	["...gg.....", "...qg.....", "...qqq...."],
	["..gg.gg...", ".qg...gq..", ".qq....qq."],
	["...ggg....", "..qg.gq...", "..qq.qq..."],
]
const GHOUL_PILE: Array[String] = [
	"....nn......",
	"..cCCCnc....",
	".cCCgCCCcn..",
	"cCCCCGCCCCc.",
	".cccccccccc.",
]

var _palette: Dictionary = {
	"o": Color("1a141f"),  # outline / deepest shadow
	"S": Color("d3d7df"),  # steel highlight
	"s": Color("8f96a6"),  # steel
	"d": Color("565c6c"),  # steel shadow
	"R": Color("9b3131"),  # red tabard and plume (the accent colour)
	"r": Color("5f1e23"),  # red shadow
	"k": Color("d2a283"),  # skin
	"b": Color("6f4d34"),  # leather
	"B": Color("45301f"),  # dark leather / boots
	"y": Color("c9a24f"),  # gold trim
	"G": Color("a5b090"),  # ghoul skin
	"g": Color("6d7a61"),  # ghoul skin shadow
	"q": Color("434c3d"),  # ghoul deep shadow
	"E": Color("e2462f"),  # ghoul eyes
	"m": Color("2b1b1d"),  # ghoul mouth
	"C": Color("51473b"),  # rags
	"c": Color("342c26"),  # rags shadow
	"n": Color("d9d1ba"),  # bone and claws
}
var _outline_color: Color = Color("1a141f")
var _shadow_color: Color = Color(0.0, 0.0, 0.0, 0.32)


func _initialize() -> void:
	_save(_hero_sheet(), Layouts.HERO["png"])
	_save(_swing_sheet(), Layouts.SWING["png"])
	_save(_ghoul_sheet(), Layouts.GHOUL["png"])
	_save(_spark_sheet(), Layouts.HIT_SPARK["png"])
	_save(_dust_sheet(), Layouts.DUST["png"])
	_save(_fortress_sheet(), Layouts.FORTRESS["png"])
	_save(_ground(), Layouts.GROUND_PNG)
	quit()


# ---------------------------------------------------------------- hero

func _hero_sheet() -> Image:
	var size: Vector2i = Layouts.HERO["size"]
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		rows.append([_hero_frame(facing, 0, 0, 0, -1), _hero_frame(facing, 0, 1, 0, -1)])
	for facing: String in ["down", "up", "side"]:
		var walk: Array[Image] = []
		for step: int in 4:
			var legs: int = [0, 1, 0, 2][step]
			walk.append(_hero_frame(facing, legs, [0, -1, 0, -1][step], 0, -1))
		rows.append(walk)
	for facing: String in ["down", "up", "side"]:
		rows.append([_hero_frame(facing, 0, 0, 0, 0), _hero_frame(facing, 2, 0, 1, 1), _hero_frame(facing, 0, 0, 0, 2)])
	return _sheet(rows, size)


## legs: leg pose index; bob: vertical offset; lean: offset toward the facing; attack: -1 = carry sword, 0-2 = swing pose.
func _hero_frame(facing: String, legs: int, bob: int, lean: int, attack: int) -> Image:
	var img: Image = _blank(Layouts.HERO["size"])
	var lean_offset: Vector2i = Vector2i(lean, 0) if facing == "side" else Vector2i(0, lean if facing == "down" else -lean)
	var sword_hilt: Vector2i
	var sword_dir: Vector2i
	var sword_len: int = 6
	match facing:
		"down":
			_paste(img, HERO_LEGS_FRONT[legs], Vector2i(6, 16) + lean_offset)
			_paste(img, HERO_TORSO_DOWN, Vector2i(6, 9 + bob) + lean_offset)
			_paste(img, HERO_HEAD_DOWN, Vector2i(8, 2 + bob) + lean_offset)
			var poses: Array = [[Vector2i(6, 14), Vector2i(0, 1), 6], [Vector2i(7, 8), Vector2i(-1, -1), 6],
				[Vector2i(11, 15), Vector2i(0, 1), 7], [Vector2i(14, 14), Vector2i(1, 1), 6]]
			var pose: Array = poses[attack + 1]
			sword_hilt = pose[0]
			sword_dir = pose[1]
			sword_len = pose[2]
		"up":
			_paste(img, HERO_LEGS_FRONT[legs], Vector2i(6, 16) + lean_offset)
			var poses_up: Array = [[Vector2i(17, 14), Vector2i(0, 1), 5], [Vector2i(16, 13), Vector2i(1, 1), 5],
				[Vector2i(16, 8), Vector2i(1, -1), 6], [Vector2i(8, 7), Vector2i(-1, -1), 5]]
			var pose_up: Array = poses_up[attack + 1]
			sword_hilt = pose_up[0]
			sword_dir = pose_up[1]
			sword_len = pose_up[2]
			# Seen from behind, a sword held low is partly hidden by the body: draw it first.
			if attack != 1:
				_sword(img, sword_hilt + lean_offset, sword_dir, sword_len)
			_paste(img, HERO_TORSO_UP, Vector2i(6, 9 + bob) + lean_offset)
			_paste(img, HERO_HEAD_UP, Vector2i(8, 2 + bob) + lean_offset)
			if attack == 1:
				_sword(img, sword_hilt + lean_offset, sword_dir, sword_len)
			return _finish_character(img, Vector2i(12, 19))
		"side":
			_paste(img, HERO_LEGS_SIDE[legs], Vector2i(7, 16) + lean_offset)
			_paste(img, HERO_TORSO_SIDE, Vector2i(7, 9 + bob) + lean_offset)
			_paste(img, HERO_HEAD_SIDE, Vector2i(8, 2 + bob) + lean_offset)
			var poses_side: Array = [[Vector2i(13, 13), Vector2i(1, 1), 6], [Vector2i(10, 8), Vector2i(-1, -1), 6],
				[Vector2i(16, 12), Vector2i(1, 0), 7], [Vector2i(15, 14), Vector2i(1, 1), 6]]
			var pose_side: Array = poses_side[attack + 1]
			sword_hilt = pose_side[0]
			sword_dir = pose_side[1]
			sword_len = pose_side[2]
	_sword(img, sword_hilt + lean_offset, sword_dir, sword_len)
	return _finish_character(img, Vector2i(12, 19))


## A sword along one of the 8 directions: pommel, crossguard, then a 1 px blade (the outline thickens it).
func _sword(img: Image, hilt: Vector2i, dir: Vector2i, length: int) -> void:
	var across: Vector2i = Vector2i(-dir.y, dir.x)
	_px(img, hilt - dir, _palette["B"])
	_px(img, hilt, _palette["b"])
	_px(img, hilt + dir + across, _palette["y"])
	_px(img, hilt + dir - across, _palette["y"])
	_px(img, hilt + dir, _palette["y"])
	for i: int in range(2, length + 2):
		_px(img, hilt + dir * i, _palette["S"] if i < length + 1 else _palette["s"])


# ---------------------------------------------------------------- ghoul

func _ghoul_sheet() -> Image:
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		rows.append([_ghoul_frame(facing, 0, 0, 0), _ghoul_frame(facing, 0, 1, 0)])
	for facing: String in ["down", "up", "side"]:
		var walk: Array[Image] = []
		for step: int in 4:
			walk.append(_ghoul_frame(facing, [0, 1, 0, 2][step], [0, 1, 0, 1][step], [0, 1, 0, -1][step]))
		rows.append(walk)
	rows.append(_ghoul_death())
	return _sheet(rows, Layouts.GHOUL["size"])


## twitch: head drops 1 px; sway: the whole upper body shifts sideways (a shambling gait).
func _ghoul_frame(facing: String, legs: int, twitch: int, sway: int) -> Image:
	var img: Image = _blank(Layouts.GHOUL["size"])
	match facing:
		"down", "up":
			_paste(img, GHOUL_LEGS_FRONT[legs], Vector2i(4, 14))
			_paste(img, GHOUL_TORSO_DOWN if facing == "down" else GHOUL_TORSO_UP, Vector2i(4 + sway, 8))
			_paste(img, GHOUL_HEAD_DOWN if facing == "down" else GHOUL_HEAD_UP, Vector2i(6 + sway, 2 + twitch))
		"side":
			_paste(img, GHOUL_LEGS_SIDE[legs], Vector2i(4, 14))
			_paste(img, GHOUL_TORSO_SIDE, Vector2i(3, 8 + twitch))
			_paste(img, GHOUL_HEAD_SIDE, Vector2i(9 + absi(sway), 4 + twitch))
	return _finish_character(img, Vector2i(10, 17))


func _ghoul_death() -> Array[Image]:
	var size: Vector2i = Layouts.GHOUL["size"]
	var frames: Array[Image] = []
	# Recoil: the body is thrown back (up) a pixel and flashes pale.
	var recoil: Image = _blank(size)
	_paste(recoil, GHOUL_LEGS_FRONT[0], Vector2i(4, 14))
	_paste(recoil, GHOUL_TORSO_DOWN, Vector2i(4, 7))
	_paste(recoil, GHOUL_HEAD_DOWN, Vector2i(6, 0))
	_outline(recoil)
	_tint(recoil, Color(1, 1, 1), 0.5)
	frames.append(recoil)
	# Buckling: the standing figure squashed toward the ground.
	var standing: Image = _ghoul_frame("down", 0, 0, 0)
	for height: int in [15, 10]:
		var squashed: Image = _blank(size)
		var body: Image = standing.get_region(Rect2i(0, 1, size.x, 17))
		body.resize(size.x + (2 if height == 10 else 0), height, Image.INTERPOLATE_NEAREST)
		squashed.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i(-1 if height == 10 else 0, 18 - height))
		frames.append(squashed)
	# A heap of rags and bones, then the heap dissolving.
	var pile: Image = _blank(size)
	_paste(pile, GHOUL_PILE, Vector2i(4, 12))
	_outline(pile)
	frames.append(pile)
	var fading: Image = pile.duplicate() as Image
	_dither_out(fading, 0)
	frames.append(fading)
	return frames


# ---------------------------------------------------------------- effects

func _swing_sheet() -> Image:
	var rows: Array[Array] = []
	for direction: int in 8:
		var frames: Array[Image] = []
		for frame: int in 3:
			frames.append(_swing_frame(direction * PI / 4.0, frame))
		rows.append(frames)
	return _sheet(rows, Layouts.SWING["size"])


## A crescent trail along the hero's swing: the arc sweeps -50..+50 degrees around `facing`
## at the same 68 px (34 art px) reach as the hitbox. Brightest at the leading edge.
func _swing_frame(facing: float, frame: int) -> Image:
	var size: Vector2i = Layouts.SWING["size"]
	var img: Image = _blank(size)
	var center: Vector2 = Vector2(size) / 2.0
	var lead: float = deg_to_rad(-50.0 + 100.0 * float(frame + 1) / 3.0)
	var trail: float = deg_to_rad(105.0)
	var white: Color = Color("f4f1e6")
	var light: Color = Color("c4cad6")
	var dim: Color = Color("8c94a6")
	for y: int in size.y:
		for x: int in size.x:
			var v: Vector2 = Vector2(x + 0.5, y + 0.5) - center
			var radius: float = v.length()
			var angle: float = wrapf(v.angle() - facing, -PI, PI)
			if angle > lead or angle < lead - trail or angle < deg_to_rad(-52.0):
				continue
			var t: float = (lead - angle) / trail  # 0 at the leading edge, 1 at the tail
			var thickness: float = lerpf(12.0, 3.0, t) * (0.7 if frame == 2 else 1.0)
			if radius > 34.0 or radius < 34.0 - thickness:
				continue
			var color: Color = white if t < 0.3 else (light if t < 0.65 else dim)
			# Ordered dither thins the tail, and the whole trail in the last frame.
			var fade: float = maxf(t - 0.55, 0.0) * 2.2 + (0.45 if frame == 2 else 0.0)
			if _bayer(x, y) < fade:
				continue
			img.set_pixel(x, y, color)
	return img


func _spark_sheet() -> Image:
	var size: Vector2i = Layouts.HIT_SPARK["size"]
	var frames: Array[Image] = []
	var white: Color = Color("fbf6e4")
	var yellow: Color = Color("f2c65c")
	var orange: Color = Color("d9682e")
	for frame: int in 3:
		var img: Image = _blank(size)
		var c: Vector2i = Vector2i(6, 6)
		var arm: int = [2, 4, 5][frame]
		for i: int in range(0, arm + 1):
			var color: Color = white if i <= 1 else (yellow if i < arm else orange)
			if frame == 2 and i < 3:
				continue  # the burst opens up in the last frame
			for d: Vector2i in DIRS_4:
				_px(img, c + d * i, color)
			if i <= arm - 2 and i > 0:
				for diag: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
					_px(img, c + diag * i, yellow if frame < 2 else orange)
		frames.append(img)
	return _sheet([frames], size)


func _dust_sheet() -> Image:
	var size: Vector2i = Layouts.DUST["size"]
	var frames: Array[Image] = []
	var light: Color = Color("8a8378")
	var dark: Color = Color("5e574e")
	var puffs: Array[Vector2] = [Vector2(10, 13), Vector2(6, 12), Vector2(14, 12), Vector2(8, 9), Vector2(12, 9)]
	for frame: int in 5:
		var img: Image = _blank(size)
		var grow: float = 1.5 + frame * 0.9
		for p: int in puffs.size():
			var center: Vector2 = puffs[p] + Vector2(0, -frame * 0.8) + (puffs[p] - Vector2(10, 11)) * frame * 0.25
			for y: int in size.y:
				for x: int in size.x:
					var d: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
					if d > grow:
						continue
					if _bayer(x, y) < (frame - 1) * 0.25:
						continue  # ordered-dither fade
					img.set_pixel(x, y, light if d < grow - 1.0 else dark)
		frames.append(img)
	return _sheet([frames], size)


# ---------------------------------------------------------------- fortress

func _fortress_sheet() -> Image:
	var size: Vector2i = Layouts.FORTRESS["size"]
	var base: Image = _fortress_base()
	var frames: Array[Image] = [base]
	for damage: int in [1, 2, 3]:
		var img: Image = base.duplicate() as Image
		_damage_fortress(img, damage)
		frames.append(img)
	var shadowed: Array[Image] = []
	for img: Image in frames:
		_outline(img)
		var framed: Image = _blank(size)
		_drop_shadow(framed, img, Vector2i(2, 2), Vector2i(2, 2))
		framed.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(2, 2))
		shadowed.append(framed)
	return _sheet([shadowed], size)


## The keep seen from above, 48x48 art px = the 96x96 world-pixel collision box. Light from the top-left.
func _fortress_base() -> Image:
	var img: Image = _blank(Vector2i(48, 48))
	var stone_light: Color = Color("9a96a0")
	var stone: Color = Color("76727e")
	var stone_dark: Color = Color("55515d")
	var mortar: Color = Color("3e3a46")
	var earth: Color = Color("5c4e3f")
	var earth_dark: Color = Color("4b3f33")
	var roof: Color = Color("413c4c")
	var roof_light: Color = Color("5d5870")
	var wood: Color = Color("5e3f29")
	# Courtyard (packed earth with flagstones).
	_fill_rect(img, Rect2i(5, 5, 38, 38), earth)
	for y: int in range(9, 39, 4):
		for x: int in range(9 + (y % 8), 39, 8):
			_fill_rect(img, Rect2i(x, y, 3, 2), earth_dark)
	# Curtain walls: 5 px thick, crenellated outer edge, lit top/left faces.
	for rect: Rect2i in [Rect2i(2, 2, 44, 6), Rect2i(2, 40, 44, 6), Rect2i(2, 2, 6, 44), Rect2i(40, 2, 6, 44)]:
		_fill_rect(img, rect, stone)
	for i: int in range(2, 46):
		var merlon: bool = floori(i / 3.0) % 2 == 0
		_px(img, Vector2i(i, 2), stone_light if merlon else mortar)
		_px(img, Vector2i(2, i), stone_light if merlon else mortar)
		_px(img, Vector2i(i, 45), stone_dark if merlon else mortar)
		_px(img, Vector2i(45, i), stone_dark if merlon else mortar)
		_px(img, Vector2i(i, 7), stone_dark)
		_px(img, Vector2i(7, i), stone_dark)
		_px(img, Vector2i(i, 40), stone_light)
		_px(img, Vector2i(40, i), stone_light)
	# Gate on the west wall, where the lane arrives.
	_fill_rect(img, Rect2i(2, 20, 6, 8), mortar)
	_fill_rect(img, Rect2i(3, 21, 4, 6), wood)
	for y: int in range(21, 27, 2):
		_fill_rect(img, Rect2i(3, y, 4, 1), Color("3d2a1c"))
	# Corner towers with conical slate roofs.
	for c: Vector2i in [Vector2i(7, 7), Vector2i(40, 7), Vector2i(7, 40), Vector2i(40, 40)]:
		_fill_circle(img, c, 7.2, stone)
		_fill_circle(img, c + Vector2i(-1, -1), 5.0, stone_light)
		_fill_circle(img, c, 5.0, stone)
		_fill_circle(img, c, 4.2, roof)
		_fill_circle(img, c + Vector2i(-1, -1), 2.0, roof_light)
		_px(img, c, Color("2e2a36"))
	# Central keep: stone walls and a hipped slate roof with a ridge.
	_fill_rect(img, Rect2i(15, 15, 18, 18), stone_dark)
	_fill_rect(img, Rect2i(15, 15, 17, 17), stone)
	_fill_rect(img, Rect2i(17, 17, 14, 14), roof)
	for i: int in range(0, 7):
		_px(img, Vector2i(17 + i, 17 + i), roof_light)
		_px(img, Vector2i(30 - i, 17 + i), roof_light)
		_px(img, Vector2i(17 + i, 30 - i), roof)
	_fill_rect(img, Rect2i(23, 23, 2, 2), roof_light)
	# Banner pole and the red banner (the accent colour).
	_fill_rect(img, Rect2i(24, 16, 1, 8), wood)
	_fill_rect(img, Rect2i(25, 16, 4, 3), _palette["R"])
	_px(img, Vector2i(28, 18), _palette["r"])
	_px(img, Vector2i(26, 17), _palette["y"])
	return img


## Cracks and missing merlons (1), plus a broken tower and fire (2), plus breaches and ruin (3).
func _damage_fortress(img: Image, damage: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242 + damage
	var crack: Color = Color("2a2630")
	var rubble: Color = Color("6a6570")
	for i: int in [6, 14, 24][damage - 1]:
		var p: Vector2i = Vector2i(rng.randi_range(3, 44), rng.randi_range(3, 44))
		if img.get_pixelv(p).a == 0.0:
			continue
		for step: int in rng.randi_range(2, 4):
			_px(img, p, crack)
			p += Vector2i(rng.randi_range(-1, 1), 1)
	for i: int in [4, 8, 16][damage - 1]:
		var x: int = rng.randi_range(3, 44)
		_px(img, Vector2i(x, 2), Color(0, 0, 0, 0))
		_px(img, Vector2i(2, x), Color(0, 0, 0, 0))
	if damage >= 2:
		# North-east tower top broken off, small fire on the keep roof.
		_fill_circle(img, Vector2i(40, 7), 4.2, rubble)
		for p: Vector2i in [Vector2i(39, 6), Vector2i(41, 8), Vector2i(40, 5), Vector2i(38, 8)]:
			_px(img, p, crack)
		for p: Vector2i in [Vector2i(20, 21), Vector2i(21, 20), Vector2i(21, 21), Vector2i(20, 22)]:
			_px(img, p, Color("e0782e"))
		_px(img, Vector2i(21, 19), Color("f2c65c"))
	if damage >= 3:
		# Breaches in the walls, the keep caved in, the banner gone, everything scorched.
		for rect: Rect2i in [Rect2i(18, 2, 6, 6), Rect2i(40, 26, 6, 7), Rect2i(10, 40, 7, 6)]:
			_fill_rect(img, rect, Color(0, 0, 0, 0))
			for i: int in 7:
				_px(img, rect.position + Vector2i(rng.randi_range(0, rect.size.x - 1), rng.randi_range(0, rect.size.y - 1)), rubble)
		_fill_rect(img, Rect2i(17, 17, 14, 14), Color("2c2832"))
		for i: int in 30:
			_px(img, Vector2i(rng.randi_range(17, 30), rng.randi_range(15, 30)), rubble if i % 2 == 0 else crack)
		_tint(img, Color("1a141f"), 0.3)


# ---------------------------------------------------------------- arena ground

## Bakes the prototype arena's floor: dark grass, the dirt lane read from the level's Path2D,
## a clearing around the fortress, scattered details, and a stone wall band around the arena.
func _ground() -> Image:
	var level: Node = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	var floor_node: ColorRect = level.get_node("Floor")
	var lane: Path2D = level.get_node("Lane")
	var fortress_pos: Vector2 = (level.get_node("Fortress") as Node2D).position
	var band: int = Layouts.WALL_BAND
	var scale: float = float(Layouts.ART_SCALE)
	var origin: Vector2 = floor_node.position - Vector2(band, band)
	var size: Vector2i = Vector2i(((floor_node.size + Vector2(band, band) * 2.0) / scale).round())
	var floor_art: Rect2i = Rect2i(Vector2i(int(band / scale), int(band / scale)), Vector2i((floor_node.size / scale).round()))
	var lane_points: Array[Vector2] = []
	for i: int in lane.curve.point_count:
		lane_points.append((lane.to_global(lane.curve.get_point_position(i)) - origin) / scale)
	var spawn: Vector2 = lane_points[0]
	var keep: Vector2 = (fortress_pos - origin) / scale
	level.free()

	var img: Image = _blank(size)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.13
	var patches: FastNoiseLite = FastNoiseLite.new()
	patches.seed = 19
	patches.frequency = 0.018
	var grass: Array[Color] = [Color("263820"), Color("2a3d23"), Color("2e4327"), Color("34492c")]
	var dry: Array[Color] = [Color("3c3d25"), Color("47462b")]
	var dirt: Array[Color] = [Color("4a3a2c"), Color("524131"), Color("5c4937")]
	var dirt_edge: Color = Color("3f2f21")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234

	# Grass, dry patches, the lane and the clearing.
	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var n: float = noise.get_noise_2d(x, y)
			var jitter: float = noise.get_noise_2d(x * 3.0, y * 3.0) * 1.6
			var lane_d: float = _distance_to_polyline(p, lane_points) + jitter
			var clearing_d: float = p.distance_to(keep) - 33.0 + jitter * 2.0
			var path_d: float = minf(lane_d - 8.0, clearing_d)
			var color: Color
			if path_d < -1.0:
				color = dirt[clampi(int((n + 1.0) * 1.5), 0, 2)]
				if rng.randf() < 0.012:
					color = Color("7a6a58")  # pebble
			elif path_d < 0.5:
				color = dirt_edge
			elif patches.get_noise_2d(x, y) > 0.35:
				color = dry[1 if n > 0.1 else 0]
			else:
				var shade: int = clampi(int((n + 0.7) * 2.2), 0, 3)
				if (x + y) % 2 == 0 and shade < 3 and noise.get_noise_2d(y, x) > 0.45:
					shade += 1  # sparse dither keeps the grass lively but low-contrast
				color = grass[shade]
			img.set_pixel(x, y, color)

	# Details on grass only, never on the lane, the clearing or right at the walls.
	var keep_out: Callable = func(p: Vector2) -> bool:
		return (_distance_to_polyline(p, lane_points) < 12.0 or p.distance_to(keep) < 40.0
			or not Rect2(floor_art).grow(-4).has_point(p))
	for i: int in 2200:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var is_dry: bool = patches.get_noise_2d(p.x, p.y) > 0.3
		var blade: Color = (Color("6f6941") if is_dry else Color("44633b")) if rng.randf() < 0.65 else Color("1d2b18")
		var tip: Vector2i = Vector2i(p)
		_px(img, tip, blade)
		_px(img, tip + Vector2i(-1, 1), blade)
		_px(img, tip + Vector2i(1, 1), blade)
	for i: int in 55:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not keep_out.call(p):
			_stone(img, Vector2i(p), rng.randi_range(1, 2))
	for i: int in 26:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)][rng.randi_range(0, 2)]
		for step: int in rng.randi_range(3, 5):
			_px(img, Vector2i(p) + dir * step, Color("4e3a28"))
	for i: int in 12:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var bone: Color = Color("cfc7ae")
		_px(img, Vector2i(p), bone)
		_px(img, Vector2i(p) + Vector2i(1, 0), bone)
		_px(img, Vector2i(p) + Vector2i(2, 0), bone)
		_px(img, Vector2i(p) + Vector2i(-1, -1), bone)
		_px(img, Vector2i(p) + Vector2i(3, 1), bone)

	# A small graveyard where the dead rise (the lane start).
	for offset: Vector2i in [Vector2i(-14, -14), Vector2i(-4, -17), Vector2i(10, -15), Vector2i(-16, 11), Vector2i(8, 13)]:
		_tombstone(img, Vector2i(spawn) + offset)

	_wall_band(img, floor_art)
	return img


## A small, flat, muted stone: dark base, mid face, one lit pixel. Never brighter than the characters.
func _stone(img: Image, at: Vector2i, radius: int) -> void:
	_fill_rect(img, Rect2i(at + Vector2i(-radius, 0), Vector2i(radius * 2 + 1, radius + 1)), Color("1f2a1a"))
	_fill_rect(img, Rect2i(at + Vector2i(-radius, -1), Vector2i(radius * 2 + 1, radius + 1)), Color("4c4a52"))
	_fill_rect(img, Rect2i(at + Vector2i(-radius + 1, -1), Vector2i(radius * 2 - 1, 1)), Color("5f5c66"))
	_px(img, at + Vector2i(-radius + 1, -1), Color("75727c"))


func _tombstone(img: Image, at: Vector2i) -> void:
	_fill_rect(img, Rect2i(at + Vector2i(1, 1), Vector2i(6, 8)), Color("1b2216"))
	_fill_rect(img, Rect2i(at, Vector2i(6, 8)), Color("6a6672"))
	_fill_rect(img, Rect2i(at + Vector2i(1, 0), Vector2i(4, 1)), Color("8a8692"))
	_px(img, at, Color(0, 0, 0, 0))
	_px(img, at + Vector2i(5, 0), Color(0, 0, 0, 0))
	_fill_rect(img, Rect2i(at + Vector2i(2, 2), Vector2i(2, 4)), Color("45414d"))
	_fill_rect(img, Rect2i(at + Vector2i(1, 3), Vector2i(4, 1)), Color("45414d"))
	_fill_rect(img, Rect2i(at + Vector2i(0, 7), Vector2i(6, 1)), Color("4d4955"))


## Stone blocks around the playable floor, battlements along the inner edge, and a soft
## shadow on the grass just inside, so the boundary reads clearly.
func _wall_band(img: Image, floor_art: Rect2i) -> void:
	var size: Vector2i = img.get_size()
	var block: Array[Color] = [Color("5a5662"), Color("64606c"), Color("6e6a76")]
	var mortar: Color = Color("37333f")
	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2i = Vector2i(x, y)
			if floor_art.has_point(p):
				var edge: int = mini(mini(x - floor_art.position.x, floor_art.end.x - 1 - x),
					mini(y - floor_art.position.y, floor_art.end.y - 1 - y))
				if edge < 3:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.45 - edge * 0.12))
				continue
			var row: int = floori(y / 5.0)
			var col: int = floori((x + (row % 2) * 4) / 8.0)
			var is_mortar: bool = y % 5 == 4 or (x + (row % 2) * 4) % 8 == 7
			var color: Color = mortar if is_mortar else block[(row * 7 + col * 3) % 3]
			# Merlons on the band's inner rim.
			# Distance to the floor, measured only across this side of the band (so corners stay clean).
			var rim: int
			var along: int
			if y < floor_art.position.y:
				rim = floor_art.position.y - 1 - y
				along = x
			elif y >= floor_art.end.y:
				rim = y - floor_art.end.y
				along = x
			elif x < floor_art.position.x:
				rim = floor_art.position.x - 1 - x
				along = y
			else:
				rim = x - floor_art.end.x
				along = y
			if rim <= 2:
				color = Color("8a8692") if floori(along / 3.0) % 2 == 0 else Color("4a4652")
			img.set_pixel(x, y, color)


func _distance_to_polyline(p: Vector2, points: Array[Vector2]) -> float:
	var best: float = INF
	for i: int in points.size() - 1:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		best = minf(best, p.distance_to(closest))
	return best


# ---------------------------------------------------------------- image helpers

func _blank(size: Vector2i) -> Image:
	return Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)


func _px(img: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, color)


func _paste(img: Image, grid: Array, at: Vector2i) -> void:
	for y: int in grid.size():
		var row: String = grid[y]
		for x: int in row.length():
			var key: String = row[x]
			if key != ".":
				_px(img, at + Vector2i(x, y), _palette[key])


func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_px(img, Vector2i(x, y), color)


func _fill_circle(img: Image, center: Vector2i, radius: float, color: Color) -> void:
	var r: int = ceili(radius)
	for y: int in range(-r, r + 1):
		for x: int in range(-r, r + 1):
			if Vector2(x, y).length() <= radius:
				_px(img, center + Vector2i(x, y), color)


## Adds a 1 px dark outline around every opaque shape (4-neighbour), giving strong silhouettes.
func _outline(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in img.get_height():
		for x: int in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in DIRS_4:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixelv(q).a > 0.5:
					img.set_pixel(x, y, _outline_color)
					break


## Outline, then a soft oval shadow under the feet (drawn only where nothing else is).
func _finish_character(img: Image, feet: Vector2i) -> Image:
	_outline(img)
	for y: int in range(-1, 2):
		for x: int in range(-5, 6):
			var p: Vector2i = feet + Vector2i(x, y)
			if absf(x) / 5.5 + absf(y) / 1.6 <= 1.0 and img.get_pixelv(p).a == 0.0:
				img.set_pixelv(p, _shadow_color)
	return img


func _drop_shadow(dst: Image, src: Image, at: Vector2i, offset: Vector2i) -> void:
	for y: int in src.get_height():
		for x: int in src.get_width():
			if src.get_pixel(x, y).a > 0.5:
				_px(dst, at + offset + Vector2i(x, y), _shadow_color)


func _tint(img: Image, color: Color, amount: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(c.lerp(color, amount), c.a))


## 4x4 ordered-dither threshold in [0, 1): the classic retro way to fade pixel art without blur.
func _bayer(x: int, y: int) -> float:
	const MATRIX: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	return MATRIX[(y % 4) * 4 + x % 4] / 16.0


func _dither_out(img: Image, phase: int) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			if (x + y + phase) % 2 == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Lays out rows of equally sized frames into one sheet.
func _sheet(rows: Array, frame_size: Vector2i) -> Image:
	var columns: int = 0
	for row: Array in rows:
		columns = maxi(columns, row.size())
	var sheet: Image = _blank(Vector2i(frame_size.x * columns, frame_size.y * rows.size()))
	for r: int in rows.size():
		var row: Array = rows[r]
		for c: int in row.size():
			var frame: Image = row[c]
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(c * frame_size.x, r * frame_size.y))
	return sheet


func _save(img: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	print("%s %s (%dx%d)" % ["saved" if err == OK else "FAILED", path, img.get_width(), img.get_height()])

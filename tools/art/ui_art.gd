extends RefCounted
## UI art (dev-time art generator): an original pixel font with a baked-in dark outline, framed
## panels and buttons, health-bar frames and fills, and small HUD icons.
## Textures are written at 2x (each art pixel = 2x2 texels) because StyleBoxTexture and TextureRect
## draw texels 1:1; the font is a bitmap font that the theme draws at an exact multiple of its size.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

## Rows of a glyph: 0-6 = cap height (row 6 sits on the baseline), 7-8 = descender.
const GLYPH_ROWS: int = 9
## Font cell: 1 px outline + 9 rows + 1 px outline + 1 px line gap.
const FONT_HEIGHT: int = 12
const FONT_ASCENT: int = 9
const FONT_DESCENT: int = 3

## "#" = pixel. Rows separated by "|"; missing rows are empty. Every row of a glyph has the same width.
const GLYPHS: Dictionary = {
	"A": ".###.|#...#|#...#|#####|#...#|#...#|#...#", "B": "####.|#...#|#...#|####.|#...#|#...#|####.",
	"C": ".###.|#...#|#....|#....|#....|#...#|.###.", "D": "####.|#...#|#...#|#...#|#...#|#...#|####.",
	"E": "#####|#....|#....|####.|#....|#....|#####", "F": "#####|#....|#....|####.|#....|#....|#....",
	"G": ".###.|#...#|#....|#.###|#...#|#...#|.####", "H": "#...#|#...#|#...#|#####|#...#|#...#|#...#",
	"I": "###|.#.|.#.|.#.|.#.|.#.|###", "J": "..###|...#.|...#.|...#.|#..#.|#..#.|.##..",
	"K": "#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#", "L": "#....|#....|#....|#....|#....|#....|#####",
	"M": "#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#", "N": "#...#|##..#|#.#.#|#..##|#...#|#...#|#...#",
	"O": ".###.|#...#|#...#|#...#|#...#|#...#|.###.", "P": "####.|#...#|#...#|####.|#....|#....|#....",
	"Q": ".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#", "R": "####.|#...#|#...#|####.|#.#..|#..#.|#...#",
	"S": ".###.|#...#|#....|.###.|....#|#...#|.###.", "T": "#####|..#..|..#..|..#..|..#..|..#..|..#..",
	"U": "#...#|#...#|#...#|#...#|#...#|#...#|.###.", "V": "#...#|#...#|#...#|#...#|#...#|.#.#.|..#..",
	"W": "#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#", "X": "#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
	"Y": "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..", "Z": "#####|....#|...#.|..#..|.#...|#....|#####",
	"a": "....|....|.###|...#|.###|#..#|.###", "b": "#...|#...|###.|#..#|#..#|#..#|###.",
	"c": "....|....|.###|#...|#...|#...|.###", "d": "...#|...#|.###|#..#|#..#|#..#|.###",
	"e": "....|....|.##.|#..#|####|#...|.###", "f": "..#|.#.|###|.#.|.#.|.#.|.#.",
	"g": "....|....|.###|#..#|#..#|#..#|.###|...#|.##.", "h": "#...|#...|###.|#..#|#..#|#..#|#..#",
	"i": "#|.|#|#|#|#|#", "j": "..#|...|.##|..#|..#|..#|..#|#.#|.#.",
	"k": "#...|#...|#..#|#.#.|##..|#.#.|#..#", "l": "#.|#.|#.|#.|#.|#.|.#",
	"m": ".....|.....|####.|#.#.#|#.#.#|#.#.#|#.#.#", "n": "....|....|###.|#..#|#..#|#..#|#..#",
	"o": "....|....|.##.|#..#|#..#|#..#|.##.", "p": "....|....|###.|#..#|#..#|#..#|###.|#...|#...",
	"q": "....|....|.###|#..#|#..#|#..#|.###|...#|...#", "r": "...|...|#.#|##.|#..|#..|#..",
	"s": "....|....|.###|#...|.##.|...#|###.", "t": ".#.|.#.|###|.#.|.#.|.#.|..#",
	"u": "....|....|#..#|#..#|#..#|#..#|.###", "v": ".....|.....|#...#|#...#|#...#|.#.#.|..#..",
	"w": ".....|.....|#...#|#...#|#.#.#|#.#.#|.#.#.", "x": "....|....|#..#|#..#|.##.|#..#|#..#",
	"y": "....|....|#..#|#..#|#..#|#..#|.###|...#|.##.", "z": "....|....|####|...#|.##.|#...|####",
	"0": ".###.|#...#|#..##|#.#.#|##..#|#...#|.###.", "1": "..#..|.##..|..#..|..#..|..#..|..#..|.###.",
	"2": ".###.|#...#|....#|...#.|..#..|.#...|#####", "3": "####.|....#|....#|.###.|....#|....#|####.",
	"4": "...#.|..##.|.#.#.|#..#.|#####|...#.|...#.", "5": "#####|#....|####.|....#|....#|#...#|.###.",
	"6": ".###.|#....|#....|####.|#...#|#...#|.###.", "7": "#####|....#|...#.|..#..|.#...|.#...|.#...",
	"8": ".###.|#...#|#...#|.###.|#...#|#...#|.###.", "9": ".###.|#...#|#...#|.####|....#|....#|.###.",
	" ": "...", "!": "#|#|#|#|#|.|#", "\"": "#.#|#.#", "'": "#|#", "#": ".#.#.|.#.#.|#####|.#.#.|#####|.#.#.|.#.#.",
	"%": "##..#|##.#.|...#.|..#..|.#...|.#.##|#..##", "&": ".##..|#..#.|.##..|.#...|#.#.#|#..#.|.##.#",
	"(": ".#|#.|#.|#.|#.|#.|.#", ")": "#.|.#|.#|.#|.#|.#|#.", "*": "...|...|#.#|.#.|#.#",
	"+": ".....|.....|..#..|..#..|#####|..#..|..#..", ",": "..|..|..|..|..|.#|.#|#.", "-": "...|...|...|...|###",
	".": ".|.|.|.|.|.|#", "/": "....#|...#.|...#.|..#..|.#...|.#...|#....", ":": ".|.|#|.|.|.|#",
	";": "..|..|.#|..|..|.#|.#|#.", "<": "...#|..#.|.#..|#...|.#..|..#.|...#", "=": "....|....|####|....|####",
	">": "#...|.#..|..#.|...#|..#.|.#..|#...", "?": ".###.|#...#|....#|...#.|..#..|.....|..#..",
	"@": ".###.|#...#|#.###|#.#.#|#.###|#....|.###.", "[": "##|#.|#.|#.|#.|#.|##", "]": "##|.#|.#|.#|.#|.#|##",
	"_": "....|....|....|....|....|....|....|####", "$": "..#..|.####|#.#..|.###.|..#.#|####.|..#..",
	"|": "#|#|#|#|#|#|#|#|#", "^": ".#.|#.#",
}


# ---------------------------------------------------------------- font

## The atlas image (white glyphs with a dark outline) and per-glyph placement.
func build_font(atlas_path: String) -> FontFile:
	var keys: Array = GLYPHS.keys()
	var cell_w: int = 9
	var columns: int = 16
	var rows: int = ceili(keys.size() / float(columns))
	var atlas: Image = Image.create_empty(columns * cell_w, rows * FONT_HEIGHT, false, Image.FORMAT_RGBA8)
	var font: FontFile = FontFile.new()
	font.fixed_size = FONT_HEIGHT
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	var size: Vector2i = Vector2i(FONT_HEIGHT, 0)
	font.set_cache_ascent(0, FONT_HEIGHT, FONT_ASCENT)
	font.set_cache_descent(0, FONT_HEIGHT, FONT_DESCENT)
	for i: int in keys.size():
		var ch: String = keys[i]
		var glyph_rows: PackedStringArray = (GLYPHS[ch] as String).split("|")
		var width: int = glyph_rows[0].length()
		var cell: Vector2i = Vector2i((i % columns) * cell_w, floori(i / float(columns)) * FONT_HEIGHT)
		var glyph: Image = _glyph_image(glyph_rows, width)
		atlas.blit_rect(glyph, Rect2i(Vector2i.ZERO, glyph.get_size()), cell)
		var code: int = ch.unicode_at(0)
		font.set_glyph_advance(0, FONT_HEIGHT, code, Vector2(width + 1, 0))
		font.set_glyph_offset(0, size, code, Vector2(-1, -FONT_ASCENT))
		font.set_glyph_size(0, size, code, Vector2(glyph.get_size()))
		font.set_glyph_uv_rect(0, size, code, Rect2(Vector2(cell), Vector2(glyph.get_size())))
		font.set_glyph_texture_idx(0, size, code, 0)
	atlas.save_png(ProjectSettings.globalize_path(atlas_path))
	font.set_texture_image(0, size, 0, atlas)
	return font


## A glyph with its 1 px outline: (width + 2) x (GLYPH_ROWS + 2). The fill is white so the label's
## font colour tints it; the outline stays dark whatever the colour.
func _glyph_image(rows: PackedStringArray, width: int) -> Image:
	var img: Image = Image.create_empty(width + 2, GLYPH_ROWS + 2, false, Image.FORMAT_RGBA8)
	for y: int in rows.size():
		for x: int in rows[y].length():
			if rows[y][x] == "#":
				img.set_pixel(x + 1, y + 1, Color.WHITE)
	var src: Image = img.duplicate() as Image
	for y: int in img.get_height():
		for x: int in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in Canvas.DIRS_8:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, Color(P.OUTLINE, 0.9))
					break
	return img


# ---------------------------------------------------------------- frames and bars

## A 9-slice panel (art 16x16, saved at 2x): bevelled gold-bronze rim with corner rivets, dark interior.
func panel(rim: Array, fill: Color, rivets: bool) -> Image:
	var size: int = 16
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var edge: int = mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var color: Color = fill
			match edge:
				0:
					color = P.OUTLINE
				1:
					color = rim[3] if (x <= y and x + y < size) or y == 1 else rim[1]  # lit top-left, dark bottom-right
					if y == 1 or x == 1:
						color = rim[3]
					if y == size - 2 or x == size - 2:
						color = rim[1]
				2:
					color = rim[2]
				3:
					color = P.OUTLINE.lerp(fill, 0.5)
			img.set_pixel(x, y, color)
	if rivets:
		for c: Vector2i in [Vector2i(2, 2), Vector2i(size - 3, 2), Vector2i(2, size - 3), Vector2i(size - 3, size - 3)]:
			img.set_pixel(c.x, c.y, rim[4])
	return _x2(img)


## Health bar frame (art 12x6 at 2x, 9-slice): dark trough with a bronze rim.
func bar_frame() -> Image:
	var img: Image = Image.create_empty(12, 6, false, Image.FORMAT_RGBA8)
	for y: int in 6:
		for x: int in 12:
			var edge: int = mini(mini(x, y), mini(11 - x, 5 - y))
			var color: Color = Color("120e16")
			if edge == 0:
				color = P.OUTLINE
			elif edge == 1:
				color = P.GOLD[1] if y > 1 and x > 1 else P.GOLD[2]
			img.set_pixel(x, y, color)
	return _x2(img)


## Bar fill (art 4x4 at 2x, stretched): a lit top row, the body, a darker bottom row.
func bar_fill(ramp: Array) -> Image:
	var img: Image = Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	for y: int in 4:
		for x: int in 4:
			img.set_pixel(x, y, [ramp[3], ramp[2], ramp[2], ramp[1]][y])
	return _x2(img)


# ---------------------------------------------------------------- icons

## 10x10 art icons (saved at 2x): coin, keep, helm, skull, foundation.
func icon(kind: String) -> Image:
	var c: Canvas = Canvas.new(10, 10)
	match kind:
		"coin":
			c.part()
			c.ellipse(Vector2(5, 5), Vector2(4.2, 4.2), P.GOLD, 0.0, 0.1)
			c.rect(Rect2i(4, 3, 2, 4), P.GOLD[1])
			c.px(4, 3, P.GOLD[4])
		"keep":
			c.part()
			c.block(Rect2(2, 3, 6, 1), 5.0, P.STONE.slice(3, 7), P.STONE.slice(2, 6), false)
			for x: int in [2, 4, 6]:
				c.rect(Rect2i(x, 2, 1, 1), P.STONE[5])
			c.rect(Rect2i(4, 6, 2, 3), P.WOOD[1])
			c.px(5, 0, P.BANNER[3])
			c.px(5, 1, P.WOOD[2])
		"helm":
			c.part()
			c.ellipse(Vector2(5, 5.5), Vector2(3.6, 3.8), P.STEEL)
			c.rect(Rect2i(3, 5, 5, 1), P.OUTLINE)
			c.part()
			c.ellipse(Vector2(5, 1.6), Vector2(1.3, 1.4), P.TABARD, 0.0, 0.1)
		"skull":
			c.part()
			c.ellipse(Vector2(5, 4.5), Vector2(3.6, 3.4), P.BONE)
			c.rect(Rect2i(3, 6, 4, 2), P.BONE[2])
			c.px(3, 4, P.OUTLINE)
			c.px(4, 4, P.EYE_GLOW[2])
			c.px(6, 4, P.EYE_GLOW[2])
			c.px(7, 4, P.OUTLINE)
			c.px(4, 7, P.BONE[0])
			c.px(6, 7, P.BONE[0])
		"slot":
			c.part()
			c.cylinder(5, 5, 6, 4.4, 2.4, P.STONE, P.STONE.slice(2, 6))
			c.px(5, 3, P.GOLD[3])
	c.finish()
	return _x2(c.image)


func _x2(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return out

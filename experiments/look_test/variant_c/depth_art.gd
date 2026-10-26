class_name LookDepthArt
extends RefCounted
## The pictures variant C draws for its fake depth (look-test): a blurred dark foreground strip (grass, gravestones,
## crosses, dead branches) and three parallax backdrop layers (far hills, ruins, a treeline). All made in code from
## a fixed seed, as seamless horizontal strips that repeat; backdrop strips are drawn at 1 art px = 2 world px.

const FOREGROUND_SIZE: Vector2i = Vector2i(1024, 130)
const STRIP_WIDTH: int = 512
const FOREGROUND_COLOR: Color = Color(0.012, 0.018, 0.028, 1.0)


static func foreground() -> Texture2D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	var image: Image = Image.create_empty(FOREGROUND_SIZE.x, FOREGROUND_SIZE.y, false, Image.FORMAT_RGBA8)
	var width: int = FOREGROUND_SIZE.x
	var height: int = FOREGROUND_SIZE.y
	# Grass blades: thin bent triangles of random height.
	for x: int in range(0, width, 4):
		var blade_height: int = rng.randi_range(18, 46) if rng.randf() < 0.75 else rng.randi_range(56, 92)
		var bend: float = rng.randf_range(-0.35, 0.35)
		for row: int in blade_height:
			var t: float = float(row) / blade_height
			var half: int = maxi(int(round(2.5 * (1.0 - t))), 0)
			var cx: int = x + int(round(bend * row))
			for dx: int in range(-half, half + 1):
				_put(image, cx + dx, height - 1 - row)
	# Gravestones: a rounded slab, now and then a cross.
	for i: int in 6:
		var gx: int = int(width / 6.0 * i) + rng.randi_range(0, 90)
		var gw: int = rng.randi_range(36, 54)
		var gh: int = rng.randi_range(70, 108)
		_slab(image, gx, gw, gh, rng.randf() < 0.4)
	# Dead branches rising from the edges with a few forks.
	for i: int in 4:
		_branch(image, int(width / 4.0 * i) + rng.randi_range(20, 120), height - 1, rng.randf_range(-0.9, 0.9), rng.randi_range(60, 104), rng)
	var soft: Image = image.duplicate() as Image
	soft.resize(int(width / 3.0), int(height / 3.0), Image.INTERPOLATE_BILINEAR)
	soft.resize(width, height, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(soft)


## One backdrop strip: "hills", "ruins" or "trees", `STRIP_WIDTH` art px wide, drawn from the bottom up.
static func strip(kind: String, color: Color, art_height: int) -> Texture2D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var image: Image = Image.create_empty(STRIP_WIDTH, art_height, false, Image.FORMAT_RGBA8)
	match kind:
		"hills":
			_hills(image, color, rng)
		"ruins":
			_ruins(image, color, rng)
		_:
			_trees(image, color, rng)
	return ImageTexture.create_from_image(image)


static func _put(image: Image, x: int, y: int, color: Color = FOREGROUND_COLOR) -> void:
	if y < 0 or y >= image.get_height():
		return
	image.set_pixel(posmod(x, image.get_width()), y, color)


@warning_ignore("integer_division")
static func _slab(image: Image, x: int, width: int, height: int, cross: bool) -> void:
	var bottom: int = image.get_height() - 1
	if cross:
		var cx: int = x + width / 2
		for row: int in height:
			for dx: int in range(-3, 4):
				_put(image, cx + dx, bottom - row)
		for row: int in range(int(height * 0.6), int(height * 0.6) + 9):
			for dx: int in range(-width / 2, width / 2):
				_put(image, cx + dx, bottom - row)
		return
	for row: int in height:
		var inset: int = 0
		var from_top: int = height - 1 - row
		if from_top < width / 2:
			inset = width / 2 - int(sqrt(maxf(float(width * width) / 4.0 - pow(width / 2.0 - from_top, 2.0), 0.0)))
		for dx: int in range(inset, width - inset):
			_put(image, x + dx, bottom - row)


static func _branch(image: Image, x: int, y: int, lean: float, length: int, rng: RandomNumberGenerator) -> void:
	var p: Vector2 = Vector2(x, y)
	var direction: Vector2 = Vector2(lean, -1.0).normalized()
	for i: int in length:
		p += direction
		_put(image, int(p.x), int(p.y))
		_put(image, int(p.x) + 1, int(p.y))
		if i > length * 0.35 and i % 11 == 0:
			var fork: Vector2 = direction.rotated(rng.randf_range(-1.0, 1.0))
			var q: Vector2 = p
			for j: int in rng.randi_range(8, 20):
				q += fork
				_put(image, int(q.x), int(q.y))
		direction = direction.rotated(rng.randf_range(-0.12, 0.12))


static func _hills(image: Image, color: Color, rng: RandomNumberGenerator) -> void:
	var height: int = image.get_height()
	var phase_a: float = rng.randf() * TAU
	var phase_b: float = rng.randf() * TAU
	for x: int in image.get_width():
		var t: float = float(x) / image.get_width() * TAU
		var top: float = height * (0.45 + 0.18 * sin(t * 2.0 + phase_a) + 0.1 * sin(t * 5.0 + phase_b) + 0.05 * sin(t * 11.0))
		for y: int in range(int(top), height):
			image.set_pixel(x, y, color)


@warning_ignore("integer_division")
static func _ruins(image: Image, color: Color, rng: RandomNumberGenerator) -> void:
	var height: int = image.get_height()
	var width: int = image.get_width()
	var x: int = 0
	while x < width:
		var kind: int = rng.randi_range(0, 3)
		var w: int = rng.randi_range(18, 40)
		var h: int = rng.randi_range(int(height * 0.35), int(height * 0.95))
		match kind:
			0:  # a broken tower with crenellations
				for dx: int in w:
					var top: int = height - h + (6 if (dx / 5) % 2 == 0 else 0)
					for y: int in range(top, height):
						image.set_pixel((x + dx) % width, y, color)
			1:  # an arch: two piers and a ring
				for dx: int in w + 14:
					for y: int in range(height - h, height):
						var cx: float = (w + 14) * 0.5
						var inside: bool = dx > 6 and dx < w + 8 and Vector2((dx - cx) / (w * 0.5), (y - (height - h * 0.5)) / (h * 0.45)).length() < 1.0
						if not inside:
							image.set_pixel((x + dx) % width, y, color)
				w += 14
			2:  # a lone column stump
				for dx: int in range(4, w - 4):
					for y: int in range(height - int(h * 0.6), height):
						image.set_pixel((x + dx) % width, y, color)
			_:  # a ragged wall
				for dx: int in w:
					var top: int = height - int(h * (0.5 + 0.5 * rng.randf()))
					for y: int in range(top, height):
						image.set_pixel((x + dx) % width, y, color)
		x += w + rng.randi_range(10, 60)
	for y: int in range(height - 6, height):  # a ground line under everything
		for xx: int in width:
			image.set_pixel(xx, y, color)


@warning_ignore("integer_division")
static func _trees(image: Image, color: Color, rng: RandomNumberGenerator) -> void:
	var height: int = image.get_height()
	var width: int = image.get_width()
	var x: int = 0
	while x < width:
		var h: int = rng.randi_range(int(height * 0.5), height - 2)
		var w: int = rng.randi_range(14, 26)
		if rng.randf() < 0.65:  # a pine: stacked triangles
			var tiers: int = 4
			for tier: int in tiers:
				var tier_top: int = height - h + tier * int(h / float(tiers + 1))
				var tier_height: int = int(h / float(tiers)) + 4
				for row: int in tier_height:
					var half: int = int((row + 1) * (w * 0.5) / tier_height) + tier
					for dx: int in range(-half, half + 1):
						var y: int = tier_top + row
						if y < height:
							image.set_pixel(posmod(x + w / 2 + dx, width), y, color)
		else:  # a dead tree: trunk and a few boughs
			for y: int in range(height - h, height):
				for dx: int in range(0, 3):
					image.set_pixel(posmod(x + w / 2 + dx, width), y, color)
			for bough: int in 3:
				var p: Vector2 = Vector2(x + w / 2, height - h * (0.4 + 0.2 * bough))
				var d: Vector2 = Vector2(-1.0 if bough % 2 == 0 else 1.0, -0.6)
				for i: int in rng.randi_range(8, 16):
					p += d
					if int(p.y) >= 0:
						image.set_pixel(posmod(int(p.x), width), int(p.y), color)
		x += w + rng.randi_range(-4, 14)
	for y: int in range(height - 3, height):
		for xx: int in width:
			image.set_pixel(xx, y, color)

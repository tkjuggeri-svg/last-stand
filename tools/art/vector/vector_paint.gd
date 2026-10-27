class_name VectorPaint
## Painterly shading for the vector test (branch vector-test, never merge), the step past flat gradients: every
## shape gets a base gradient, a cool shadow band on the side away from the light, a warm highlight band toward it,
## a cold moonlight rim on the far edge and a dark outline. Bands are the shape minus itself shifted
## (Geometry2D.clip_polygons), so they follow any outline. Plus detail helpers (curves, rivets, strands, noise).

const SHADOW_TINT: Color = Color("2a2552")
const LIGHT_TINT: Color = Color("ffe2a8")
const MOON_RIM: Color = Color("a8d8ff")
const MIN_AREA: float = 0.6


static func shadow_of(c: Color, amount: float = 0.42) -> Color:
	return c.darkened(amount).lerp(SHADOW_TINT, 0.3)


static func light_of(c: Color, amount: float = 0.32) -> Color:
	return c.lightened(amount).lerp(LIGHT_TINT, 0.22)


static func moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		out.append(p + by)
	return out


static func area(points: PackedVector2Array) -> float:
	var sum: float = 0.0
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5


static func fill(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 3 and area(points) > MIN_AREA:
		if Geometry2D.triangulate_polygon(points).is_empty():
			_bad(points)
			return
		ci.draw_colored_polygon(points, color)


## Set by the bake tool to list the shapes a painter drew badly (self-intersecting: they are skipped).
static var report_bad: bool = false


static func _bad(points: PackedVector2Array) -> void:
	if report_bad:
		print("bad polygon at ", points[0], " (", points.size(), " points)")


## `points` minus `points` shifted by `by`: a band along the edge facing away from `by`.
static func band(ci: CanvasItem, points: PackedVector2Array, by: Vector2, color: Color) -> void:
	var outer: bool = Geometry2D.is_polygon_clockwise(points)
	for piece: PackedVector2Array in Geometry2D.clip_polygons(points, moved(points, by)):
		if Geometry2D.is_polygon_clockwise(piece) == outer:
			fill(ci, piece, color)


## The full painted shape. `depth` is the shadow band's width; `rim` the moonlight's strength (0 = none).
static func painted(ci: CanvasItem, points: PackedVector2Array, base: Color, depth: float = 3.0, rim: float = 0.55, outline: float = 1.2) -> void:
	if points.size() < 3 or area(points) <= MIN_AREA:
		return
	if Geometry2D.triangulate_polygon(points).is_empty():
		_bad(points)
		return
	# The bands scale with the shape (a third of its smaller side at least), or small parts look flat.
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		bounds = bounds.expand(p)
	depth = maxf(depth, minf(bounds.size.x, bounds.size.y) * 0.32)
	VectorStyle.shape(ci, points, base.lightened(0.1), base.darkened(0.18), Color(0, 0, 0, 0))
	var toward: Vector2 = VectorStyle.LIGHT_DIR
	band(ci, points, toward * depth, Color(shadow_of(base), 0.85))
	band(ci, points, -toward * depth * 0.7, Color(light_of(base), 0.75))
	band(ci, points, -toward * depth * 0.25, Color(light_of(base, 0.55), 0.6))
	if rim > 0.0:
		band(ci, points, toward * 1.1, Color(MOON_RIM, rim))
	if outline > 0.0:
		var closed: PackedVector2Array = points.duplicate()
		closed.append(points[0])
		ci.draw_polyline(closed, VectorStyle.INK, outline, true)


## Points along a quadratic curve a -> b bent toward `ctrl`.
static func curve(a: Vector2, ctrl: Vector2, b: Vector2, steps: int = 10) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in steps + 1:
		var t: float = float(i) / steps
		out.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return out


## A tapered stroke along a curve (hair, plume strands, sinew, cloth folds): wide at `a`, thin at `b`.
static func strand(ci: CanvasItem, a: Vector2, ctrl: Vector2, b: Vector2, width: float, color: Color) -> void:
	var spine: PackedVector2Array = curve(a, ctrl, b, 8)
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for i: int in spine.size():
		var j: int = mini(i + 1, spine.size() - 1)
		var k: int = maxi(i - 1, 0)
		var n: Vector2 = (spine[j] - spine[k]).normalized().orthogonal()
		var w: float = width * (1.0 - float(i) / spine.size()) * 0.5 + 0.15
		left.append(spine[i] + n * w)
		right.append(spine[i] - n * w)
	right.reverse()
	left.append_array(right)
	if not Geometry2D.triangulate_polygon(left).is_empty():
		fill(ci, left, color)
		return
	# A tight curve folds the ribbon over itself: draw it as tapered segments instead.
	for i: int in spine.size() - 1:
		ci.draw_line(spine[i], spine[i + 1], color, maxf(width * (1.0 - float(i) / spine.size()), 0.3), true)


static func rivet(ci: CanvasItem, at: Vector2, r: float = 0.9) -> void:
	ci.draw_circle(at, r, Color("2b2a33"), true, -1.0, true)
	ci.draw_circle(at - Vector2(0.3, 0.3), r * 0.55, Color("f4f1e6"), true, -1.0, true)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	ci.draw_line(a, b, color, width, true)


## A limb from `a` through `joint` to `b`, tapering, with a dark outline under its colour (legs, arms, tails).
static func limb(ci: CanvasItem, a: Vector2, joint: Vector2, b: Vector2, width: float, color: Color, outline: Color = VectorStyle.INK) -> void:
	strand(ci, a, a.lerp(joint, 0.5), joint, width + 1.5, outline)
	strand(ci, joint, joint.lerp(b, 0.5), b, width * 0.9 + 1.4, outline)
	strand(ci, a, a.lerp(joint, 0.5), joint, width, color)
	strand(ci, joint, joint.lerp(b, 0.5), b, width * 0.85, color.lightened(0.08))
	ci.draw_circle(joint, width * 0.5, color.lightened(0.14), true, -1.0, true)
	line(ci, a + Vector2(-0.4, 0), joint + Vector2(-0.4, 0), Color(light_of(color), 0.5), 0.6)

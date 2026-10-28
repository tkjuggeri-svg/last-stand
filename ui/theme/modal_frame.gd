class_name ModalFrame
extends StyleBox
## The frame of a modal panel (M15 P2, docs/M15_P2_UI.md): the theme's flat panel plus a hairline inner rule and gold
## corner brackets with a small diamond, drawn as vectors so it fits any size. Used by the theme's `ModalPanel`
## variation only; the compact HUD panels stay plain.

@export var base: StyleBoxFlat
@export var accent: Color = Color("e8c675")
## Distance of the inner rule and the brackets from the panel's edge.
@export var inset: float = 6.0
@export var bracket_length: float = 16.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if base != null:
		base.draw(to_canvas_item, rect)
	var inner: Rect2 = rect.grow(-inset)
	var rule: Color = Color(accent, 0.28)
	_rect_lines(to_canvas_item, inner, rule, 1.0)
	var bracket: Color = Color(accent, 0.95)
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
		var point: Vector2 = inner.position + inner.size * corner
		var along_x: Vector2 = Vector2(-1.0 if corner.x > 0.5 else 1.0, 0.0)
		var along_y: Vector2 = Vector2(0.0, -1.0 if corner.y > 0.5 else 1.0)
		RenderingServer.canvas_item_add_line(to_canvas_item, point, point + along_x * bracket_length, bracket, 2.0, true)
		RenderingServer.canvas_item_add_line(to_canvas_item, point, point + along_y * bracket_length, bracket, 2.0, true)
		_diamond(to_canvas_item, point + (along_x + along_y) * 4.0, 2.6, bracket)


func _rect_lines(canvas: RID, rect: Rect2, color: Color, width: float) -> void:
	var a: Vector2 = rect.position
	var b: Vector2 = Vector2(rect.end.x, rect.position.y)
	var c: Vector2 = rect.end
	var d: Vector2 = Vector2(rect.position.x, rect.end.y)
	for pair: Array in [[a, b], [b, c], [c, d], [d, a]]:
		RenderingServer.canvas_item_add_line(canvas, pair[0], pair[1], color, width, true)


func _diamond(canvas: RID, center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
	RenderingServer.canvas_item_add_polygon(canvas, points, PackedColorArray([color]))

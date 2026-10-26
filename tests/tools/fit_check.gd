class_name FitCheck
## Test helper (M13 follow-up, after a playtest found the War Room cut off): finds the buttons and labels of a
## screen that are not fully inside the visible area, i.e. clipped titles and buttons. A control inside a
## ScrollContainer or a dialog window is allowed to be out of view (it scrolls); everything else must fit.

const TOLERANCE: float = 1.0


## The names of the visible Buttons and Labels under `root` whose box leaves `area`.
static func clipped(root: Node, area: Rect2) -> Array[String]:
	var found: Array[String] = []
	_walk(root, area, found)
	return found


static func _walk(node: Node, area: Rect2, found: Array[String]) -> void:
	if node is Window and node != node.get_tree().root:
		return
	if node is ScrollContainer:
		_check(node as Control, area, found)  # the scroller itself must fit; what it holds may scroll
		return
	if node is Control:
		var control: Control = node as Control
		if not control.visible or (node is Control and not control.is_visible_in_tree()):
			return
		if control is Button or control is Label:
			_check(control, area, found)
	for child: Node in node.get_children():
		_walk(child, area, found)


static func _check(control: Control, area: Rect2, found: Array[String]) -> void:
	if not control.is_visible_in_tree():
		return
	var rect: Rect2 = control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if rect.position.x < area.position.x - TOLERANCE or rect.position.y < area.position.y - TOLERANCE \
			or rect.end.x > area.end.x + TOLERANCE or rect.end.y > area.end.y + TOLERANCE:
		var label: String = control.text if (control is Button or control is Label) else ""
		found.append("%s \"%s\" %s" % [control.name, label.left(24), rect])

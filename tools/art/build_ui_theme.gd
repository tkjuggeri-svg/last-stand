extends SceneTree
## Builds the UI theme (M15 P2, docs/M15_P2_UI.md): vector panels, buttons and bars drawn as StyleBoxFlat (rounded
## corners, a gold-bronze rim, a soft shadow) and the OFL fonts (Cinzel for titles and headers, Alegreya Sans for the
## rest). One table of colours and sizes here, so the look is tuned in one place; the type variation names are the
## ones every screen already uses. Writes ui/theme/game_theme.tres (dev only, never hand-edit that file):
## godot --headless --path . --script res://tools/art/build_ui_theme.gd

const OUT: String = "res://ui/theme/game_theme.tres"
const FONT_TITLE: String = "res://assets/fonts/Cinzel-Variable.ttf"
const FONT_BODY: String = "res://assets/fonts/AlegreyaSans-Medium.ttf"
const FONT_BOLD: String = "res://assets/fonts/AlegreyaSans-Bold.ttf"

const SIZE_BODY: int = 18
const SIZE_DIM: int = 16
const SIZE_HEADER: int = 20
const SIZE_TITLE: int = 32

const PANEL_BG: Color = Color(0.078, 0.067, 0.109, 0.92)
const CARD_BG: Color = Color(0.105, 0.09, 0.14, 0.95)
const RIM: Color = Color("b98f4a")
const RIM_LIGHT: Color = Color("e8c675")
const RIM_DIM: Color = Color("4a4252")
const BUTTON_BG: Color = Color("26212f")
const BUTTON_HOVER: Color = Color("353044")
const BUTTON_PRESSED: Color = Color("1a1622")
const PRIMARY_BG: Color = Color("7a2a26")
const PRIMARY_HOVER: Color = Color("98352f")
const TROUGH: Color = Color("0d0b12")
const SHADOW: Color = Color(0, 0, 0, 0.38)
const OUTLINE: Color = Color(0.05, 0.04, 0.07, 1)

const TEXT: Color = Color(0.93, 0.9, 0.84)
const GOLD: Color = Color(0.94, 0.82, 0.48)
const DIM: Color = Color(0.72, 0.7, 0.78)
const GOOD: Color = Color(0.6, 0.9, 0.5)
const WARN: Color = Color(1.0, 0.47, 0.4)
const RELIC: Color = Color(0.82, 0.66, 1.0)
const BAD_TITLE: Color = Color(0.92, 0.3, 0.26)


func _initialize() -> void:
	var theme: Theme = Theme.new()
	var body: Font = load(FONT_BODY)
	theme.default_font = body
	theme.default_font_size = SIZE_BODY
	_labels(theme, body)
	_panels(theme)
	_buttons(theme)
	_inputs(theme)
	theme.set_stylebox("background", "ProgressBar", _flat(TROUGH, RIM_DIM, 1, 3, 0))
	theme.set_type_variation("Backdrop", "Panel")
	theme.set_stylebox("panel", "Backdrop", _flat(Color(0.03, 0.02, 0.05, 0.72), Color(0, 0, 0, 0), 0, 0, 0))
	var err: Error = ResourceSaver.save(theme, OUT)
	print("%s %s" % ["saved" if err == OK else "FAILED", OUT])
	quit(0 if err == OK else 1)


func _labels(theme: Theme, body: Font) -> void:
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", OUTLINE)
	theme.set_constant("outline_size", "Label", 3)
	theme.set_constant("line_spacing", "Label", 1)
	var bold: Font = load(FONT_BOLD)
	_variation(theme, "TitleLabel", GOLD, _cinzel(700), SIZE_TITLE)
	_variation(theme, "TitleBadLabel", BAD_TITLE, _cinzel(700), SIZE_TITLE)
	_variation(theme, "HeaderLabel", GOLD, _cinzel(600), SIZE_HEADER)
	_variation(theme, "DimLabel", DIM, body, SIZE_DIM)
	_variation(theme, "GoodLabel", GOOD, body, 0)
	_variation(theme, "WarnLabel", WARN, body, 0)
	_variation(theme, "RelicLabel", RELIC, bold, 0)


func _variation(theme: Theme, name: StringName, color: Color, font: Font, size: int) -> void:
	theme.set_type_variation(name, "Label")
	theme.set_color("font_color", name, color)
	theme.set_font("font", name, font)
	if size > 0:
		theme.set_font_size("font_size", name, size)


func _cinzel(weight: int) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = load(FONT_TITLE)
	font.variation_opentype = {"wght": weight}
	return font


func _panels(theme: Theme) -> void:
	var panel: StyleBoxFlat = _flat(PANEL_BG, RIM, 2, 6, 4)
	_margins(panel, 10, 8)
	theme.set_stylebox("panel", "PanelContainer", panel)
	var modal: StyleBoxFlat = _flat(PANEL_BG, RIM, 2, 8, 8)
	_margins(modal, 28, 18)
	theme.set_type_variation("ModalPanel", "PanelContainer")
	theme.set_stylebox("panel", "ModalPanel", modal)
	var card: StyleBoxFlat = _flat(CARD_BG, RIM_DIM, 2, 6, 3)
	_margins(card, 10, 8)
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", card)


func _buttons(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _button(BUTTON_BG, RIM))
	theme.set_stylebox("hover", "Button", _button(BUTTON_HOVER, RIM_LIGHT))
	theme.set_stylebox("focus", "Button", _button(BUTTON_HOVER, RIM_LIGHT))
	theme.set_stylebox("pressed", "Button", _button(BUTTON_PRESSED, RIM))
	theme.set_stylebox("disabled", "Button", _button(Color("1b1822"), RIM_DIM))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color(1, 0.92, 0.7))
	theme.set_color("font_focus_color", "Button", Color(1, 0.92, 0.7))
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.52))
	theme.set_color("font_outline_color", "Button", OUTLINE)
	theme.set_constant("outline_size", "Button", 2)
	theme.set_type_variation("ButtonPrimary", "Button")
	theme.set_stylebox("normal", "ButtonPrimary", _button(PRIMARY_BG, RIM_LIGHT))
	theme.set_stylebox("hover", "ButtonPrimary", _button(PRIMARY_HOVER, RIM_LIGHT))
	theme.set_stylebox("focus", "ButtonPrimary", _button(PRIMARY_HOVER, RIM_LIGHT))
	theme.set_color("font_color", "ButtonPrimary", Color(0.98, 0.9, 0.62))


func _inputs(theme: Theme) -> void:
	for type: String in ["LineEdit", "TextEdit"]:
		var field: StyleBoxFlat = _flat(TROUGH, RIM_DIM, 2, 4, 0)
		_margins(field, 8, 5)
		var focus: StyleBoxFlat = _flat(TROUGH, RIM_LIGHT, 2, 4, 0)
		_margins(focus, 8, 5)
		theme.set_stylebox("normal", type, field)
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_placeholder_color", type, Color(0.55, 0.53, 0.6))


func _button(fill: Color, rim: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = _flat(fill, rim, 2, 5, 2)
	_margins(box, 12, 5)
	return box


func _flat(fill: Color, border: Color, border_width: int, radius: int, shadow: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_border_width_all(border_width)
	box.border_color = border
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	if shadow > 0:
		box.shadow_color = SHADOW
		box.shadow_size = shadow
		box.shadow_offset = Vector2(0, 2)
	return box


func _margins(box: StyleBoxFlat, horizontal: float, vertical: float) -> void:
	box.content_margin_left = horizontal
	box.content_margin_right = horizontal
	box.content_margin_top = vertical
	box.content_margin_bottom = vertical

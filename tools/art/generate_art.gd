extends SceneTree
## Draws all LAST STAND art (original, made entirely in code) and saves it as PNG sheets, plus the
## pixel font. The drawing lives in one file per asset family (hero_art.gd, ghoul_art.gd, ...) built on
## canvas.gd (lit primitives, contours, outline) and palette.gd; this script only runs the jobs.
## See ART_DIRECTION.md for the rules.
##
## Regenerate everything (from the project folder):
##   godot --headless --path . --script res://tools/art/generate_art.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/art/build_sprite_frames.gd

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")
const HeroArt: GDScript = preload("res://tools/art/hero_art.gd")
const GhoulArt: GDScript = preload("res://tools/art/ghoul_art.gd")
const HoundArt: GDScript = preload("res://tools/art/hound_art.gd")
const BruteArt: GDScript = preload("res://tools/art/brute_art.gd")
const CultistArt: GDScript = preload("res://tools/art/cultist_art.gd")
const GravelordArt: GDScript = preload("res://tools/art/gravelord_art.gd")
const ColossusArt: GDScript = preload("res://tools/art/colossus_art.gd")
const LichArt: GDScript = preload("res://tools/art/lich_art.gd")
const TollkeeperArt: GDScript = preload("res://tools/art/tollkeeper_art.gd")
const EffectsArt: GDScript = preload("res://tools/art/effects_art.gd")
const FortressArt: GDScript = preload("res://tools/art/fortress_art.gd")
const TowerArt: GDScript = preload("res://tools/art/tower_art.gd")
const EvolutionArt: GDScript = preload("res://tools/art/evolution_art.gd")
const MapArt: GDScript = preload("res://tools/art/map_art.gd")
const EnvironmentArt: GDScript = preload("res://tools/art/environment_art.gd")
const MarshArt: GDScript = preload("res://tools/art/marsh_art.gd")
const BloaterArt: GDScript = preload("res://tools/art/bloater_art.gd")
const MirePriestArt: GDScript = preload("res://tools/art/mire_priest_art.gd")
const ShieldbearerArt: GDScript = preload("res://tools/art/shieldbearer_art.gd")
const UiArt: GDScript = preload("res://tools/art/ui_art.gd")
const UpgradeIconArt: GDScript = preload("res://tools/art/upgrade_icon_art.gd")
const RelicArt: GDScript = preload("res://tools/art/relic_art.gd")
const TitleArt: GDScript = preload("res://tools/art/title_art.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
## Sheets now hand-drawn (the double-resolution art pack, docs/ART_HANDOFF.md): their jobs never run,
## so a regeneration can't overwrite them. Their drawing code stays for reference. The characters (hero,
## enemies, bosses) are drawn here again, at the pack's resolution (Layouts.FINE).
const HAND_DRAWN: Array[String] = ["swing", "swing_long", "spark", "dust",
	"fortress", "fortress_fx", "props", "crypt", "marsh_props", "chapel", "ripple", "title", "towers", "projectiles",
	"explosion", "explosion_large", "frost_nova", "burn", "soul_burst", "evolution_fx", "grapeshot", "status", "frost", "slot"]


func _initialize() -> void:
	# --only=hero,ghoul regenerates just those sheets (faster while iterating on one asset).
	var only: PackedStringArray = PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	var jobs: Dictionary = {
		"hero": func() -> void: _save(_sheet(HeroArt.new(Layouts.FINE).sheet_rows(), Layouts.HERO["size"]), Layouts.HERO["png"]),
		"swing": func() -> void: _save(_sheet(EffectsArt.new().swing_rows(), Layouts.SWING["size"]), Layouts.SWING["png"]),
		"swing_long": func() -> void: _save(_sheet(EffectsArt.new().swing_long_rows(), Layouts.SWING_LONG["size"]), Layouts.SWING_LONG["png"]),
		"ghoul": func() -> void: _save(_sheet(GhoulArt.new(Layouts.FINE).sheet_rows(), Layouts.GHOUL["size"]), Layouts.GHOUL["png"]),
		"hound": func() -> void: _save(_sheet(HoundArt.new(Layouts.FINE).sheet_rows(), Layouts.HOUND["size"]), Layouts.HOUND["png"]),
		"brute": func() -> void: _save(_sheet(BruteArt.new(Layouts.FINE).sheet_rows(), Layouts.BRUTE["size"]), Layouts.BRUTE["png"]),
		"cultist": func() -> void: _save(_sheet(CultistArt.new(Layouts.FINE).sheet_rows(), Layouts.CULTIST["size"]), Layouts.CULTIST["png"]),
		"cultist_fx": func() -> void: _save(_sheet(CultistArt.new(Layouts.FINE).fx_rows(), Layouts.CULTIST_FX["size"]), Layouts.CULTIST_FX["png"]),
		"gravelord": func() -> void: _save(_sheet(GravelordArt.new(Layouts.FINE).sheet_rows(), Layouts.GRAVELORD["size"]), Layouts.GRAVELORD["png"]),
		"colossus": func() -> void: _save(_sheet(ColossusArt.new(Layouts.FINE).sheet_rows(), Layouts.COLOSSUS["size"]), Layouts.COLOSSUS["png"]),
		"lich": func() -> void: _save(_sheet(LichArt.new(Layouts.FINE).sheet_rows(), Layouts.LICH["size"]), Layouts.LICH["png"]),
		"bloater": func() -> void: _save(_sheet(BloaterArt.new(false, Layouts.FINE).sheet_rows(), Layouts.BLOATER["size"]), Layouts.BLOATER["png"]),
		"bloatling": func() -> void: _save(_sheet(BloaterArt.new(true, Layouts.FINE).sheet_rows(), Layouts.BLOATLING["size"]), Layouts.BLOATLING["png"]),
		"mire_priest": func() -> void: _save(_sheet(MirePriestArt.new(Layouts.FINE).sheet_rows(), Layouts.MIRE_PRIEST["size"]), Layouts.MIRE_PRIEST["png"]),
		"shieldbearer": func() -> void: _save(_sheet(ShieldbearerArt.new(Layouts.FINE).sheet_rows(), Layouts.SHIELDBEARER["size"]), Layouts.SHIELDBEARER["png"]),
		"tollkeeper": func() -> void: _save(_sheet(TollkeeperArt.new(Layouts.FINE).sheet_rows(), Layouts.TOLLKEEPER["size"]), Layouts.TOLLKEEPER["png"]),
		"spark": func() -> void: _save(_sheet([EffectsArt.new().spark_frames()], Layouts.HIT_SPARK["size"]), Layouts.HIT_SPARK["png"]),
		"dust": func() -> void: _save(_sheet([EffectsArt.new().dust_frames()], Layouts.DUST["size"]), Layouts.DUST["png"]),
		"fortress": func() -> void: _save(_sheet([FortressArt.new().sheet_frames()], Layouts.FORTRESS["size"]), Layouts.FORTRESS["png"]),
		"fortress_fx": func() -> void: _save(_sheet(FortressArt.new().fx_rows(), Layouts.FORTRESS_FX["size"]), Layouts.FORTRESS_FX["png"]),
		"smoke": func() -> void: _save(FortressArt.new().smoke_puff(), Layouts.SMOKE_PNG),
		"ground": func() -> void: _save(_ground(), Layouts.GROUND_PNG),
		"props": func() -> void: _save(_sheet([EnvironmentArt.new().prop_frames()], EnvironmentArt.PROP_SIZE), Layouts.PROPS_PNG),
		"crypt": func() -> void: _save(EnvironmentArt.new().crypt(), Layouts.CRYPT_PNG),
		"marsh_ground": func() -> void: _save(_marsh_ground(), Layouts.MARSH_GROUND_PNG),
		"marsh_props": func() -> void: _save(_sheet([MarshArt.new().prop_frames()], MarshArt.PROP_SIZE), Layouts.MARSH_PROPS_PNG),
		"chapel": func() -> void: _save(MarshArt.new().chapel(), Layouts.CHAPEL_PNG),
		"ripple": func() -> void: _save(_sheet([MarshArt.new().ripple_frames()], Layouts.RIPPLE["size"]), Layouts.RIPPLE["png"]),
		"mote": func() -> void: _save(EnvironmentArt.new().mote(), Layouts.MOTE_PNG),
		"coin": func() -> void: _save(UiArt.new().icon("coin"), Layouts.COIN_PNG),
		"ui": _ui,
		"title": func() -> void: _save(TitleArt.new().scene(), Layouts.UI_DIR + "title_scene.png"),
		"towers": func() -> void: _save(_sheet(TowerArt.new().sheet_rows() + EvolutionArt.new().sheet_rows(), Layouts.TOWERS["size"]), Layouts.TOWERS["png"]),
		"projectiles": func() -> void: _save(_sheet(TowerArt.new().projectile_rows() + _evolution_shots(), Layouts.PROJECTILES["size"]), Layouts.PROJECTILES["png"]),
		"explosion": func() -> void: _save(_sheet([TowerArt.new().explosion_frames()], Layouts.EXPLOSION["size"]), Layouts.EXPLOSION["png"]),
		"explosion_large": func() -> void: _save(_sheet([TowerArt.new().explosion_frames(TowerArt.EXPLOSION_LARGE_SIZE)], Layouts.EXPLOSION_LARGE["size"]), Layouts.EXPLOSION_LARGE["png"]),
		"frost_nova": func() -> void: _save(_sheet([TowerArt.new().frost_nova_frames()], Layouts.FROST_NOVA["size"]), Layouts.FROST_NOVA["png"]),
		"burn": func() -> void: _save(_sheet([TowerArt.new().burn_frames(), EvolutionArt.new().soul_burn_frames()], Layouts.BURN["size"]), Layouts.BURN["png"]),
		"soul_burst": func() -> void: _save(_sheet([EvolutionArt.new().soul_burst_frames()], Layouts.SOUL_BURST["size"]), Layouts.SOUL_BURST["png"]),
		"evolution_fx": func() -> void: _save(_sheet([EvolutionArt.new().arrow_rain_frames()], Layouts.EVOLUTION_FX["size"]), Layouts.EVOLUTION_FX["png"]),
		"grapeshot": func() -> void: _save(_sheet(_grapeshot_rows(), Layouts.GRAPESHOT["size"]), Layouts.GRAPESHOT["png"]),
		"status": func() -> void: _save(_sheet(EvolutionArt.new().status_rows(), Layouts.STATUS["size"]), Layouts.STATUS["png"]),
		"upgrade_icons": _upgrade_icons,
		"relic_icons": func() -> void:
			for id: String in RelicArt.IDS:
				_save(RelicArt.new().icon(id), Layouts.RELIC_ICON_DIR + id + ".png"),
		"bone": func() -> void: _save(RelicArt.new().bone(), Layouts.BONE_PNG),
		"map_icons": func() -> void:
			for kind: String in MapArt.KINDS:
				_save(MapArt.new().icon(kind), Layouts.UI_DIR + "map/node_%s.png" % kind),
		"frost": func() -> void: _save(_sheet(TowerArt.new().frost_rows(), Layouts.FROST_FX["size"]), Layouts.FROST_FX["png"]),
		"slot": func() -> void: _save(_sheet([EnvironmentArt.new().slot_frames()], Layouts.BUILD_SLOT["size"]), Layouts.BUILD_SLOT["png"]),
	}
	for job_name: String in jobs:
		if HAND_DRAWN.has(job_name):
			if only.has(job_name):
				print("skipped %s: hand-drawn art (docs/ART_HANDOFF.md); its code art is no longer used" % job_name)
			continue
		if only.is_empty() or only.has(job_name):
			(jobs[job_name] as Callable).call()
	quit()


# ---------------------------------------------------------------- UI

func _ui() -> void:
	var ui: RefCounted = UiArt.new()
	var font: FontFile = ui.build_font(Layouts.FONT_ATLAS_PNG)
	var err: Error = ResourceSaver.save(font, Layouts.FONT)
	print("%s %s" % ["saved" if err == OK else "FAILED", Layouts.FONT])
	var dark: Color = Color("16121b")
	_save(ui.panel(P.GOLD, dark, true), Layouts.UI_DIR + "panel.png")
	_save(ui.panel(P.STONE.slice(1, 6), Color("1e1a24"), false), Layouts.UI_DIR + "card.png")
	_save(ui.panel(P.STONE.slice(1, 6), Color("2e2a38"), false), Layouts.UI_DIR + "button.png")
	_save(ui.panel(P.GOLD, Color("3a3446"), false), Layouts.UI_DIR + "button_hover.png")
	_save(ui.panel(P.GOLD, Color("1c1822"), false), Layouts.UI_DIR + "button_pressed.png")
	_save(ui.panel(P.STONE.slice(0, 5), Color("1c1a22"), false), Layouts.UI_DIR + "button_disabled.png")
	_save(ui.bar_frame(), Layouts.UI_DIR + "bar_frame.png")
	_save(ui.bar_fill([Color("1d2a4a"), Color("2f4a7a"), Color("4a6fa8"), Color("86aedb")]), Layouts.UI_DIR + "bar_fortress.png")
	_save(ui.bar_fill([Color("2c0f17"), Color("85282e"), Color("c0453a"), Color("ec7a5c")]), Layouts.UI_DIR + "bar_hero.png")
	_save(ui.bar_fill([Color("102438"), Color("2f6596"), Color("5aa0c8"), Color("b8e4f0")]), Layouts.UI_DIR + "bar_dash.png")
	_save(ui.bar_fill([Color("1f0d2a"), Color("4a1f5e"), Color("7d3a8f"), Color("c27ad0")]), Layouts.UI_DIR + "bar_boss.png")
	for kind: String in ["keep", "helm", "skull", "slot", "dash"]:
		_save(ui.icon(kind), Layouts.UI_DIR + "icon_%s.png" % kind)


func _upgrade_icons() -> void:
	var art: RefCounted = UpgradeIconArt.new()
	for id: String in UpgradeIconArt.IDS:
		_save(art.icon(id), Layouts.UPGRADE_ICON_DIR + id + ".png")


# ---------------------------------------------------------------- arena ground

## Bakes the prototype arena's ground from the level's floor, lanes (every Path2D named Lane*) and fortress.
func _ground() -> Image:
	var level: Node = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	var lanes: Array[Array] = _lanes_of(level)
	var keep: Vector2 = (level.get_node("Fortress") as Node2D).position
	var floor_node: ColorRect = level.get_node("Floor")
	var floor_rect: Rect2 = Rect2(floor_node.position, floor_node.size)
	level.free()
	return EnvironmentArt.new().ground(floor_rect, lanes, keep, Layouts.WALL_BAND, float(Layouts.ART_SCALE), Layouts.FINE)


## The Drowned Marsh's ground, baked the same way plus its pools (the Water node's polygons).
func _marsh_ground() -> Image:
	var level: Node = (load(Layouts.MARSH_LEVEL) as PackedScene).instantiate()
	var lanes: Array[Array] = _lanes_of(level)
	var pools: Array[PackedVector2Array] = (level.get_node("Water") as MarshWater).get_pools()
	var keep: Vector2 = (level.get_node("Fortress") as Node2D).position
	var floor_node: ColorRect = level.get_node("Floor")
	var floor_rect: Rect2 = Rect2(floor_node.position, floor_node.size)
	level.free()
	return MarshArt.new().ground(floor_rect, lanes, pools, keep, Layouts.WALL_BAND, float(Layouts.ART_SCALE), Layouts.FINE)


## Every Path2D named Lane* as a polyline in level coordinates.
func _lanes_of(level: Node) -> Array[Array]:
	var lanes: Array[Array] = []
	for child: Node in level.get_children():
		if child is Path2D and child.name.begins_with("Lane"):
			var lane: Path2D = child
			var lane_points: Array[Vector2] = []
			for i: int in lane.curve.point_count:
				lane_points.append(lane.position + lane.curve.get_point_position(i))
			lanes.append(lane_points)
	return lanes

# ---------------------------------------------------------------- image helpers

## The evolution shots, after the base towers' rows: sniper shot and harpoon (8 directions each),
## the mortar shell.
func _evolution_shots() -> Array[Array]:
	var art: RefCounted = EvolutionArt.new()
	var rows: Array[Array] = []
	for direction: int in 8:
		rows.append([art.sniper_shot(direction)])
	for direction: int in 8:
		rows.append([art.harpoon(direction)])
	rows.append(art.mortar_shell_frames())
	return rows


func _grapeshot_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for direction: int in 8:
		rows.append(EvolutionArt.new().grapeshot_frames(direction))
	return rows


func _blank(size: Vector2i) -> Image:
	return Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)


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

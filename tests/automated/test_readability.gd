extends SceneTree
## Automated check for readability (M8.5, ART_DIRECTION 14): by brightness alone (no colour), the
## hero and every enemy stand out from the ground of every map they fight on (a contrast ratio of at
## least MIN_CHARACTER), the towers and the shots from both grounds (MIN_BUILDING: buildings may be
## quieter than characters); and every enemy has a role, whose colour is the same in the game
## (EnemyRoles) and in the art (its eyes, the palette's role ramps).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const MIN_CHARACTER: float = 1.8
const MIN_BUILDING: float = 1.5
const GROUNDS: Dictionary = {
	"the Crypt Road": "res://assets/sprites/environment/prototype_arena_ground.png",
	"the Drowned Marsh": "res://assets/sprites/environment/drowned_marsh_ground.png",
}
## Enemies of chapter 2 only (measured on its ground alone).
const MARSH_ONLY: Array[String] = ["bloater", "bloatling", "mire_priest", "shieldbearer", "tollkeeper"]
const ENEMY_SPRITES: String = "res://assets/sprites/enemies"
const ENEMY_DATA: String = "res://data/enemies"
const PALETTE: GDScript = preload("res://tools/art/palette.gd")

var _failures: int = 0


func _initialize() -> void:
	var grounds: Dictionary = {}
	for map: String in GROUNDS:
		grounds[map] = Readability.body_luminance(_image(GROUNDS[map]), 4)
	var weak: Array[String] = []
	var sprites: Array[String] = ["res://assets/sprites/hero/hero.png"]
	for file: String in DirAccess.get_files_at(ENEMY_SPRITES):
		if file.ends_with(".png") and not file.ends_with("_fx.png"):
			sprites.append(ENEMY_SPRITES.path_join(file))
	for path: String in sprites:
		var light: float = Readability.body_luminance(_image(path))
		for map: String in grounds:
			if map == "the Crypt Road" and MARSH_ONLY.has(path.get_file().get_basename()):
				continue
			var ratio: float = Readability.contrast(light, grounds[map])
			if ratio < MIN_CHARACTER:
				weak.append("%s on %s (%.2f)" % [path.get_file().get_basename(), map, ratio])
	_check("the hero and %d enemies stand out from their grounds without colour (contrast >= %.1f)%s" % [sprites.size() - 1, MIN_CHARACTER,
		(": too weak " + ", ".join(weak)) if not weak.is_empty() else ""], weak.is_empty())
	weak.clear()
	for path: String in ["res://assets/sprites/towers/towers.png", "res://assets/sprites/towers/projectiles.png"]:
		var light: float = Readability.body_luminance(_image(path))
		for map: String in grounds:
			if Readability.contrast(light, grounds[map]) < MIN_BUILDING:
				weak.append("%s on %s" % [path.get_file(), map])
	_check("the towers and the shots stand out from both grounds (>= %.1f)%s" % [MIN_BUILDING, (": " + ", ".join(weak)) if not weak.is_empty() else ""],
		weak.is_empty())
	_test_roles()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_roles() -> void:
	var ramps: Dictionary = {EnemyData.Role.GRUNT: PALETTE.EYES_GRUNT, EnemyData.Role.FAST: PALETTE.EYES_FAST, EnemyData.Role.TANK: PALETTE.EYES_TANK,
		EnemyData.Role.RANGED: PALETTE.EYES_RANGED, EnemyData.Role.SUPPORT: PALETTE.EYES_SUPPORT, EnemyData.Role.SPLITTER: PALETTE.EYES_SPLITTER,
		EnemyData.Role.BOSS: PALETTE.EYES_BOSS}
	var same: bool = ramps.size() == EnemyRoles.COLORS.size()
	for role: EnemyData.Role in ramps:
		same = same and (ramps[role] as Array)[2].is_equal_approx(EnemyRoles.color_of(role))
	_check("each role's colour is the same in the game and in the art's eyes", same)
	var bosses_right: bool = true
	var roles: Dictionary = {}
	for file: String in DirAccess.get_files_at(ENEMY_DATA):
		if file.ends_with(".tres"):
			var data: EnemyData = load(ENEMY_DATA.path_join(file))
			bosses_right = bosses_right and (data.is_boss == (data.role == EnemyData.Role.BOSS))
			roles[data.role] = true
	_check("every boss has the boss role and only bosses; %d of the 7 roles in use" % roles.size(), bosses_right and roles.size() == 7)


func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1

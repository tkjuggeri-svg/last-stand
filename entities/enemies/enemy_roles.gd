class_name EnemyRoles
## The colour of each enemy role (M8.5, ART_DIRECTION 5): every enemy's eyes glow in it (the art
## tools' palette, P.EYES_*, index 2, the same values), and the game repeats it on its small health
## bar, its line in the feed and its first-sight banner. One colour per role, so a role reads the same
## everywhere: the common dead red, fast yellow, tanks cold blue, ranged witchfire green, support teal,
## splitters magenta, bosses violet.

const COLORS: Dictionary = {
	EnemyData.Role.GRUNT: Color("ff5a3a"),
	EnemyData.Role.FAST: Color("ffe14a"),
	EnemyData.Role.TANK: Color("7fb4ff"),
	EnemyData.Role.RANGED: Color("7fd13b"),
	EnemyData.Role.SUPPORT: Color("57e0c8"),
	EnemyData.Role.SPLITTER: Color("ff6adf"),
	EnemyData.Role.BOSS: Color("b58cff"),
}


static func color_of(role: EnemyData.Role) -> Color:
	return COLORS.get(role, COLORS[EnemyData.Role.GRUNT])

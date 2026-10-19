extends RefCounted
## The LAST STAND master palette (see ART_DIRECTION.md). Every material is a ramp from its deepest
## shadow to its brightest highlight. Shadows lean cool (blue/violet), highlights lean warm, so the
## colours stay rich instead of turning grey. Only the dev-time art generator uses this file.

const OUTLINE: Color = Color("1a141f")

# --- Hero ---
const STEEL: Array[Color] = [Color("23222e"), Color("393c50"), Color("555b72"), Color("7a8399"), Color("a5aec0"), Color("dfe4ea")]
const DARK_STEEL: Array[Color] = [Color("1f1e2a"), Color("33354a"), Color("4b5068"), Color("6c7189")]
const TABARD: Array[Color] = [Color("2c0f17"), Color("561a24"), Color("85282e"), Color("ae3b37"), Color("cf5c46")]
const CAPE: Array[Color] = [Color("22091a"), Color("3f1222"), Color("651c2b"), Color("8a2a33")]
const GOLD: Array[Color] = [Color("4f3418"), Color("8a5f2a"), Color("c49a4a"), Color("efd07a"), Color("fff1c0")]
const LEATHER: Array[Color] = [Color("1f1510"), Color("37261a"), Color("563c28"), Color("785739")]
const SKIN: Array[Color] = [Color("4e2f2b"), Color("82523f"), Color("b98163"), Color("deae8a")]

# --- Ghoul and the undead ---
const GHOUL_SKIN: Array[Color] = [Color("25252c"), Color("3d4046"), Color("5d6460"), Color("838c7c"), Color("aab29a"), Color("d3d5bb")]
const RAGS: Array[Color] = [Color("17130f"), Color("2a221b"), Color("41362a"), Color("5a4c3b")]
const BONE: Array[Color] = [Color("5b5446"), Color("8f8670"), Color("c3b99c"), Color("ece4cb")]
const EYE_GLOW: Array[Color] = [Color("6e1410"), Color("c2261b"), Color("ff5a3a"), Color("ffc9a0")]
const ICHOR: Array[Color] = [Color("10170f"), Color("223322"), Color("3b5a33"), Color("6f9a4f")]
const SOUL: Array[Color] = [Color("1e3d3a"), Color("2f6b5f"), Color("57b892"), Color("a8f0c8"), Color("e8fff0")]
## Grave Hound: flayed, mangy red-brown hide over pale bone (warmer and redder than the Ghoul).
const HOUND_HIDE: Array[Color] = [Color("26131a"), Color("45201f"), Color("6b3428"), Color("91503a"), Color("b47452"), Color("d39b72")]
## Brute: bloated, bruised violet-grey corpse flesh (colder and bluer than the Ghoul). Kept light:
## the cool dusk light flattens violets, and the biggest enemy must still pop off the dark grass.
const BRUTE_SKIN: Array[Color] = [Color("2a2236"), Color("463a5a"), Color("66597f"), Color("8b7ca3"), Color("b0a2c4"), Color("dcd2ea")]
## Cultist: a pale, ash-grey ritual robe (lighter than every other enemy, so the caster pops off the
## grass) with a near-black hood opening, lit by witchfire.
const CULT_ROBE: Array[Color] = [Color("2a2630"), Color("4a4450"), Color("716a72"), Color("9a9294"), Color("c2b9b2"), Color("e2dace")]
const CULT_DARK: Array[Color] = [Color("0d0a12"), Color("1b1424"), Color("2c2038")]
# --- Bosses ---
## The Gravelord's grave-moss shroud (grey-green, lighter than the grass it walks on).
const GRAVE_SHROUD: Array[Color] = [Color("1a201b"), Color("2d372f"), Color("465448"), Color("637465"), Color("849684"), Color("a8b8a4")]
## The Lich Warden's regal robe: deep violet-blue with cold highlights.
const LICH_ROBE: Array[Color] = [Color("120f24"), Color("221c42"), Color("362d66"), Color("4f4590"), Color("6e66b4"), Color("9a94d6")]
## Witchfire: the Cultist's sickly, bright green magic (its eyes, the orb it casts, its shots).
const WITCHFIRE: Array[Color] = [Color("1f4a1c"), Color("3f8f2a"), Color("7fd13b"), Color("c8f57a"), Color("f2ffd0")]

# --- Buildings ---
const STONE: Array[Color] = [Color("1e1c26"), Color("2f2c39"), Color("44404f"), Color("5b5667"), Color("777181"), Color("958f9c"), Color("b3adb6")]
const STONE_WARM: Array[Color] = [Color("231e22"), Color("372f33"), Color("4d4347"), Color("665a5c"), Color("837474"), Color("a39290")]
const SLATE: Array[Color] = [Color("16141f"), Color("221f30"), Color("302c45"), Color("423d5c"), Color("595372")]
const WOOD: Array[Color] = [Color("1d130e"), Color("33221a"), Color("4c3324"), Color("6a4a31"), Color("8a6542")]
const DEAD_WOOD: Array[Color] = [Color("181416"), Color("2a2324"), Color("3f3634"), Color("564b45"), Color("71655b")]
## Bronze: upgraded cannon barrels.
const BRONZE: Array[Color] = [Color("2e1d10"), Color("5a3a1c"), Color("8a5e2c"), Color("b88a45"), Color("e2bd76")]
const IRON: Array[Color] = [Color("15141b"), Color("25242e"), Color("3a3946"), Color("575766"), Color("82838f")]
const BANNER: Array[Color] = [Color("2c0d14"), Color("531721"), Color("7e232b"), Color("a83632"), Color("c95341")]
const HOOD: Array[Color] = [Color("16200f"), Color("26381f"), Color("3a5530"), Color("557547"), Color("7a9a5c")]

# --- Elements ---
const FIRE: Array[Color] = [Color("4a120c"), Color("8e2a14"), Color("d4551f"), Color("f29a35"), Color("ffd463"), Color("fff6d0")]
const SMOKE: Array[Color] = [Color("1b181d"), Color("2c282e"), Color("413b40"), Color("5a5357"), Color("776f70")]
const ICE: Array[Color] = [Color("0f2238"), Color("1d3d63"), Color("2f6596"), Color("4f95c8"), Color("8fd0f0"), Color("dff6ff")]
const ARCANE_ICE: Array[Color] = [Color("1d2a4a"), Color("3a5a96"), Color("6aa2e0"), Color("b6e4ff"), Color("ffffff")]

# --- Ground ---
const GRASS: Array[Color] = [Color("16200f"), Color("1d2a15"), Color("24331a"), Color("2b3d1f"), Color("344825"), Color("40552c")]
const GRASS_DRY: Array[Color] = [Color("2c2b17"), Color("39371d"), Color("484526"), Color("5a5530")]
const DIRT: Array[Color] = [Color("231a14"), Color("33261c"), Color("433325"), Color("54412f"), Color("67513b"), Color("7c6449")]
const MUD: Array[Color] = [Color("1a1512"), Color("261f1a"), Color("332a22")]
const MOSS: Array[Color] = [Color("1d2914"), Color("2e401d"), Color("435a28")]

class_name HeroData
extends Resource
## One playable hero (M9): who they are and the stats the Hero scene reads at startup. data/heroes/*.tres.
## The attack itself stays in the Hero scene; heroes with another attack add theirs in their own stage.

enum AttackKind { SWORD, BOLT }

@export var id: StringName = &""
@export var display_name: String = ""
## Two short lines for the War Room: how the hero fights and what they are weak at.
@export_multiline var description: String = ""
@export var max_health: int = 100
@export var move_speed: float = 200.0
## Damage of one hit, before the run's upgrades.
@export var attack_damage: int = 10
## Seconds between the start of two attacks, and how long the attack's hitbox stays active.
@export var attack_cooldown: float = 0.4
@export var attack_duration: float = 0.12
## How far (px) a hit pushes an enemy back along its lane.
@export var knockback: float = 12.0
## The towers only this hero builds (the build menu shows the shared ones and these).
@export var exclusive_towers: Array[TowerData] = []
## The cards and relics only this hero is offered (the other heroes' offers leave them out).
@export var exclusive_cards: Array[UpgradeData] = []
@export var exclusive_relics: Array[RelicData] = []
## The hero's sprite sheet (null: the scene's own).
@export var frames: SpriteFrames
@export var attack_kind: AttackKind = AttackKind.SWORD
## The hero's ultimate (M14): null = none.
@export var ultimate: UltimateData
## Bulwark (the Knight's passive): the share of a hit's damage shrugged off while swinging.
@export_range(0.0, 0.9) var bulwark: float = 0.0
@export_group("Story")
## The hero's name in the story (Ser Aldric), a line for the War Room's hero panel and the longer telling,
## and which portrait of the sheet is theirs (Portraits).
@export var story_name: String = ""
@export var story_line: String = ""
@export_multiline var story_text: String = ""
@export var portrait_index: int = 0
@export_group("")
@export_group("Raising")
## A kill the hero's bolt lands raises this minion where the enemy fell, up to `raise_cap` at once.
@export var raise_minion: MinionData
@export var raise_cap: int = 0
@export_group("Bolt")
## The bolt's own animations ("<look>_0".."<look>_7"); empty: the shared projectile sheet's "bolt".
@export var bolt_frames: SpriteFrames
@export var bolt_look: StringName = &"bolt"
## Its sound (an Sfx id).
@export var bolt_sound: StringName = &"hero_bolt"
## A bolt flies this far (px) at this speed and passes through this many enemies after the first.
@export var bolt_range: float = 340.0
@export var bolt_speed: float = 520.0
@export var bolt_pierce: int = 0
## A bolt bends toward the nearest enemy ahead of it, up to this many radians a second (0: flies straight).
@export var bolt_homing: float = 0.0
## The Mark a bolt leaves on whoever it hits: towers deal this much more to it for this long (0: none).
@export var mark_bonus: float = 0.0
@export var mark_time: float = 3.0

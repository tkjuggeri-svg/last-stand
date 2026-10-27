class_name VectorFrames
## Helpers the vector painters share (M15): reading an animation name and shaping an attack over its progress.


## "walk_side" -> {state: "walk", facing: "side"}; "death" -> {state: "death", facing: "down"}.
static func parse(anim: String) -> Dictionary:
	var cut: int = anim.find("_")
	return {"state": anim.substr(0, cut) if cut > 0 else anim, "facing": anim.substr(cut + 1) if cut > 0 else "down"}


## An attack's shape over its progress (0..1): pull back (a negative value) until `windup_end`, strike up to 1.0 at `peak`,
## then recover to 0. The painters time `peak` to the data's wind-up against the animation's length.
static func attack_curve(progress: float, windup_end: float, peak: float, pull: float) -> float:
	if progress < windup_end:
		return pull * smoothstep(0.0, windup_end, progress)
	if progress < peak:
		return lerpf(pull, 1.0, smoothstep(windup_end, peak, progress))
	return lerpf(1.0, 0.0, smoothstep(peak, 1.0, progress))

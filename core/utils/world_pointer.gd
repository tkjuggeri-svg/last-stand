class_name WorldPointer
extends RefCounted
## Where the mouse points in the 2D world (look-test: the only place gameplay asks). Normally the plain
## 2D answer; a presentation layer that shows the world differently (a tilted 3D camera) installs a
## provider that projects the mouse back onto the 2D plane, so aiming and the build hover keep working.

## A Callable returning the world position (Vector2); invalid: use the node's own 2D mouse position.
static var provider: Callable = Callable()


static func position_for(node: Node2D) -> Vector2:
	return provider.call() if provider.is_valid() else node.get_global_mouse_position()

// Blends a sprite toward a flat colour (white by default) to show it was hit. Keeps the pixel alpha.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// COLOR already holds the texture times the node's modulate, so tints (e.g. frost) still apply.
	COLOR = vec4(mix(COLOR.rgb, flash_color.rgb, flash), COLOR.a);
}

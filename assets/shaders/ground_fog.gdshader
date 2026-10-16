// Drifting ground fog for a world-space ColorRect: two noise layers scrolling at different speeds,
// snapped to a coarse pixel grid and to a few alpha steps so it matches the pixel art.
// Thicker around `focus` (in UV), thin elsewhere. Display only.
shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform vec4 fog_color : source_color = vec4(0.72, 0.76, 0.86, 1.0);
uniform vec2 rect_size = vec2(1300.0, 900.0);
// World px per fog "pixel" (4 = two art pixels).
uniform float pixel_size = 4.0;
uniform float density = 0.32;
uniform float base_density = 0.3;
uniform vec2 focus = vec2(0.12, 0.25);
uniform float focus_radius = 0.38;
uniform vec2 drift = vec2(0.006, 0.002);

void fragment() {
	vec2 world = floor(UV * rect_size / pixel_size) * pixel_size;
	vec2 uv = world / 512.0;
	float a = texture(noise_tex, uv + TIME * drift).r;
	float b = texture(noise_tex, uv * 1.7 - TIME * drift * 1.6 + vec2(0.37, 0.11)).r;
	float n = a * 0.6 + b * 0.4;
	float cover = smoothstep(0.48, 0.78, n);
	float near = 1.0 - smoothstep(0.0, focus_radius, distance(UV * vec2(rect_size.x / rect_size.y, 1.0), focus * vec2(rect_size.x / rect_size.y, 1.0)));
	float alpha = cover * density * mix(base_density, 1.0, near);
	alpha = floor(alpha * 12.0 + 0.5) / 12.0;
	COLOR = vec4(fog_color.rgb, alpha);
}

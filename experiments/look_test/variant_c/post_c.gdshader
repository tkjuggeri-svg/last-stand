shader_type canvas_item;
// Variant C's post pass, drawn inside the world canvas above the sprites and below the damage numbers and health
// bars (so those stay sharp; the HUD is on its own layers above everything). Tilt-shift that is stronger at the
// bottom than at the top, a distance haze by WORLD height (cooler and darker toward the top of the map, so it
// belongs to the map and not to the screen), a gentler bloom with a soft highlight roll-off (so lamps and the
// fortress do not blow out), world-anchored drifting fog and a light grade.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 view_size = vec2(1280.0, 720.0);
uniform vec2 camera_pos = vec2(0.0);
uniform float focus_y = 0.42;
uniform float blur_top = 1.8;
uniform float blur_bottom = 6.5;
uniform float bloom_threshold = 0.66;
uniform float bloom_strength = 0.34;
uniform float fog_strength = 0.14;
uniform vec3 fog_color : source_color = vec3(0.42, 0.5, 0.64);
uniform float haze_top_y = -500.0;
uniform float haze_bottom_y = 400.0;
uniform float haze_strength = 0.34;
uniform vec3 haze_color : source_color = vec3(0.22, 0.3, 0.46);
uniform float exposure = 1.7;
uniform float shadow_lift = 0.88;  // gamma below 1 lifts the darks, where most of the map is
uniform float saturation = 1.16;
uniform float contrast = 1.05;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + 11.7;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = 1.0 / view_size;
	float dy = SCREEN_UV.y - focus_y;
	float radius = dy < 0.0 ? blur_top * smoothstep(0.2, 0.42, -dy) : blur_bottom * smoothstep(0.08, 0.58, dy);
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	if (radius > 0.15) {
		vec3 sum = col;
		float total = 1.0;
		for (int i = 0; i < 12; i++) {
			float a = float(i) * 2.399963;
			float r = sqrt((float(i) + 0.5) / 12.0) * radius;
			sum += texture(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * r * px).rgb;
			total += 1.0;
		}
		col = sum / total;
	}
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 16; i++) {
		float a = float(i) * 2.399963;
		float r = (6.0 + 22.0 * sqrt((float(i) + 0.5) / 16.0));
		vec3 s = texture(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * r * px).rgb;
		glow += max(s - vec3(bloom_threshold), vec3(0.0));
	}
	col += glow / 16.0 * bloom_strength * 2.2 * vec3(1.0, 0.88, 0.7);
	col *= exposure;
	vec2 world = SCREEN_UV * view_size + camera_pos - view_size * 0.5;
	float n = fbm(world * 0.0042 + vec2(TIME * 0.012, TIME * 0.006));
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	float away = 1.0 - clamp((world.y - haze_top_y) / (haze_bottom_y - haze_top_y), 0.0, 1.0);
	float haze = pow(away, 1.4) * haze_strength;
	col = mix(col, haze_color * (luma * 0.9 + 0.18), haze);
	col *= 1.0 - 0.08 * haze;
	float fog = clamp((n - 0.28) * 1.9, 0.0, 1.0) * fog_strength * (0.4 + 0.6 * away);
	col = mix(col, fog_color * (luma * 0.6 + 0.3), fog);
	col = col / (1.0 + max(col - vec3(0.82), vec3(0.0)) * 0.9);
	col = pow(max(col, vec3(0.0)), vec3(shadow_lift));
	float l2 = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l2), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	COLOR = vec4(col, 1.0);
}

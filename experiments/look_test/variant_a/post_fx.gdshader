shader_type canvas_item;
// Variant A's single post pass over the world (the HUD layers sit above it): tilt-shift blur toward the
// top and bottom of the screen, a bloom of the bright parts (lamps, fire, magic), world-anchored drifting
// fog (denser far away, i.e. at the top) and a light colour grade. Compatibility-safe: one screen read.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 view_size = vec2(1280.0, 720.0);
uniform vec2 camera_pos = vec2(0.0);
uniform float focus_band : hint_range(0.0, 0.5) = 0.16;
uniform float blur_max = 5.0;
uniform float bloom_threshold = 0.62;
uniform float bloom_strength = 0.7;
uniform float fog_strength = 0.20;
uniform vec3 fog_color : source_color = vec3(0.42, 0.5, 0.64);
uniform float saturation = 1.12;
uniform float contrast = 1.06;

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
	float away = abs(SCREEN_UV.y - 0.5);
	float radius = blur_max * smoothstep(focus_band, 0.5, away);
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
	// Bloom: the bright parts, spread wide.
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 16; i++) {
		float a = float(i) * 2.399963;
		float r = (6.0 + 22.0 * sqrt((float(i) + 0.5) / 16.0));
		vec3 s = texture(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * r * px).rgb;
		glow += max(s - vec3(bloom_threshold), vec3(0.0));
	}
	col += glow / 16.0 * bloom_strength * 2.2 * vec3(1.0, 0.86, 0.66);
	// Fog, anchored to the world so it drifts past as the camera moves.
	vec2 world = SCREEN_UV * view_size + camera_pos - view_size * 0.5;
	float n = fbm(world * 0.0042 + vec2(TIME * 0.012, TIME * 0.006));
	float depth = mix(1.0, 0.3, SCREEN_UV.y);
	float amount = clamp((n - 0.28) * 1.9, 0.0, 1.0) * fog_strength * depth;
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, fog_color * (luma * 0.6 + 0.3), amount);
	// Grade.
	float l2 = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l2), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	COLOR = vec4(col, 1.0);
}

shader_type canvas_item;
render_mode unshaded, blend_mix;

// Slow drifting haze band for outdoor rooms.
uniform float drift_speed : hint_range(0.0, 0.2, 0.001) = 0.018;
uniform float band_scale : hint_range(0.5, 8.0, 0.1) = 2.4;
uniform float haze_alpha : hint_range(0.0, 0.35, 0.01) = 0.07;
uniform vec4 haze_color : source_color = vec4(0.75, 0.82, 0.95, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;
	uv.x += TIME * drift_speed;
	float n = noise(uv * band_scale);
	float n2 = noise(uv * band_scale * 1.7 + vec2(3.1, TIME * drift_speed * 0.5));
	float haze = smoothstep(0.35, 0.75, n * 0.65 + n2 * 0.35);
	float vertical = smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.55, UV.y);
	COLOR = vec4(haze_color.rgb, haze * haze_alpha * vertical);
}

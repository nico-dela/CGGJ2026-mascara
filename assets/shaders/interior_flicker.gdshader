shader_type canvas_item;
render_mode unshaded, blend_mix;

// Gentle warm light pulse for interior rooms.
uniform float pulse_amount : hint_range(0.0, 0.2, 0.005) = 0.035;
uniform float pulse_speed : hint_range(0.2, 6.0, 0.05) = 2.4;
uniform float flicker_amount : hint_range(0.0, 0.15, 0.005) = 0.02;
uniform vec4 warm_tint : source_color = vec4(1.0, 0.96, 0.88, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float slow = sin(TIME * pulse_speed) * pulse_amount;
	float flick = (hash(floor(TIME * 11.0)) - 0.5) * flicker_amount;
	float lit = 1.0 + slow + flick;
	COLOR = vec4(tex.rgb * warm_tint.rgb * lit, tex.a);
}

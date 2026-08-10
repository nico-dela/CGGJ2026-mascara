shader_type canvas_item;
render_mode unshaded, blend_mix;

// Soft wind sway for trees / ivy. Pivots near the bottom of the sprite (UV.y ~ 1).
uniform float sway_strength : hint_range(0.0, 24.0, 0.1) = 6.0;
uniform float sway_speed : hint_range(0.1, 4.0, 0.05) = 1.1;
uniform float sway_phase : hint_range(0.0, 6.28, 0.01) = 0.0;
uniform float secondary_strength : hint_range(0.0, 12.0, 0.1) = 2.0;

void vertex() {
	float top_factor = 1.0 - UV.y;
	float wave = sin(TIME * sway_speed + sway_phase + UV.y * 2.5);
	float ripple = sin(TIME * sway_speed * 1.7 + sway_phase * 1.3 + UV.x * 4.0);
	VERTEX.x += (wave * sway_strength + ripple * secondary_strength) * top_factor;
}

shader_type canvas_item;
render_mode unshaded, blend_mix;

// Soft radial vignette that slowly breathes.
uniform vec4 vignette_color : source_color = vec4(0.02, 0.01, 0.04, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.42;
uniform float vignette_softness : hint_range(0.1, 1.5, 0.01) = 0.55;
uniform float breathe_amount : hint_range(0.0, 0.3, 0.01) = 0.06;
uniform float breathe_speed : hint_range(0.05, 2.0, 0.01) = 0.35;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv * vec2(1.0, 0.92));
	float edge = smoothstep(vignette_softness, 1.25, dist);
	float breathe = sin(TIME * breathe_speed) * breathe_amount;
	float alpha = clamp(edge * vignette_strength + breathe, 0.0, 0.85);
	COLOR = vec4(vignette_color.rgb, alpha);
}

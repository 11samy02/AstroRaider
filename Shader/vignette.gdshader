shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(1.0, 0.4, 0.0, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 0.6, 0.0, 0.05);
uniform vec4 line_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float radius : hint_range(0.0, 1.0) = 0.65;
uniform float softness : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_strength : hint_range(0.0, 0.15) = 0.04;
uniform float line_brightness : hint_range(0.0, 2.0) = 1.2;
uniform float flicker_speed : hint_range(0.0, 10.0) = 3.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float energy_line(vec2 uv, float edge_dist, float seed, float time) {
	float phase = hash(seed) * 6.28;
	float speed = 0.5 + hash(seed + 1.0) * 1.5;
	float flicker = sin(time * flicker_speed * speed + phase) * 0.5 + 0.5;
	flicker *= sin(time * flicker_speed * 0.3 + phase * 2.0) * 0.5 + 0.5;

	float pos = hash(seed + 2.0);
	float length = 0.05 + hash(seed + 3.0) * 0.2;
	float width = 0.003 + hash(seed + 4.0) * 0.008;

	float line_pos = fract(pos + time * speed * 0.02);
	float dist_to_line = abs(edge_dist - line_pos);
	float line = smoothstep(width, 0.0, dist_to_line) * smoothstep(length, length * 0.3, dist_to_line);

	return line * flicker;
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);

	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float animated_radius = radius + pulse * pulse_strength;

	float vignette = smoothstep(animated_radius - softness, animated_radius, dist);
	float inner_glow = (1.0 - smoothstep(0.0, animated_radius - softness * 0.5, dist)) * 0.3;

	float edge_mask = smoothstep(animated_radius - softness * 2.0, animated_radius, dist);

	float lines = 0.0;

	float top_dist = fract(UV.x + 0.5);
	float bottom_dist = fract(UV.x + 0.5);
	float left_dist = fract(UV.y + 0.5);
	float right_dist = fract(UV.y + 0.5);

	float top_mask = smoothstep(0.08, 0.0, UV.y) * edge_mask;
	float bottom_mask = smoothstep(0.08, 0.0, 1.0 - UV.y) * edge_mask;
	float left_mask = smoothstep(0.08, 0.0, UV.x) * edge_mask;
	float right_mask = smoothstep(0.08, 0.0, 1.0 - UV.x) * edge_mask;

	for (float i = 0.0; i < 6.0; i++) {
		lines += energy_line(UV, top_dist, i * 10.0, TIME) * top_mask;
		lines += energy_line(UV, bottom_dist, i * 10.0 + 1.0, TIME) * bottom_mask;
		lines += energy_line(UV, left_dist, i * 10.0 + 2.0, TIME) * left_mask;
		lines += energy_line(UV, right_dist, i * 10.0 + 3.0, TIME) * right_mask;
	}

	lines *= line_brightness;

	vec4 col = mix(inner_color, vignette_color, vignette);
	col += line_color * lines * intensity;
	col.a = clamp(
		vignette * intensity * vignette_color.a +
		inner_color.a * intensity * inner_glow +
		lines * intensity * line_color.a,
		0.0, 1.0
	);

	COLOR = col;
}
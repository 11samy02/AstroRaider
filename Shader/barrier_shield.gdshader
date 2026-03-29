shader_type canvas_item;

uniform vec4 shield_color : source_color = vec4(0.0, 1.0, 0.8, 0.4);
uniform vec4 hex_line_color : source_color = vec4(0.0, 0.9, 1.0, 0.8);
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.9, 1.0);
uniform float hex_size : hint_range(5.0, 300.0) = 20.0;
uniform float line_thickness : hint_range(0.01, 0.3) = 0.08;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.2;
uniform float glow_radius : hint_range(0.0, 1.0) = 0.15;
uniform float alpha : hint_range(0.0, 1.0) = 0.6;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.2;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float edge_fade : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a >= 0.01) {
		vec2 uv = UV;
		vec2 tex_size = vec2(textureSize(TEXTURE, 0));
		vec2 px = uv * tex_size;

		float hex_w = hex_size * 1.732;
		float hex_h = hex_size * 2.0;
		vec2 grid = vec2(hex_w, hex_h * 0.75);
		vec2 half_grid = grid * 0.5;

		vec2 a = mod(px, grid) - half_grid;
		vec2 b = mod(px - half_grid, grid) - half_grid;

		float da = max(abs(a.x) * 0.866 + abs(a.y) * 0.5, abs(a.y));
		float db = max(abs(b.x) * 0.866 + abs(b.y) * 0.5, abs(b.y));
		float hex_dist = min(da, db) / (hex_size * 0.5);

		float edge = 1.0 - line_thickness;
		float hex_line = smoothstep(edge - 0.05, edge + 0.05, hex_dist);

		float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
		float pulse_alpha = alpha + pulse * pulse_strength;

		vec2 center = vec2(0.5, 0.5);
		float dist_from_center = length(uv - center);
		float edge_glow = smoothstep(0.5 - glow_radius, 0.5, dist_from_center);
		edge_glow *= glow_strength;

		// Rand fade — 0.0 am Rand, 1.0 in der Mitte
		float fade = smoothstep(0.5, 0.5 - edge_fade, dist_from_center);

		vec4 base = shield_color * pulse_alpha;
		base += hex_line_color * hex_line;
		base += glow_color * edge_glow;
		base.a = tex.a * (shield_color.a * pulse_alpha + hex_line * hex_line_color.a + edge_glow * 0.5) * fade;

		base = mix(base, hit_color, hit_flash);

		COLOR = base;
	} else {
		COLOR = vec4(0.0);
	}
}
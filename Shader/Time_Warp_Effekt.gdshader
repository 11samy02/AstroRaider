shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration : hint_range(0.0, 0.008) = 0.003;
uniform vec4 tint_color : source_color = vec4(0.15, 0.1, 0.7, 1.0);
uniform float tint_strength : hint_range(0.0, 0.25) = 0.12;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.6;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 3.0) = 0.8;
uniform float pulse_strength : hint_range(0.0, 0.05) = 0.02;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5, 0.5);
	vec2 to_center = uv - center;
	float dist = length(to_center);

	vec2 aberr_dir = normalize(to_center + vec2(0.0001)) * aberration * intensity;
	float r = texture(screen_texture, uv - aberr_dir).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + aberr_dir).b;
	vec3 col = vec3(r, g, b);

	col = mix(col, tint_color.rgb, tint_strength * intensity);

	float pulse = sin(TIME * pulse_speed) * pulse_strength + (1.0 - pulse_strength);
	float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist) * pulse;
	col *= mix(1.0, vignette, 0.25 * intensity);

	COLOR = vec4(col, intensity * 0.88);
}
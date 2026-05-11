shader_type canvas_item;
render_mode unshaded;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D fog_tex : repeat_enable, filter_linear;

uniform vec4 bg_color : source_color = vec4(0.005, 0.012, 0.016, 1.0);
uniform vec4 fog_color : source_color = vec4(0.0, 0.45, 0.50, 1.0);
uniform vec4 particle_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);

uniform float bg_noise_scale = 1.5;
uniform float fog_scale = 1.1;
uniform float fog_strength = 0.45;
uniform float fog_speed = 0.018;

uniform float particle_scale = 95.0;
uniform float particle_amount = 0.982;
uniform float particle_size = 0.025;
uniform float particle_speed = 0.025;
uniform float particle_glow = 1.4;

uniform float left_darkness = 0.55;
uniform float vignette_strength = 0.75;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float particle_field(vec2 uv) {
	vec2 p = uv * particle_scale;
	p += vec2(TIME * particle_speed * 0.25, -TIME * particle_speed);

	vec2 id = floor(p);
	vec2 gv = fract(p) - 0.5;

	float rnd = hash(id);
	vec2 offset = vec2(hash(id + 12.7), hash(id + 78.2)) - 0.5;

	float d = length(gv - offset);
	float star = smoothstep(particle_size, 0.0, d);

	star *= step(particle_amount, rnd);
	star *= 0.35 + hash(id + 33.3) * 0.85;

	return star;
}

void fragment() {
	vec2 uv = UV;

	float n1 = texture(noise_tex, uv * bg_noise_scale + vec2(TIME * 0.006, TIME * 0.002)).r;
	float n2 = texture(noise_tex, uv * bg_noise_scale * 2.3 + vec2(-TIME * 0.004, TIME * 0.003)).r;

	float depth = n1 * 0.65 + n2 * 0.35;

	vec3 col = bg_color.rgb;
	col += fog_color.rgb * depth * 0.14;

	vec2 fog_uv_a = uv * fog_scale + vec2(TIME * fog_speed, TIME * fog_speed * 0.3);
	vec2 fog_uv_b = uv * fog_scale * 1.8 + vec2(-TIME * fog_speed * 0.55, TIME * fog_speed * 0.2);

	float fog_a = texture(fog_tex, fog_uv_a).r;
	float fog_b = texture(fog_tex, fog_uv_b).r;

	float fog = smoothstep(0.32, 0.88, fog_a * 0.7 + fog_b * 0.3);
	float right_fog = smoothstep(0.10, 1.0, uv.x);

	col += fog_color.rgb * fog * fog_strength * right_fog;

	float particles = particle_field(uv);
	col += particle_color.rgb * particles * particle_glow;

	float left_mask = smoothstep(0.0, 0.55, uv.x);
	col *= mix(left_darkness, 1.0, left_mask);

	float vignette = distance(uv, vec2(0.5, 0.5));
	vignette = smoothstep(0.25, 0.85, vignette);
	col *= 1.0 - vignette * vignette_strength;

	COLOR = vec4(col, 1.0);
}
shader_type canvas_item;

uniform float radius : hint_range(0.0, 256.0) = 16.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 modulate_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 pos = UV * tex_size;
	vec2 inner_min = vec2(radius);
	vec2 inner_max = tex_size - vec2(radius);
	vec2 nearest = clamp(pos, inner_min, inner_max);
	float dist = length(pos - nearest);
	if (dist > radius) {
		discard;
	}

	COLOR = texture(TEXTURE, UV) * modulate_color;
	COLOR.a = alpha;
}
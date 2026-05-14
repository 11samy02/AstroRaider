shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(1.0, 0.82, 0.15, 1.0);
uniform float outline_size : hint_range(0.0, 8.0) = 2.0;
uniform float glow_size : hint_range(0.0, 12.0) = 4.0;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.35;
uniform float hover_strength : hint_range(0.0, 1.0) = 0.0;
uniform bool draw_base = true;

vec4 sample_sprite(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return vec4(0.0);
	}

	return texture(TEXTURE, uv);
}

void vertex() {
	float margin = outline_size + glow_size;
	VERTEX += (UV * 2.0 - 1.0) * margin;
}

void fragment() {
	float margin = outline_size + glow_size;
	vec2 border = (TEXTURE_PIXEL_SIZE * margin) / (vec2(1.0) + TEXTURE_PIXEL_SIZE * margin * 2.0);
	vec2 uv = (UV - border) / max(vec2(0.001), vec2(1.0) - border * 2.0);

	vec4 base = sample_sprite(uv);
	float base_alpha = base.a;
	vec2 px = TEXTURE_PIXEL_SIZE;

	if (hover_strength <= 0.0) {
		if (draw_base) {
			COLOR = base;
		} else {
			COLOR = vec4(0.0);
		}
		return;
	}

	float outline_alpha = 0.0;
	float glow_alpha = 0.0;

	for (float x = -12.0; x <= 12.0; x += 1.0) {
		for (float y = -12.0; y <= 12.0; y += 1.0) {
			if (x == 0.0 && y == 0.0) {
				continue;
			}

			float dist = length(vec2(x, y));
			float a = sample_sprite(uv + vec2(x, y) * px).a;
			if (dist <= outline_size) {
				outline_alpha = max(outline_alpha, a);
			}
			if (dist <= outline_size + glow_size) {
				glow_alpha = max(glow_alpha, a);
			}
		}
	}

	float outline_mask = max(outline_alpha - base_alpha, 0.0);
	float glow_mask = max(glow_alpha - base_alpha, 0.0);

	vec4 result = base;
	if (!draw_base) {
		result = vec4(0.0);
	}

	vec4 glow_col = outline_color;
	glow_col.a *= glow_mask * glow_strength * hover_strength;

	vec4 outline_col = outline_color;
	outline_col.a *= outline_mask * hover_strength;

	result.rgb = mix(result.rgb, glow_col.rgb, glow_col.a);
	result.rgb = mix(result.rgb, outline_col.rgb, outline_col.a);
	result.a = max(result.a, max(glow_col.a, outline_col.a));

	COLOR = result;
}

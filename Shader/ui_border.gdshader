shader_type canvas_item;

uniform bool dashed = true;
uniform int dash_count : hint_range(2, 40) = 10;
uniform float border_width : hint_range(1.0, 20.0) = 3.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 px = uv * size;

	float left   = px.x;
	float right  = size.x - px.x;
	float top    = px.y;
	float bottom = size.y - px.y;
	float min_dist = min(min(left, right), min(top, bottom));

	bool in_border = min_dist < border_width;

	vec4 tex = texture(TEXTURE, uv);

	if (!in_border) {
		COLOR = tex;
	} else if (!dashed) {
		COLOR = border_color;
	} else {
		float perimeter = 2.0 * (size.x + size.y);
		float pos = 0.0;
		bool in_corner = false;

		if (top < border_width && left >= border_width && right >= border_width) {
			pos = px.x / perimeter;
		} else if (right < border_width && top >= border_width && bottom >= border_width) {
			pos = (size.x + px.y) / perimeter;
		} else if (bottom < border_width && right >= border_width && left >= border_width) {
			pos = (size.x + size.y + (size.x - px.x)) / perimeter;
		} else if (left < border_width && bottom >= border_width && top >= border_width) {
			pos = (2.0 * size.x + size.y + (size.y - px.y)) / perimeter;
		} else {
			in_corner = true;
		}

		if (in_corner) {
			COLOR = tex;
		} else {
			float segment = 1.0 / float(dash_count * 2);
			float dash_pos = mod(pos, segment * 2.0);
			bool is_dash = dash_pos < segment;
			COLOR = is_dash ? border_color : tex;
		}
	}
}
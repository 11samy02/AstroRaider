shader_type canvas_item;
render_mode unshaded;

uniform int outline_size : hint_range(1,10) = 1;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if(tex_color.a < 0.1) {
		vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
		bool found = false;
		for (int x = -outline_size; x <= outline_size; x++) {
			for (int y = -outline_size; y <= outline_size; y++) {
				if((x == 0 && y == 0) || (x != 0 && y != 0))
					continue;
				vec2 offset = vec2(float(x), float(y)) * pixel_size;
				vec4 neighbor = texture(TEXTURE, UV + offset);
				if(neighbor.a > 0.1) {
					found = true;
					break;
				}
			}
			if(found)
				break;
		}
		if(found) {
			COLOR = outline_color;
		} else {
			discard;
		}
	} else {
		COLOR = tex_color;
	}
}

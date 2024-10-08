shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0, 10) = 1.0;
uniform int outline_pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool outline_inside = false;

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
    for (float i = -ceil(outline_width); i <= ceil(outline_width); i++) {
        float x = abs(i) > outline_width ? outline_width * sign(i) : i;
        float offset;

        if (outline_pattern == 0) {
            offset = outline_width - abs(x);
        } else if (outline_pattern == 1) {
            offset = floor(sqrt(pow(outline_width + 0.5, 2) - x * x));
        } else if (outline_pattern == 2) {
            offset = outline_width;
        }

        for (float j = -ceil(offset); j <= ceil(offset); j++) {
            float y = abs(j) > offset ? offset * sign(j) : j;
            vec2 xy = uv + texture_pixel_size * vec2(x, y);

            if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == outline_inside) {
                return true;
            }
        }
    }

    return false;
}

void fragment() {
    vec2 uv = UV;
    vec2 texture_pixel_size = TEXTURE_PIXEL_SIZE;

    vec4 texColor = texture(TEXTURE, uv);
    bool is_inside = texColor.a > 0.0;

    if (is_inside) {
        COLOR = texColor;
    } else if (hasContraryNeighbour(uv, texture_pixel_size, TEXTURE)) {
        COLOR = outline_color;
    } else {
        COLOR = vec4(0.0);
    }
}

shader_type canvas_item;
render_mode unshaded;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 blink_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float blink_strength : hint_range(0.0, 1.0) = 0.0;

uniform bool use_recolor = false;
uniform sampler2D gradient_texture;

uniform vec4 blink_color_2 : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float blink_strength_2 : hint_range(0.0, 1.0) = 0.0;

uniform bool blink_uses_recolor = true;
uniform float gradient_offset : hint_range(-1.0, 1.0) = 0.0;
uniform float gradient_contrast : hint_range(0.1, 4.0) = 1.0;

float get_luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 recolor(vec3 original) {
    float l = get_luminance(original);
    l = (l - 0.5 + gradient_offset) * gradient_contrast + 0.5;
    l = clamp(l, 0.0, 1.0);
    return texture(gradient_texture, vec2(l, 0.5)).rgb;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a <= 0.0) {
        discard;
    }

    vec3 original_rgb = tex.rgb;
    vec3 recolored_rgb = recolor(original_rgb);

    vec3 base_rgb = use_recolor ? recolored_rgb : original_rgb;
    vec3 blink_base = blink_uses_recolor ? recolored_rgb : original_rgb;

    vec3 final_rgb = mix(base_rgb, blink_color.rgb, blink_strength);
    final_rgb = mix(final_rgb, blink_color_2.rgb, blink_strength_2);

    COLOR = vec4(final_rgb, tex.a * opacity);
}
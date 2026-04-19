shader_type canvas_item;
render_mode unshaded;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 blink_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float blink_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a <= 0.0) {
        discard;
    }

    vec3 final_rgb = mix(tex.rgb, blink_color.rgb, blink_strength);
    COLOR = vec4(final_rgb, tex.a * opacity);
}
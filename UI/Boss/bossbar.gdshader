shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform bool crit_active = false;
uniform float crit_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 crit_color : source_color = vec4(1.0, 0.271, 0.2, 1.0);

void fragment() {
	vec4 base_col = texture(TEXTURE, UV);
	float mix_amount = crit_active ? crit_intensity : 0.0;
	vec3 crit_mix = mix(base_col.rgb, crit_color.rgb, mix_amount);
	vec3 glow = vec3(1.0, 0.3, 0.5) * glow_intensity;
	vec3 final_rgb = crit_mix + glow * glow_intensity;
	COLOR = vec4(final_rgb, base_col.a);
}

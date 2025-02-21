shader_type canvas_item;

uniform sampler2D noise_tex: repeat_enable;
uniform sampler2D noise_tex2: repeat_enable;

uniform vec2 offset = vec2(0.01);
uniform vec2 offset2 = vec2(0.02);

uniform sampler2D color_ramp;

void fragment() {
	vec4 noise_col = texture(noise_tex, UV+offset*TIME);
	vec4 noise_col2 = texture(noise_tex2, UV+offset2*TIME);

	float final_noise = noise_col.r * noise_col2.r;
	vec2 sample_cord = vec2(final_noise);

	vec4 final_color = texture(color_ramp, sample_cord);

	COLOR = final_color;
}

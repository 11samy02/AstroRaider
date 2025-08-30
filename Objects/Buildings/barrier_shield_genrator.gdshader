shader_type canvas_item;
render_mode unshaded;

uniform sampler2D mask;
uniform sampler2D noise_1: repeat_enable;
uniform sampler2D noise_2: repeat_enable;

uniform vec2 offset_1 = vec2(0.1);
uniform vec2 offset_2 = vec2(0.2);


uniform sampler2D screen_tex: hint_screen_texture, filter_nearest;

uniform float disortion_strength: hint_range(-1.0, 1.0, 0.001) = 0.01;

void fragment() {
	vec4 mask_color = texture(mask, UV);
	vec4 screen_color = texture(screen_tex, SCREEN_UV);
	
	vec4 noise_color1 = texture(noise_1, UV + offset_1 * TIME);
	vec4 noise_color2 = texture(noise_2, UV + offset_2 * TIME);
	
	float final_noise = noise_color1.r * noise_color2.r;
	vec4 final_color = texture(screen_tex, SCREEN_UV + final_noise * disortion_strength);
	
	
	if(mask_color.r <= 0.0) {
		mask_color.a = 0.0;
	}
	else{
		mask_color.rgb = final_color.rgb;
	}
	
	
	
	COLOR = mask_color;
}

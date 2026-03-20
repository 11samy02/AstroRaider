shader_type canvas_item;
render_mode blend_add;

uniform vec4 color_1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_2 : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 color_3 : source_color = vec4(0.0, 0.3, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 20.0) = 6.0;
uniform float glow_intensity : hint_range(0.0, 10.0) = 3.0;
uniform float core_sharpness : hint_range(1.0, 20.0) = 10.0;
uniform float white_core_strength : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	float along = UV.x;
	float across = abs(UV.y - 0.5) * 2.0;

	float t = TIME * pulse_speed;
	float phase1 = sin(t) * 0.5 + 0.5;
	float phase2 = sin(t + 2.094) * 0.5 + 0.5;
	float phase3 = sin(t + 4.188) * 0.5 + 0.5;
	float total = phase1 + phase2 + phase3;
	vec3 pulsed = (color_1.rgb * phase1 + color_2.rgb * phase2 + color_3.rgb * phase3) / total;

	float trail_fade = 1.0 - along;
	float core = pow(1.0 - across, core_sharpness);
	float glow = pow(1.0 - across, 2.0) * 0.4;

	vec3 final_color = mix(pulsed, vec3(1.0), core * white_core_strength) * glow_intensity;
	float alpha = (core + glow) * trail_fade;

	COLOR = vec4(final_color, alpha);
}

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float grayscale_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	// Wahrgenommene Helligkeit, wirkt natürlicher als einfacher Durchschnitt
	float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

	vec3 grayscale_color = vec3(gray);

	// 0.0 = normales Bild
	// 1.0 = komplett grau
	vec3 final_color = mix(screen_color.rgb, grayscale_color, grayscale_strength);

	COLOR = vec4(final_color, screen_color.a);
}
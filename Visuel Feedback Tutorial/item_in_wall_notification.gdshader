shader_type canvas_item;
render_mode unshaded;

uniform vec4 hologram_tint = vec4(0.0, 1.0, 1.0, 1.0); // Farbton des Hologramms
uniform float line_frequency = 20.0; // Häufigkeit der Linien
uniform float line_intensity = 0.2;  // Sichtbarkeit der Linien
uniform float distortion_strength = 0.05; // Verzerrungsstärke
uniform float glow_intensity = 0.3; // Glüheffekt-Intensität
uniform float time_speed = 2.0; // Geschwindigkeit der Animation
uniform float alpha = 1.0; // Transparenz des Sprites (0.0 - 1.0)

void fragment() {
    vec2 uv = UV;

    // Zeit für Animation
    float time = TIME * time_speed;

    // Horizontale Verzerrung basierend auf UV-Koordinaten und Zeit
    float distortion = sin(uv.y * 10.0 + time) * distortion_strength;

    // Verzerrung auf UV anwenden
    uv.x += distortion;

    // Linien-Effekt basierend auf UV-Koordinaten und Zeit
    float line_effect = abs(sin(uv.y * line_frequency + time)) * line_intensity;

    // Original-Textur abrufen
    vec4 tex_color = texture(TEXTURE, uv);

    // Hologramm-Farbe mit Original-Textur kombinieren
    vec4 holo_color = mix(tex_color, hologram_tint, line_effect * glow_intensity);

    // Finale Farbe (ursprüngliche Transparenz bleibt erhalten und wird durch den Alpha-Wert gesteuert)
    COLOR = vec4(holo_color.rgb, tex_color.a * alpha);
}

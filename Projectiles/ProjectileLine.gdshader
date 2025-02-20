shader_type canvas_item;

uniform vec4 core_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Farbe des Kerns (Mitte)
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Farbe des äußeren Glow
uniform float speed = 3.0; // Geschwindigkeit der Animation
uniform float glow_intensity = 1.5; // Stärke des Glows
uniform float wave_amplitude = 0.05; // Höhe der Wellen
uniform float wave_frequency = 10.0; // Frequenz der Wellen
uniform float core_width = 0.2; // Breite des Kernbereichs
uniform float edge_falloff = 0.4; // Weicher Übergang zu den Rändern

void fragment() {
    // Zeitabhängige Animation
    float t = TIME * speed;

    // Wellenbewegung für dynamischen Effekt
    float wave = sin(UV.x * wave_frequency + t) * wave_amplitude;

    // Abstand zur Mitte mit Wave-Verzerrung
    float dist_to_center = abs(UV.y - 0.5 + wave);

    // Kernfarbe: Helle Mitte
    float core = smoothstep(0.0, core_width, 0.5 - dist_to_center);

    // Randfarbe: Weicher Glow außerhalb des Kerns
    float glow = smoothstep(edge_falloff, 0.0, dist_to_center);

    // Mischung der Farben basierend auf Abstand
    vec4 final_color = mix(edge_color, core_color, core);

    // Glow-Intensität hinzufügen
    final_color.rgb *= 1.0 + glow * glow_intensity;

    // Alpha: immer sichtbar, abhängig von Glow und Kern
    final_color.a = max(1.0 - dist_to_center, 0.0);

    // Ergebnisfarbe setzen
    COLOR = final_color;
}

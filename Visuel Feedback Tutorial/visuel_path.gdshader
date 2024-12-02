shader_type canvas_item;
render_mode unshaded;

uniform float speed = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Die Farbe des Glow-Effekts
uniform float glow_strength = 1.0; // Die Stärke des Glow-Effekts
uniform float blur_amount = 1.0; // Die Menge des Blur-Effekts

void fragment() {
    vec2 new_UV = mod(UV - vec2(TIME * speed, 0.0), 1.0);
    vec4 base_color = texture(TEXTURE, new_UV);

    // Berechnung des Glow-Effekts
    vec4 glow = base_color * glow_color * glow_strength;

    // Berechnung des Blur-Effekts nur für den Glow
    vec4 blurred_glow = vec4(0.0);
    float total_weight = 0.0;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            float weight = 1.0 / (abs(float(x)) + abs(float(y)) + 1.0);
            blurred_glow += glow * weight;
            total_weight += weight;
        }
    }
    blurred_glow /= total_weight;

    // Kombination der Basisfarbe und des geblurrten Glow-Effekts
    COLOR = base_color + blurred_glow * blur_amount;
}

shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform float size = 40.0;
uniform bool fill = true;

void fragment() {
	float x = abs(fract(FRAGCOORD.x / size) - 0.5);
	float y = abs(fract(FRAGCOORD.y / size) - 0.5);

	// Invert progress for the case where fill is false
	float effective_progress = fill ? progress : 1.0 - progress;

	if (x + y + UV.y + UV.x > effective_progress * 4.0) {
		if (fill) {
			discard;
		}
	} else if (!fill) {
		discard;
	}
}

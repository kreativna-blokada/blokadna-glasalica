shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0, 1.0) = 1.0;
uniform bool enabled_outline = true;
uniform vec4 modulate_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

//widest outline still checked texel by texel, wider ones are sampled in rings
const float DENSE_WIDTH_LIMIT = 4.0;
const int WIDE_RING_COUNT = 4;
const int WIDE_DIRECTION_COUNT = 16;
//unit directions every 22.5 degrees, so no fragment computes them again
const vec2 WIDE_DIRECTIONS[WIDE_DIRECTION_COUNT] = {
	vec2(1.0000, 0.0000),
	vec2(0.9239, 0.3827),
	vec2(0.7071, 0.7071),
	vec2(0.3827, 0.9239),
	vec2(0.0000, 1.0000),
	vec2(-0.3827, 0.9239),
	vec2(-0.7071, 0.7071),
	vec2(-0.9239, 0.3827),
	vec2(-1.0000, 0.0000),
	vec2(-0.9239, -0.3827),
	vec2(-0.7071, -0.7071),
	vec2(-0.3827, -0.9239),
	vec2(0.0000, -1.0000),
	vec2(0.3827, -0.9239),
	vec2(0.7071, -0.7071),
	vec2(0.9239, -0.3827)
};
//half opaque, like the texel itself, so compression noise in the alpha is ignored
const float OPAQUE_ALPHA = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * modulate_color;
	if (enabled_outline && tex.a < OPAQUE_ALPHA) {
		bool is_near_sprite = false;
		if (outline_width <= DENSE_WIDTH_LIMIT) {
			//checks every texel within a thin outline, so thin parts leave no holes or loose dots
			int radius = int(outline_width);
			float reach = outline_width * outline_width + outline_width;
			for (int x = -radius; x <= radius && !is_near_sprite; x++) {
				for (int y = -radius; y <= radius; y++) {
					//the texel itself already failed the alpha check
					if ((x == 0 && y == 0) || float(x * x + y * y) > reach) continue;
					if (textureLod(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE, 0.0).a >= OPAQUE_ALPHA) {
						is_near_sprite = true;
						break;
					}
				}
			}
		} else {
			//a wide outline samples a few rings in fixed directions, so its cost stays the same at any width
			for (int ring = 1; ring <= WIDE_RING_COUNT && !is_near_sprite; ring++) {
				float ring_radius = outline_width * float(ring) / float(WIDE_RING_COUNT);
				for (int direction = 0; direction < WIDE_DIRECTION_COUNT; direction++) {
					if (textureLod(TEXTURE, UV + WIDE_DIRECTIONS[direction] * ring_radius * TEXTURE_PIXEL_SIZE, 0.0).a >= OPAQUE_ALPHA) {
						is_near_sprite = true;
						break;
					}
				}
			}
		}
		if (is_near_sprite) {
			tex = outline_color;
		}
	}
	COLOR = tex;
}

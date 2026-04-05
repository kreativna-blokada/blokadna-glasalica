shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0, 1.0) = 1.0;
uniform bool enabled_outline = true;
uniform vec4 modulate_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * modulate_color;
	if (enabled_outline && tex.a < 0.5) {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float a = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
		a += texture(TEXTURE, UV + vec2(size.x, 0)).a;
		a += texture(TEXTURE, UV + vec2(0, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(0, size.y)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		a += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
		if (a > 0.0) {
			tex = outline_color;
		}
	}
	COLOR = tex;
}

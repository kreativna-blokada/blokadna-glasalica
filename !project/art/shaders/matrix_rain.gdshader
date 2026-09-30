shader_type canvas_item;

//full-screen matrix rain; 5x7 dot 3s fall down in columns, a solid head with a fading trail
//glyph columns across the screen width
uniform float column_count : hint_range(10.0, 200.0, 1.0) = 64.0;
//rows per second, each column randomly faster or slower around it
uniform float fall_speed : hint_range(1.0, 60.0, 0.5) = 14.0;
//rows the trail spans behind the head
uniform float trail_length : hint_range(2.0, 60.0, 1.0) = 18.0;
uniform vec4 glyph_color : source_color = vec4(0.496, 0.0, 0.0, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

//glyph cell height over width, 5x7 dot glyph plus margin
const float GLYPH_ASPECT = 1.4;
//5x7 dot 3, one row per entry top to bottom, leftmost dot in the highest of the 5 bits
const int THREE_ROWS[7] = { 14, 17, 1, 6, 1, 17, 14 };

float hash(vec2 seed) {
	return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

//1.0 where a dot of the 3 in this cell covers the point, 0.0 elsewhere
float three_mask(vec2 cell_point) {
	//7x9 grid leaves a one dot margin around the 5x7 glyph
	ivec2 dot_index = ivec2(floor(cell_point * vec2(7.0, 9.0))) - 1;
	if (dot_index.x < 0 || dot_index.x > 4 || dot_index.y < 0 || dot_index.y > 6) {
		return 0.0;
	}
	return float((THREE_ROWS[dot_index.y] >> (4 - dot_index.x)) & 1);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float row_count = column_count / (aspect * GLYPH_ASPECT);
	vec2 cell_position = vec2(SCREEN_UV.x * column_count, SCREEN_UV.y * row_count);
	vec2 cell_index = floor(cell_position);

	float column_random = hash(vec2(cell_index.x, 3.0));
	float column_speed = fall_speed * mix(0.5, 1.5, column_random);
	//head wraps past the bottom and the whole trail before re-entering at the top
	float head_row = mod(TIME * column_speed + column_random * 1000.0, row_count + trail_length);
	float trail_distance = head_row - cell_index.y;

	vec4 rain_color = background_color;
	if (trail_distance >= 0.0 && trail_distance < trail_length) {
		float fade = 1.0 - trail_distance / trail_length;
		rain_color = mix(background_color, glyph_color, three_mask(fract(cell_position)) * fade);
	}
	COLOR = rain_color;
}

shader_type canvas_item;

//full-screen countdown digit over everything; 1 explodes in pixels, 2 rains down in pixels, 3 spreads over the whole screen
//digit shown, 1 to 3
uniform int digit : hint_range(1, 3) = 1;
//0 to 1 over the time this digit is on screen
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 digit_color : source_color = vec4(0.496, 0.0, 0.0, 1.0);
//alpha while semi-transparent; 3 turns fully opaque as it fills the screen
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.5;
//fraction of the screen height
uniform float digit_height : hint_range(0.1, 1.0, 0.01) = 0.6;
//px side of one digit pixel
uniform float pixel_size : hint_range(4.0, 64.0, 1.0) = 16.0;
//share of the progress 1 and 2 stay whole before breaking apart
uniform float hold_fraction : hint_range(0.0, 0.9, 0.01) = 0.35;
//how many times larger 3 is at the end of its progress
uniform float spread_scale : hint_range(1.0, 40.0, 0.5) = 20.0;

//speed groups the pixels are split into, each flying at its own speed
const int SPEED_GROUPS = 6;

float hash(vec2 seed) {
	return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

float box_distance(vec2 point, vec2 center, vec2 half_size) {
	vec2 edge_distance = abs(point - center) - half_size;
	return length(max(edge_distance, 0.0)) + min(max(edge_distance.x, edge_distance.y), 0.0);
}

//true where the seven-segment digit covers the point, point in screen heights around the screen center
bool digit_covers(vec2 point) {
	float half_height = digit_height * 0.5;
	float stroke = digit_height * 0.14;
	float digit_width = digit_height * 0.55;
	vec2 bar_size = vec2(digit_width * 0.5, stroke * 0.5);
	vec2 stem_size = vec2(stroke * 0.5, half_height * 0.5);
	float right_x = digit_width * 0.5 - stroke * 0.5;

	if (digit == 1) {
		return box_distance(point, vec2(0.0), vec2(stroke * 0.5, half_height)) <= 0.0;
	}
	float shape_distance = min(
		min(box_distance(point, vec2(0.0, -half_height + stroke * 0.5), bar_size), box_distance(point, vec2(0.0), bar_size)),
		min(box_distance(point, vec2(0.0, half_height - stroke * 0.5), bar_size), box_distance(point, vec2(right_x, -half_height * 0.5), stem_size)));
	//2 has the lower stem on the left, 3 on the right
	float lower_x = digit == 2 ? -right_x : right_x;
	shape_distance = min(shape_distance, box_distance(point, vec2(lower_x, half_height * 0.5), stem_size));
	return shape_distance <= 0.0;
}

//where a pixel starting at start_position is at break_progress, 1 flies out from the center, 2 falls down
vec2 flown_position(vec2 start_position, vec2 screen_center, float speed, float break_progress, float screen_height) {
	if (digit == 1) {
		return screen_center + (start_position - screen_center) * (1.0 + break_progress * speed * 4.0);
	}
	return start_position + vec2(0.0, break_progress * break_progress * speed * screen_height * 1.2);
}

//inverse of flown_position, where a pixel now at flown_position started
vec2 resting_position(vec2 current_position, vec2 screen_center, float speed, float break_progress, float screen_height) {
	if (digit == 1) {
		return screen_center + (current_position - screen_center) / (1.0 + break_progress * speed * 4.0);
	}
	return current_position - vec2(0.0, break_progress * break_progress * speed * screen_height * 1.2);
}

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 screen_center = screen_size * 0.5;
	vec2 fragment_position = SCREEN_UV * screen_size;
	float coverage = 0.0;
	float alpha = opacity;

	if (digit == 3) {
		//cubic growth, slow start then rushes over the screen through the middle bar
		float spread = 1.0 + pow(progress, 3.0) * (spread_scale - 1.0);
		coverage = float(digit_covers((fragment_position - screen_center) / (screen_size.y * spread)));
		alpha = mix(opacity, 1.0, smoothstep(0.6, 1.0, progress));
	} else {
		float break_progress = clamp((progress - hold_fraction) / (1.0 - hold_fraction), 0.0, 1.0);
		if (digit == 2) {
			//columns start falling one after another
			float column_delay = hash(vec2(floor(fragment_position.x / pixel_size), 5.0)) * 0.3;
			break_progress = clamp((break_progress - column_delay) / (1.0 - column_delay), 0.0, 1.0);
		}
		for (int speed_group = 0; speed_group < SPEED_GROUPS; speed_group++) {
			float speed = mix(0.4, 1.6, (float(speed_group) + 0.5) / float(SPEED_GROUPS));
			vec2 pixel_index = floor(resting_position(fragment_position, screen_center, speed, break_progress, screen_size.y) / pixel_size);
			if (int(hash(pixel_index) * float(SPEED_GROUPS)) != speed_group) {
				continue;
			}
			vec2 pixel_center = (pixel_index + 0.5) * pixel_size;
			vec2 landed_offset = abs(fragment_position - flown_position(pixel_center, screen_center, speed, break_progress, screen_size.y));
			//pixels keep their size and show small gaps between them
			bool inside_pixel = max(landed_offset.x, landed_offset.y) < pixel_size * 0.42;
			if (inside_pixel && digit_covers((pixel_center - screen_center) / screen_size.y)) {
				coverage = 1.0;
				break;
			}
		}
		alpha = opacity * (1.0 - break_progress);
	}
	COLOR = vec4(digit_color.rgb, digit_color.a * alpha * coverage);
}

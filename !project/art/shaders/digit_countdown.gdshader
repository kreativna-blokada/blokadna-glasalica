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

//distance from the point to the straight stroke line between line_start and line_end
float line_distance(vec2 point, vec2 line_start, vec2 line_end) {
	vec2 start_to_point = point - line_start;
	vec2 start_to_end = line_end - line_start;
	float along_line = clamp(dot(start_to_point, start_to_end) / dot(start_to_end, start_to_end), 0.0, 1.0);
	return length(start_to_point - start_to_end * along_line);
}

//distance from the point to the stroke arc drawn clockwise on screen from start_angle to end_angle, angles in radians, 0 = right, PI / 2 = down
float arc_distance(vec2 point, vec2 arc_center, float arc_radius, float start_angle, float end_angle) {
	vec2 center_to_point = point - arc_center;
	float middle_angle = (start_angle + end_angle) * 0.5;
	float half_sweep = (end_angle - start_angle) * 0.5;
	float angle_from_middle = mod(atan(center_to_point.y, center_to_point.x) - middle_angle + PI, TAU) - PI;
	if (abs(angle_from_middle) <= half_sweep) {
		return abs(length(center_to_point) - arc_radius);
	}

	vec2 arc_start = arc_center + arc_radius * vec2(cos(start_angle), sin(start_angle));
	vec2 arc_end = arc_center + arc_radius * vec2(cos(end_angle), sin(end_angle));
	return min(length(point - arc_start), length(point - arc_end));
}

//half the stroke thickness, in screen heights
float stroke_radius() {
	return digit_height * 0.07;
}

//half the digit height measured to the stroke middle line, in screen heights
float inner_half_height() {
	return digit_height * 0.5 - stroke_radius();
}

//point where the upper and lower bowls of 3 meet, 3 spreads around it
vec2 three_join() {
	return vec2(0.0, -inner_half_height() * 0.125);
}

//true where the digit stroke covers the point, point in screen heights around the screen center
bool digit_covers(vec2 point) {
	float inner_height = inner_half_height();
	float inner_width = digit_height * 0.275 - stroke_radius();
	float stroke_distance;

	if (digit == 1) {
		//stem with a slanted flag on top and a base bar
		float stem_x = inner_width * 0.15;
		vec2 stem_top = vec2(stem_x, -inner_height);
		stroke_distance = min(min(
			line_distance(point, stem_top, vec2(stem_x, inner_height)),
			line_distance(point, stem_top, vec2(-inner_width * 0.7, -inner_height * 0.55))),
			line_distance(point, vec2(-inner_width * 0.7, inner_height), vec2(inner_width, inner_height)));
	} else if (digit == 2) {
		//round top bowl flowing into a diagonal down to the base bar
		vec2 bowl_center = vec2(0.0, -inner_height + inner_width);
		float bowl_end_angle = radians(35.0);
		vec2 bowl_end = bowl_center + inner_width * vec2(cos(bowl_end_angle), sin(bowl_end_angle));
		vec2 bottom_left = vec2(-inner_width, inner_height);
		stroke_distance = min(min(
			arc_distance(point, bowl_center, inner_width, radians(-165.0), bowl_end_angle),
			line_distance(point, bowl_end, bottom_left)),
			line_distance(point, bottom_left, vec2(inner_width, inner_height)));
	} else {
		//smaller upper bowl over a larger lower bowl, both open to the left, with a short tongue at the join
		vec2 join = three_join();
		float upper_radius = (join.y + inner_height) * 0.5;
		float lower_radius = (inner_height - join.y) * 0.5;
		stroke_distance = min(min(
			arc_distance(point, join - vec2(0.0, upper_radius), upper_radius, radians(-155.0), radians(90.0)),
			arc_distance(point, join + vec2(0.0, lower_radius), lower_radius, radians(-90.0), radians(155.0))),
			line_distance(point, join - vec2(inner_width * 0.4, 0.0), join));
	}
	return stroke_distance <= stroke_radius();
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
		//cubic growth, slow start then rushes over the screen through the bowls join, which slides to the screen center
		float spread = 1.0 + pow(progress, 3.0) * (spread_scale - 1.0);
		vec2 digit_point = (fragment_position - screen_center) / (screen_size.y * spread) + three_join() * (1.0 - 1.0 / spread);
		coverage = float(digit_covers(digit_point));
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

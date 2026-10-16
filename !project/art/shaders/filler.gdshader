shader_type canvas_item;

//px from the left edge the fill has reached, in the node's own space
uniform float fill_edge = 0.0;
//colour the pixels take once the fill has passed over them, their alpha kept
uniform vec4 filled_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	if (local_position.x < fill_edge) {
		COLOR.rgb = filled_color.rgb;
	}
}

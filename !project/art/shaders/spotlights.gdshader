shader_type canvas_item;

//xy centre and z radius of each hole, in the dimmed rect's own pixels
uniform vec3 spotlights[8];
uniform int spotlight_count = 0;
//px over which a hole's edge fades into the full dim
uniform float edge_softness = 40.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float dim_strength = 1.0;
	for (int spotlight_index = 0; spotlight_index < spotlight_count; spotlight_index++) {
		vec3 spotlight = spotlights[spotlight_index];
		float distance_to_centre = distance(local_position, spotlight.xy);
		dim_strength = min(dim_strength, smoothstep(spotlight.z, spotlight.z + edge_softness, distance_to_centre));
	}
	COLOR.a *= dim_strength;
}

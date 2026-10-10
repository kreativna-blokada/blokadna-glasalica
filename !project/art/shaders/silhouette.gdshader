shader_type canvas_item;

//light colour the dark lines of the sprite are drawn in
uniform vec4 silhouette_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
//brightness up to which a pixel counts as a line; brighter pixels become see-through
uniform float line_brightness_limit : hint_range(0.0, 1.0) = 0.5;

varying vec4 node_tint;

void vertex() {
	node_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float texel_brightness = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
	float line_opacity = texel.a * step(texel_brightness, line_brightness_limit);
	COLOR = vec4(silhouette_color.rgb, silhouette_color.a * line_opacity) * node_tint;
}

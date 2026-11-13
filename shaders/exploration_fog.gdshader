shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D explored_map : filter_linear, repeat_disable;
uniform vec2 world_size;
uniform vec2 explorer_position;
uniform float vision_radius = 310.0;

void fragment() {
	float explored = texture(explored_map, UV).r;
	float distance_to_explorer = distance(UV * world_size, explorer_position);
	float nearby = 1.0 - smoothstep(vision_radius * 0.58, vision_radius, distance_to_explorer);
	float darkness = mix(0.97, 0.59, explored);
	darkness = mix(darkness, 0.03, nearby);
	COLOR = vec4(0.025, 0.035, 0.055, darkness);
}

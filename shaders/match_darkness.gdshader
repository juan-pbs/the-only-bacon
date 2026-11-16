shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec2 world_size;
uniform vec2 flame_position;
uniform float light_radius = 225.0;

void fragment() {
	float distance_to_flame = distance(UV * world_size, flame_position);
	float light = 1.0 - smoothstep(light_radius * 0.38, light_radius, distance_to_flame);
	float darkness = mix(0.995, 0.035, light);
	COLOR = vec4(0.016, 0.012, 0.008, darkness);
}

// NOTE: Shader automatically converted from Godot Engine 4.6.beta3's StandardMaterial3D.

shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, diffuse_toon, specular_toon, vertex_lighting;

uniform vec4 albedo : source_color;
uniform float grow : hint_range(-16.0, 16.0, 0.001);

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

uniform float t;

varying float flicker;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

uniform bool affine_mapping = false;
uniform float jitter: hint_range(0, 1) = 0.5;
uniform ivec2 resolution = ivec2(320, 240);

vec4 snap_to_position(vec4 base_position)
{
	vec4 snapped_position = base_position;
	snapped_position.xyz = base_position.xyz / base_position.w;
	
	vec2 snap_resulotion = floor(vec2(resolution) * (1.0 - jitter));
	snapped_position.x = floor(snap_resulotion.x * snapped_position.x) / snap_resulotion.x;
	snapped_position.y = floor(snap_resulotion.y * snapped_position.y) / snap_resulotion.y;
	
	snapped_position.xyz *= base_position.w;
	return snapped_position;
}

void vertex() {
	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (affine_mapping)
	{
		POSITION = snapped_position;
		POSITION /= abs(POSITION.w);
	}
	else
	{
		POSITION = snapped_position;
	}
	// Grow: Enabled
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float offset = world_pos.x + world_pos.y + world_pos.z;
	flicker = mix(hash(floor(t + offset)), hash(floor(t + offset) + 1.0), fract(t + offset));
	
	float finalgrow = flicker * grow;
	VERTEX += NORMAL * finalgrow;
}
void fragment() {
	vec2 base_uv = UV;
	ALBEDO = albedo.rgb;
	EMISSION = albedo.rgb * (emission_energy * flicker);
}

shader_type spatial;

render_mode unshaded,world_vertex_coords,cull_disabled, vertex_lighting;

instance uniform vec3 instanceCol : source_color;
uniform sampler2D color_ramp : repeat_disable, source_color, hint_default_white;
uniform sampler2D curve : repeat_disable, hint_default_white;

instance uniform vec3 instancePos;
instance uniform vec3 instanceRot;

varying vec2 clip;
varying vec2 mesh_uv;

//uniform int light_steps : hint_range(2, 8) = 4;
global uniform int dither_size : hint_range(1, 10) = 1;
uniform float alpha_scale : hint_range(0.0, 1.0) = 1.0;

global uniform float FADE_DISTANCE_START : hint_range(0.0, 100.0, 0.1);
global uniform float FADE_DISTANCE_END : hint_range(0.0, 100.0, 0.1);

global uniform float JITTER;
global uniform ivec2 RESOLUTION;

float bayer4x4(ivec2 pos)
{
	const float matrix[16] = {
		 0.0,  8.0,  2.0, 10.0,
		12.0,  4.0, 14.0,  6.0,
		 3.0, 11.0,  1.0,  9.0,
		15.0,  7.0, 13.0,  5.0
	};

	ivec2 scaled = pos / dither_size;

	int index =
		(scaled.y % 4) * 4 +
		(scaled.x % 4);

	return matrix[index] / 16.0;
}

mat4 rotation_x(float a) {
    float c = cos(a);
    float s = sin(a);

    return mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, c,   s,   0.0),
        vec4(0.0, -s,  c,   0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

mat4 rotation_y(float a) {
    float c = cos(a);
    float s = sin(a);

    return mat4(
        vec4(c,   0.0, -s,  0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(s,   0.0, c,   0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

mat4 rotation_z(float a) {
    float c = cos(a);
    float s = sin(a);

    return mat4(
        vec4(c,   s,   0.0, 0.0),
        vec4(-s,  c,   0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

mat4 translation_matrix(vec3 pos) {
    return mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(pos, 1.0)
    );
}

vec4 snap_to_position(vec4 clip_pos)
{
	 // Perspective divide -> NDC
    vec3 ndc = clip_pos.xyz / clip_pos.w;

    vec2 snap_resolution =
        floor(vec2(RESOLUTION) * (1.0 - JITTER));

    // NDC [-1,1] -> Screen [0,1]
    vec2 screen = ndc.xy * 0.5 + 0.5;

    // Snap to pixel grid
    screen = floor(screen * snap_resolution) / snap_resolution;

    // Screen [0,1] -> NDC [-1,1]
    ndc.xy = screen * 2.0 - 1.0;

    // Back to clip space
    return vec4(ndc * clip_pos.w, clip_pos.w);
}

void vertex(){
	mesh_uv = UV;
	mat4 my_model_matrix = MODEL_MATRIX;
	
	if(INSTANCE_CUSTOM.w==2.0){
		mat4 rot_mat =
		    rotation_y(instanceRot.y) *
		    rotation_x(instanceRot.x) *
		    rotation_z(instanceRot.z);
		
		mat4 tr = translation_matrix(instancePos) * rot_mat;
		my_model_matrix[1] = tr * vec4(0,1,0,1);
		my_model_matrix[2] = tr * vec4(0,-1,0,1);
	}
	
	//mat4 rot_mat =
	    //rotation_y(instanceRot.y) *
	    //rotation_x(instanceRot.x) *
	    //rotation_z(instanceRot.z);
		//
	//my_model_matrix *= rot_mat;


	vec3 a = mix(my_model_matrix[1].xyz,my_model_matrix[0].xyz,UV.x);
	vec3 b = mix(my_model_matrix[2].xyz,my_model_matrix[3].xyz,UV.x);

	UV.x = (UV.x + INSTANCE_CUSTOM.w-1.0 - 2.0)/(INSTANCE_CUSTOM.z-1.0);

	float h = textureLod(curve, vec2(UV.x), 0.0).x;//h=1.0;

	VERTEX = mix(a,b,(UV.y-0.5)*h + 0.5);


	clip.x = dot(VERTEX - INV_VIEW_MATRIX[3].xyz,cross(my_model_matrix[1].xyz - INV_VIEW_MATRIX[3].xyz,my_model_matrix[2].xyz - INV_VIEW_MATRIX[3].xyz));
	clip.y = dot(VERTEX - INV_VIEW_MATRIX[3].xyz,cross(my_model_matrix[3].xyz - INV_VIEW_MATRIX[3].xyz,my_model_matrix[0].xyz - INV_VIEW_MATRIX[3].xyz));
	
	vec4 clip_pos =
        PROJECTION_MATRIX *
        VIEW_MATRIX *
        vec4(VERTEX, 1.0);

    POSITION = snap_to_position(clip_pos);

}

void fragment(){
	float fade_distance = length(VERTEX);

	// Use interleaved gradient noise, which is fast but still looks good.
	const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
	float fade = clamp(smoothstep(FADE_DISTANCE_END, FADE_DISTANCE_START, fade_distance), 0.0, 1.0);
	// Use a hard cap to prevent a few stray pixels from remaining when past the fade-out distance.
	if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
		discard;
	}
	
	vec2 clip0 = clip;
	float ababab = clip0.x*clip0.y;

	if(ababab < 0.0) {
		if(abs(mesh_uv.x-0.5)<0.5)
			discard;
	}

	vec4 T = textureLod(color_ramp, UV, 0.0);
	ALBEDO = instanceCol;
	
	float final_alpha = T.a * alpha_scale;

	// Screen-space dithering
	ivec2 pixel_pos = ivec2(FRAGCOORD.xy);
	float threshold = bayer4x4(pixel_pos);

	// Dithered transparency
	if (final_alpha <= threshold) {
		discard;
	}
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 1.0;
}

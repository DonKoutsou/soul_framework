// ============================================================================
// RENDER MODES
// ============================================================================


render_mode
#if defined(CULLDISABLED)
	cull_disabled,
#else
	cull_back,
#endif

#ifdef FOLIAGE
	depth_prepass_alpha, 
	shadows_disabled,
	diffuse_lambert_wrap,
	specular_disabled,
#elif defined(NODEPTH)
	depth_draw_never,
	depth_test_disabled,
#endif

#ifdef UNLIT
	unshaded,
#endif

#ifdef TOON
	diffuse_toon, 
	specular_toon,
#elif !defined(FOLIAGE)
	diffuse_lambert,
	specular_schlick_ggx,
#endif
/*
#ifdef CLOUD
	fog_disabled,
#endif
*/
vertex_lighting;

// ============================================================================
// GENERAL UNIFORMS
// ============================================================================

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);

#if defined(NORM) || defined(ORM) || defined(COLTEX)
group_uniforms UV;
uniform vec3 uv1_scale = vec3(1.0,1.0,1.0);
uniform vec3 uv1_offset;
group_uniforms;
#endif

#ifdef COLBLEND
uniform float blend_value = 0.5;
#endif

#ifdef COLATLAS
uniform vec2 texture_count = vec2(4.000000, 4.000000); // Column and row count of textures in atlas
#endif

#ifdef FOLIAGE
uniform float character_height = 1.85; // Height of the camera above the ground
#endif

#ifdef CLOUD
uniform float zoom = 2.0;

uniform vec4 color_low : source_color = vec4(0.01, 0.41, 0.51, 1.0);
uniform vec4 color_mid : source_color = vec4(0.50, 0.10, 0.30, 1.0);
uniform vec4 color_high : source_color = vec4(1.0, 1.0, 1.0, 1.0);
#endif

// ============================================================================
// INSTANCE UNIFORMS
// ============================================================================

instance uniform int variant_index = 0;
#ifdef CRACK
instance uniform bool cracked = false;
#endif

#ifdef LIGHT_TOGGLE
instance uniform float instance_emission_energy_multiplier = 0.0;
#endif

#ifdef ALPHA_INSTANCE
instance uniform bool instance_alpha_mask_switch = false;
#endif

#ifdef COLMASK
instance uniform bool instance_use_color_switch = false;
instance uniform vec4 instance_mask_color : source_color = vec4(1.0,1.0,1.0, 1.0);
#endif

// ============================================================================
// LIGHTING
// ============================================================================

#ifdef DITHER_ALPHA
//uniform int light_steps : hint_range(2, 8) = 4;
global uniform int dither_size : hint_range(1, 10) = 1;
#endif

// ============================================================================
// ALPHA
// ============================================================================
#ifdef DITHER_ALPHA
uniform float alpha_scale : hint_range(0.0, 1.0) = 1.0;
#endif

#ifdef GROW
uniform float grow_amount : hint_range(-16.0, 16.0, 0.001) = 0.0;
#endif


// ============================================================================
// TEXTURES
// ============================================================================
group_uniforms Texture_Maps;
#ifdef COLTEX

	#ifdef VARIANT
		uniform sampler2DArray texture_array_albedo :
			source_color,
			filter_nearest_mipmap,
			repeat_enable;
	#else
		#ifdef COLATLAS
			uniform sampler2D texture_atlas_albedo :
				source_color,
				filter_nearest_mipmap,
				repeat_enable;
		#else
			uniform sampler2D texture_albedo :
				source_color,
				filter_nearest_mipmap,
				repeat_enable;
			#ifdef COLBLEND
				uniform sampler2D texture_blend_albedo :
					source_color,
					filter_nearest_mipmap,
					repeat_enable;
			#endif
		#endif
	#endif

	#ifdef COLMASK
		uniform sampler2D color_mask :
			filter_nearest_mipmap,
			repeat_enable;
	#endif

	#ifdef CRACK
	uniform sampler2D crack_albedo :
		source_color,
		filter_nearest_mipmap,
		repeat_enable;
	#endif
	
#endif

#ifdef NORM
	#ifdef VARIANT_N
		uniform sampler2DArray texture_array_normal :
			source_color,
			filter_nearest_mipmap,
			repeat_enable;
	#else
		uniform sampler2D texture_normal  :
			source_color,
			filter_nearest_mipmap,
			repeat_enable;
	#endif
uniform float normal_scale :
	hint_range(-16.0, 16.0);

	#ifdef CRACK
	uniform sampler2D crack_normal :
		source_color,
		filter_nearest_mipmap,
		repeat_enable;
	#endif

#endif
#ifndef UNLIT
	#ifdef ORM

	uniform sampler2D texture_orm :
		hint_roughness_g,
		filter_nearest_mipmap,
		repeat_enable;

	#else

	uniform sampler2D texture_metallic :
		hint_default_white,
		filter_nearest_mipmap,
		repeat_enable;

	uniform sampler2D texture_roughness :
		hint_default_white,
		filter_nearest_mipmap,
		repeat_enable;
	
	uniform sampler2D texture_occlusion :
		hint_default_white,
		filter_nearest_mipmap,
		repeat_enable;

	#endif
#endif

#ifdef EMM
	uniform sampler2D texture_emmisive :
	hint_default_white,
	filter_nearest_mipmap,
	repeat_enable;
#endif

#ifdef NOISE_OFFSET
	uniform sampler2D noise_texture : 
	hint_default_white,
	filter_nearest_mipmap,
	repeat_enable;
#endif

#ifdef ALPHA_SCISSOR
	uniform sampler2D alpha_Mask : hint_default_white, filter_nearest_mipmap;
#endif

#ifdef DEPTHEMM
uniform sampler2D DepthTexture : hint_depth_texture;
#endif

group_uniforms;

// ============================================================================
// PBR
// ============================================================================

#ifndef UNLIT
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float metal : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float ao : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01) = 1.0;
#endif

// ============================================================================
// EMISSION
// ============================================================================

#ifdef DEPTHEMM
uniform float FoamSize = 0.5;
uniform float FoamGlowIntensity = 0.5;
#elif defined (EMM)

uniform vec4 emission : source_color;

uniform float emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);

#endif


// ============================================================================
// BILLBOARD
// ============================================================================

#ifdef BILLBOARD

uniform bool billboard = false;
uniform bool particle_billboard = false;
uniform bool y_billboard = false;
uniform bool keep_scale;

#endif


// ============================================================================
// PS1
// ============================================================================

#ifndef PS1

global uniform float JITTER;
global uniform ivec2 RESOLUTION;

#endif

// ============================================================================
// DISTANCE FADE
// ============================================================================

#ifndef DIST_FADE
global uniform float FADE_DISTANCE_START : hint_range(0.0, 100.0, 0.1);
global uniform float FADE_DISTANCE_END : hint_range(0.0, 100.0, 0.1);
#endif

// ============================================================================
// TRIPLANAR
// ============================================================================

#ifdef TRIPLANAR

varying vec3 uv1_power_normal;
varying vec3 uv1_triplanar_pos;

uniform float uv1_blend_sharpness :
	hint_range(0.0, 150.0, 0.001);

#endif

// ============================================================================
// NOISE OFFSET
// ============================================================================

#ifdef NOISE_OFFSET
uniform float noise_strength = 1.0;
uniform float noise_scale = 0.02;
#endif

// ============================================================================
// TIME
// ============================================================================

#if defined(UV_TIME) || defined(NOISE_OFFSET) || defined(COLBLEND) || defined(FOLIAGE) || defined(CLOUD)
uniform float TimeOffset = 0.0;
uniform float TimeScale = 1.0;
#endif

// ============================================================================
// VARYINGS
// ============================================================================

varying vec3 world_pos;


// ============================================================================
// BAYER DITHER
// ============================================================================

#ifdef DITHER_ALPHA
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
#endif

// ============================================================================
// Fight BG helpers
// ============================================================================

#ifdef CLOUD
const mat2 mtx = mat2(
	vec2(0.80, -0.60),
	vec2(0.60,  0.80)
);

float rand(vec2 n) {
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 ip = floor(p);
	vec2 u = fract(p);

	u = u * u * (3.0 - 2.0 * u);

	float res = mix(
		mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
		mix(rand(ip + vec2(0.0, 1.0)),
			rand(ip + vec2(1.0, 1.0)), u.x),
		u.y
	);

	return res * res;
}

float fbm(vec2 p) {
	float t = TimeOffset * TimeScale;

	float f = 0.0;
	float speed = 0.5;
	
	f += 0.500000 * noise(p + (t * speed));
	p = mtx * p * 2.02;

	f += 0.031250 * noise(p);
	p = mtx * p * 2.01;

	f += 0.250000 * noise(p);
	p = mtx * p * 2.03;

	f += 0.125000 * noise(p);
	p = mtx * p * 2.01;

	f += 0.062500 * noise(p);
	p = mtx * p * 2.04;

	f += 0.015625 * noise(p + sin(t * speed));

	return f / 0.96875;
}

float pattern(vec2 p) {
	return fbm(p + fbm(p + fbm(p)));
}

vec4 colormap(float x, vec2 uv) {

	x *= (
		1.0 -
		pow(
			max(abs(0.5 - uv.x), abs(0.5 - uv.y)) * 2.0,
			3.0
		)
	);

	if (x < 0.0) {
		return vec4(0.0);
	}

	return mix(
		color_mid,
		color_high,
		x
	);
}
#endif

// ============================================================================
// ATLAS HELPERS
// ============================================================================

#ifdef COLATLAS
vec2 atlas_increment(vec2 pos, int step) {
    int width = int(texture_count.x);
    int height = int(texture_count.y);
    int total = width * height;

    int index = (int(pos.y) - 1) * width + (int(pos.x) - 1);

    // Increment by any amount and wrap
    index = (index + step) % total;

    int x = (index % width) + 1;
    int y = (index / width) + 1;

    return vec2(float(x), float(y));
}
#endif

// ============================================================================
// TRIPLANAR HELPERS
// ============================================================================

#ifdef TRIPLANAR

vec4 triplanar_texture(
	sampler2D tex,
	vec3 weights,
	vec3 pos
) {
	vec4 sample = vec4(0.0);

	sample += texture(tex, pos.xy) * weights.z;
	sample += texture(tex, pos.xz) * weights.y;
	sample += texture(tex, pos.zy * vec2(-1.0, 1.0)) * weights.x;

	return sample;
}

vec4 triplanar_texture_array(
	sampler2DArray tex,
	vec3 weights,
	vec3 pos
) {
	vec4 sample = vec4(0.0);

	sample += texture(tex, vec3(pos.x * weights.z, pos.y, float(variant_index)));
	sample += texture(tex, vec3(pos.x * weights.y, pos.z * weights.y, float(variant_index)));
	sample += texture(tex, vec3(pos.z * -1.0 * weights.x, pos.y * weights.x, float(variant_index)));

	return sample;
}

#endif


// ============================================================================
// PS1 POSITION SNAP
// ============================================================================

#ifndef PS1

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

#endif

#ifdef CAUSTICS
// ============================================================================
// WATER CAUSTICS
// ============================================================================

uniform sampler2D caustics_tex;
global uniform float WATER_LEVEL = 0.0;
uniform float caustics_scale = 0.1;
uniform float caustics_strength = 0.3;
uniform vec2 caustics_scroll = vec2(0.1, 0.05);

#endif

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	#ifdef FOLIAGE
	float time_offset = sin(TimeOffset * TimeScale);

	float distance_to_origin = distance(MODELVIEW_MATRIX[3].xyz, vec3(0.0, 0.0, 0.0));
	float character_distance = character_height - distance_to_origin;
	float clamped_character_distance = clamp(character_distance, 0.0, 0.5);

	float wind_modifier = 0.1 - clamped_character_distance;
	float clamped_wind_modifier = clamp(wind_modifier, 0.0, 1.0);
	float wind_offset = time_offset * clamped_wind_modifier;

	vec3 trampled_vertex_modifier = vec3(VERTEX.x, VERTEX.y * -1.0, VERTEX.z);
	float height_based_character_distance = clamped_character_distance * VERTEX.y;

	vec3 trampled_offset = trampled_vertex_modifier * vec3(height_based_character_distance);

	float height_based_wind_offset = VERTEX.y * wind_offset;
	float new_vertex_x = VERTEX.x + height_based_wind_offset;
	float new_vertex_z = VERTEX.z + height_based_wind_offset;
	vec3 new_vertex = vec3(new_vertex_x, VERTEX.y, new_vertex_z);

	VERTEX = new_vertex + trampled_offset;
	#endif

	#ifdef BILLBOARD
		if (y_billboard)
		{
			MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1], vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz)), 0.0), MODEL_MATRIX[3]);
			MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0 / length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		}
		else if (billboard)
		{
			MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		}
		else if (particle_billboard)
		{
			mat4 mat_world = mat4(
				normalize(INV_VIEW_MATRIX[0]),
				normalize(INV_VIEW_MATRIX[1]),
				normalize(INV_VIEW_MATRIX[2]),
				MODEL_MATRIX[3]);
			mat_world = mat_world * mat4(
				vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
				vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
				vec4(0.0, 0.0, 1.0, 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
			MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
		}
		if (keep_scale)
		{
			MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
				vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
				vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
				vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
		}
			
	#endif
	#ifdef NOISE_OFFSET
	vec2 global_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float noise_value = texture(noise_texture, global_position * noise_scale).r;
	float wave = sin(global_position.x * 0.2 + global_position.y * 0.2 + (TimeOffset * TimeScale) + noise_value * 10.0) * noise_strength;
	VERTEX.y += wave;
	#endif

	#ifdef GROW
	VERTEX += NORMAL * grow_amount;
	#endif

	#ifndef PS1
		vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
		POSITION = snapped_position;
	#endif
	#ifdef TRIPLANAR
		vec3 normal = NORMAL;

		TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
		TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
		TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
		TANGENT = normalize(TANGENT);

		BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
		BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
		BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
		BINORMAL = normalize(BINORMAL);

		// UV1 Triplanar: Enabled
		uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
		uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
		uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
		uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
	#endif
	
		
	#if defined(NORM) || defined(ORM) || defined(COLTEX)
		UV = UV * uv1_scale.xy + uv1_offset.xy;
	#endif
}
/*
void light()
{
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);

	float stepped = floor(NdotL * float(light_steps))
		/ float(light_steps - 1);
	
	//ivec2 pixel_pos = ivec2(FRAGCOORD.xy / pixel_size);
	
	ivec2 dither_pos = ivec2(
		int(world_pos.x * 100.0),
		int(world_pos.z * 100.0));
	
	float threshold = bayer4x4(dither_pos);

	float next_step = min(
		floor(NdotL * float(light_steps) + 1.0)
		/ float(light_steps - 1),
		1.0
	);

	float frac_part = fract(NdotL * float(light_steps));

	float dithered_light = mix(
		stepped,
		next_step,
		step(threshold, frac_part)
	);

	DIFFUSE_LIGHT += LIGHT_COLOR * dithered_light * ATTENUATION;
}
 */
void fragment() {
	#ifndef DIST_FADE
	// Distance Fade: Pixel Dither
	float fade_distance = length(VERTEX);

	// Use interleaved gradient noise, which is fast but still looks good.
	const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
	float fade = clamp(smoothstep(FADE_DISTANCE_END, FADE_DISTANCE_START, fade_distance), 0.0, 1.0);
	// Use a hard cap to prevent a few stray pixels from remaining when past the fade-out distance.
	if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
		discard;
	}
	#endif

	vec2 base_uv = UV;
	#ifdef UV_TIME
		base_uv.x += TimeOffset * TimeScale * 0.01;
	#endif
	//ALBEDO
	vec4 albedo_tex = vec4(1.0,1.0,1.0,1.0);
	#ifdef COLTEX
		#ifdef TRIPLANAR
			#ifdef VARIANT
				albedo_tex = triplanar_texture_array(texture_array_albedo, uv1_power_normal, uv1_triplanar_pos);
			#else
				
				albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
				#ifdef COLBLEND
					albedo_tex = mix(albedo_tex, triplanar_texture(texture_blend_albedo, uv1_power_normal, uv1_triplanar_pos), blend_value);
				#endif
			#endif
			
			#ifdef COLMASK
				if (instance_use_color_switch)
				{
					float color_mix_mask_tex = triplanar_texture(color_mask, uv1_power_normal, uv1_triplanar_pos).r;
					albedo_tex = mix(albedo_tex, instance_mask_color, color_mix_mask_tex);
				}
				
			#endif
			
			#ifdef DITHER_ALPHA
				// Use texture alpha * material alpha
				float final_alpha = albedo_tex.a * albedo.a * alpha_scale;

				// Screen-space dithering
				ivec2 pixel_pos = ivec2(uv1_triplanar_pos.xy);
				float threshold = bayer4x4(pixel_pos);

				// Dithered transparency
				if (final_alpha <= threshold) {
					discard;
				}
				ALPHA = 1.0;
				ALPHA_SCISSOR_THRESHOLD = 1.0;
			#elif defined(ALPHA_SCISSOR)
				float alpha_tex = 1.0;
				#ifdef ALPHA_INSTANCE
				if (instance_alpha_mask_switch)
				{
					alpha_tex = triplanar_texture(alpha_Mask, uv1_power_normal, uv1_triplanar_pos).r;
				}
				#else
				alpha_tex = triplanar_texture(alpha_Mask, uv1_power_normal, uv1_triplanar_pos).r;
				#endif
				ALPHA = albedo_tex.a * albedo.a * alpha_tex;
				ALPHA_SCISSOR_THRESHOLD = 1.0;
			#endif

			
		#else
			#ifdef VARIANT
				albedo_tex = texture(texture_array_albedo, vec3(base_uv.x, base_uv.y, float(variant_index)));
			#else
				#ifdef COLATLAS
					vec2 tile_size = 1.0 / texture_count;

					vec2 tile = atlas_increment(vec2(1.0, 1.0),variant_index) - vec2(1.0);

					vec2 modified_uv = base_uv * tile_size + tile * tile_size;

					albedo_tex = texture(texture_atlas_albedo, modified_uv);
				#else
					albedo_tex = texture(texture_albedo, base_uv);
					#ifdef COLBLEND
						vec2 revUV = UV - (TimeOffset * TimeScale * 0.01);
						albedo_tex = mix(albedo_tex, texture(texture_blend_albedo, revUV), blend_value);
					#endif
				#endif
			#endif
			
			#ifdef COLMASK
				if (instance_use_color_switch)
				{
					float color_mix_mask_tex = texture(color_mask, base_uv).r;
					albedo_tex = mix(albedo_tex, instance_mask_color, color_mix_mask_tex);
				}
			#endif
			
			#ifdef DITHER_ALPHA
				float final_alpha = albedo_tex.a * albedo.a * alpha_scale;

				// Screen-space dithering
				ivec2 pixel_pos = ivec2(FRAGCOORD.xy);
				float threshold = bayer4x4(pixel_pos);

				// Dithered transparency
				if (final_alpha <= threshold) {
					discard;
				}
				ALPHA = 1.0;
				ALPHA_SCISSOR_THRESHOLD = 1.0;
			#elif defined(ALPHA_SCISSOR)
				float alpha_tex = 1.0;
				#ifdef ALPHA_INSTANCE
				if (instance_alpha_mask_switch)
				{
					alpha_tex = texture(alpha_Mask, base_uv).r;
				}
				#else
				alpha_tex = texture(alpha_Mask, base_uv).a;
				#endif

				ALPHA = albedo_tex.a * albedo.a * alpha_tex;
				ALPHA_SCISSOR_THRESHOLD = 1.0;
			#endif
		#endif
		#ifdef CRACK
			//mix the crack texture to the albedo
			vec4 cr = vec4(1,1,1,1);
			float mixValue = 1.0;
				#ifdef TRIPLANAR
					cr = triplanar_texture(crack_albedo, uv1_power_normal, uv1_triplanar_pos);
					mixValue = cr.a;
					cr.a = 0.0;
				#else
					cr = texture(crack_albedo, base_uv);
					mixValue = cr.a;
					cr.a = 0.0;
				#endif
			if (!cracked)
			{
				mixValue = 0.0;
			}
				
			albedo_tex = mix(albedo_tex, cr, mixValue);
		#endif
	#elif defined(DITHER_ALPHA)
		float final_alpha = albedo.a * alpha_scale;

		// Screen-space dithering
		ivec2 pixel_pos = ivec2(FRAGCOORD.xy);
		float threshold = bayer4x4(pixel_pos);

		// Dithered transparency
		if (final_alpha <= threshold) {
			discard;
		}
		ALPHA = 1.0;
		ALPHA_SCISSOR_THRESHOLD = 1.0;

	#endif
	
	#ifdef CLOUD
		vec2 pixUV = floor(base_uv * 512.0) / 512.0;
		float shade = pattern(pixUV * zoom);
		albedo_tex = colormap(shade, pixUV);
	#endif
	
	#ifdef CAUSTICS
	if (world_pos.y < WATER_LEVEL)
    {
        vec2 cuv = world_pos.xz * caustics_scale +TIME * caustics_scroll;

        float caustics = texture(caustics_tex, cuv).r;

        albedo_tex *= mix(1.0,1.0 + caustics,caustics_strength);
    }
	#endif
	
	ALBEDO = albedo_tex.rgb * albedo.rgb;
	#ifdef EMM
		#ifdef DEPTHEMM
			float depthValue = texture(DepthTexture, SCREEN_UV).r;
			vec4 wPos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depthValue, 1.0);
			wPos.xyz /= wPos.w;
			float foamEffect = clamp(1.0 - smoothstep(wPos.z + FoamSize, wPos.z, VERTEX.z), 0.0, 1.0);
			float foamOpacity = 1.0 - foamEffect;
			EMISSION = vec3(foamOpacity) * FoamGlowIntensity * albedo.rgb;
		#else
			float emmMask = texture(texture_emmisive, base_uv).r;
			vec3 emm = emission.rgb * emission_energy_multiplier;
			#ifdef LIGHT_TOGGLE
				emm *= instance_emission_energy_multiplier;
			#endif
			EMISSION = mix(vec3(0,0,0), emm, emmMask);
		#endif
	#endif
	
	#ifdef NORM
		vec3 norm = vec3(1,1,1);
		#ifdef TRIPLANAR
			#ifdef VARIANT_N
				norm = triplanar_texture_array(texture_array_normal, uv1_power_normal, uv1_triplanar_pos).rgb;
			#else
				norm = triplanar_texture(texture_normal, uv1_power_normal, uv1_triplanar_pos).rgb;
			#endif
			
		#else
			#ifdef VARIANT_N
				norm = texture(texture_array_normal, vec3(base_uv.x, base_uv.y, float(variant_index))).rgb;
			#else
				norm = texture(texture_normal, base_uv).rgb;
			#endif
			
		#endif
		#ifdef CRACK

			//mix the crack texture to the normal
			vec3 crackNormal = vec3(1,1,1);
				#ifdef TRIPLANAR
					crackNormal = triplanar_texture(crack_normal, uv1_power_normal, uv1_triplanar_pos).rgb;
				#else
					crackNormal = texture(crack_normal, base_uv).rgb;
				#endif

			norm = mix(norm, crackNormal, mixValue);
		#endif
		NORMAL_MAP  = norm;
		NORMAL_MAP_DEPTH = normal_scale;
	#endif
	
	#ifndef UNLIT
		SPECULAR = specular;
		AO_LIGHT_AFFECT = ao_light_affect;
		#ifdef ORM
			#ifdef TRIPLANAR
				vec3 orm_tex = triplanar_texture(texture_orm, uv1_power_normal, uv1_triplanar_pos).rgb;
				METALLIC = orm_tex.b * metal;
				ROUGHNESS = orm_tex.g * roughness;
				AO = orm_tex.r * ao;
			#else
				vec4 orm_tex = texture(texture_orm, base_uv);
				METALLIC = orm_tex.b * metal;
				ROUGHNESS = orm_tex.g * roughness;
				AO = orm_tex.r * ao;
			#endif
		
		#else
			#ifdef TRIPLANAR
				float metaltexture = triplanar_texture(texture_metallic, uv1_power_normal, uv1_triplanar_pos).r;
				float roughnesstexture = triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos).r;
				float occlusiontexture = triplanar_texture(texture_occlusion, uv1_power_normal, uv1_triplanar_pos).r;
				
				METALLIC =  metaltexture * metal;
				ROUGHNESS = roughnesstexture * roughness;
				AO = occlusiontexture * ao;
			#else
				float metaltexture = texture(texture_metallic, base_uv).r;
				float roughnesstexture = texture(texture_roughness, base_uv).r;
				float occlusiontexture = texture(texture_occlusion, base_uv).r;
				
				METALLIC =  metaltexture * metal;
				ROUGHNESS = roughnesstexture * roughness;
				AO = occlusiontexture * ao;
			#endif
		#endif
	#endif
}

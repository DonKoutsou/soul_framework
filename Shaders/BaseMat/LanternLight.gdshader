shader_type spatial;

render_mode unshaded,cull_disabled;

uniform vec3 base_color : source_color = vec3(0.275, 0.012, 0.0);
uniform vec3 spike_color : source_color = vec3(0.808, 0.0, 0.059);

uniform float spike_density : hint_range(1.0, 128.0) = 10.0;
uniform float spike_height : hint_range(0.0, 0.2) = 0.1;
uniform float spike_width : hint_range(0.0, 0.5) = 0.1;
uniform float spike_base_width : hint_range(0.0, 0.5) = 0.2;
uniform float tip_smoothness : hint_range(0.0, 1.0) = 0.2;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.25;
uniform float max_alpha : hint_range(0.0, 1.0) = 0.05;
uniform bool grow_out = false;
uniform float TimeOffset = 0.0;

// Offset in spike-cell units. (1, 0) = shift by one cell along U, independent of density.
//vec2 spike_offset = vec2(0.0);

varying float v_mask;

float spike_pattern(vec2 uv) {
    vec2 cell_uv = fract(uv * spike_density + TimeOffset * 5.0);
    vec2 d = abs(cell_uv - 0.5);
    float dist = length(d);
    float mask = smoothstep(spike_width, spike_width + spike_base_width, dist) * (1.0 - tip_smoothness);
    mask += smoothstep(0.0, spike_width + spike_base_width, dist) * tip_smoothness;
    return mask;
}

void vertex() {
    v_mask = spike_pattern(UV) ;
    VERTEX += NORMAL * spike_height * (grow_out ? (UV.y - v_mask) : -v_mask);
}

void fragment() {
    ALBEDO = mix(base_color, spike_color, v_mask);
	if (UV.y < 0.2)
	{
		ALPHA = 0.0;
	}
	else
	{
		 ALPHA = mix(min_alpha, max_alpha, v_mask);
	}
  //EMISSION = vec3(16.0,16.0,16.0);
}
shader_type canvas_item;
uniform sampler2D ST : hint_screen_texture, filter_linear_mipmap_anisotropic;
uniform float color_offset = 1.5;
uniform float blur = 0.15;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(ST, 0));
	float offset = color_offset * pixel_size.x;
	
	// chromatic aberration
	float channel_r = textureLod(ST, SCREEN_UV + vec2(offset, 0.0), blur).r;
	float channel_g = textureLod(ST, SCREEN_UV, blur).g;
	float channel_b = textureLod(ST, SCREEN_UV + vec2(-offset, 0.0), blur).b;
	vec4 aberrate = vec4(channel_r, channel_g, channel_b, 1.0);
	
	COLOR = aberrate;
}
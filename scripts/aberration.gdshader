// chromatic aberration
//---------------------------------

shader_type canvas_item;

global uniform float aberrationStrength = 3.0f;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;



void fragment()
{
	vec2 r_displacement = vec2(aberrationStrength, 0.0);
	vec2 g_displacement = vec2(0.0, 0.0);
	vec2 b_displacement = vec2(-aberrationStrength, 0.0);
	float r = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE*r_displacement), 0.0).r;
	float g = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE*g_displacement), 0.0).g;
	float b = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE*b_displacement), 0.0).b;
	
	COLOR = vec4(r, g, b, 1.0);
}
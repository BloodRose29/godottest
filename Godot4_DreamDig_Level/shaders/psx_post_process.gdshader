shader_type canvas_item;
// Пост-процесс фильтр PSX / Retro Dither для 3D сцены в Godot 4
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float color_steps : hint_range(8.0, 64.0) = 16.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.65;

const float bayer_matrix[16] = float[16](
	 0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
	12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
	 3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
	15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 color = texture(screen_texture, uv).rgb;
	
	ivec2 coord = ivec2(FRAGCOORD.xy) % 4;
	float bayer = bayer_matrix[coord.y * 4 + coord.x] - 0.5;
	
	color += bayer * (dither_strength / color_steps);
	color = floor(color * color_steps) / color_steps;
	
	float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
	vignette = clamp(pow(16.0 * vignette, vignette_intensity), 0.0, 1.0);
	color *= vignette;
	
	COLOR = vec4(color, 1.0);
}

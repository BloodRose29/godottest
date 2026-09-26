shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting;

// PSX Ретро-шейдер с вертексным дрожанием (Wobble) для 3D хоррора в Godot 4
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float jitter_resolution : hint_range(64.0, 480.0) = 160.0;
uniform bool affine_texture_mapping = true;

varying vec4 affine_coords;

void vertex() {
	vec4 clip_space = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	
	// Вертексный снаппинг к сетке пикселей
	vec2 grid = vec2(jitter_resolution, jitter_resolution * (VIEWPORT_SIZE.y / VIEWPORT_SIZE.x));
	clip_space.xy = floor(clip_space.xy / clip_space.w * grid) / grid * clip_space.w;
	
	POSITION = clip_space;
	
	if (affine_texture_mapping) {
		affine_coords = vec4(UV * clip_space.w, 0.0, clip_space.w);
	}
}

void fragment() {
	vec2 uv = affine_texture_mapping ? (affine_coords.xy / affine_coords.w) : UV;
	vec4 tex = texture(albedo_texture, uv) * tint_color;
	
	ALBEDO = tex.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

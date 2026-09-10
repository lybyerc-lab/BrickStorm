shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 brick_color : source_color = vec4(0.85, 0.15, 0.15, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.22;
uniform float specular : hint_range(0.0, 1.0) = 0.65;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	ALBEDO = brick_color.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	METALLIC = metallic;
	
	// Classic molded plastic rim highlight
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = brick_color.rgb * fresnel * rim_strength * 0.4;
}

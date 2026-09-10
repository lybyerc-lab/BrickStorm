shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 tornado_pos = vec3(0.0, 0.0, 0.0);
uniform float show_risk_bands = 1.0;

// Risk band radii
const float R_RED = 15.0;
const float R_ORANGE = 25.0;
const float R_YELLOW = 35.0;

// Colors
const vec3 COLOR_RED_DIRT = vec3(0.52, 0.24, 0.14);
const vec3 COLOR_WHEAT = vec3(0.72, 0.58, 0.28);
const vec3 COLOR_ROAD = vec3(0.40, 0.22, 0.12);
const vec3 COLOR_SAGE = vec3(0.42, 0.45, 0.28);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Procedural grid & fields
	float field_x = floor(world_pos.x / 40.0);
	float field_z = floor(world_pos.z / 40.0);
	float field_hash = fract(sin(field_x * 12.9898 + field_z * 78.233) * 43758.5453);
	
	// Base soil / crop blend
	vec3 base_col = mix(COLOR_RED_DIRT, COLOR_WHEAT, smoothstep(0.3, 0.7, field_hash));
	
	// Farm road strip through x = 0 or z grid
	float road_dist = abs(world_pos.x);
	if (road_dist < 4.0) {
		base_col = mix(COLOR_ROAD, base_col, smoothstep(2.5, 4.0, road_dist));
		// Tire ruts
		float rut = abs(abs(world_pos.x) - 1.8);
		if (rut < 0.6) {
			base_col *= 0.85;
		}
	}
	
	// Tractor furrow stripes across fields
	float furrow = sin(world_pos.z * 1.5) * 0.04;
	base_col += vec3(furrow);
	
	// Risk bands calculation
	vec3 final_color = base_col;
	vec3 emission_color = vec3(0.0);
	
	if (show_risk_bands > 0.5) {
		float d = length(world_pos.xz - tornado_pos.xz);
		
		// Red zone (< 15m)
		if (d < R_RED) {
			final_color = mix(final_color, vec3(0.9, 0.15, 0.15), 0.25);
		}
		// Red/Orange boundary ring
		float red_edge = abs(d - R_RED);
		if (red_edge < 0.6) {
			float intensity = 1.0 - smoothstep(0.0, 0.6, red_edge);
			emission_color += vec3(1.0, 0.1, 0.1) * intensity * 0.8;
		}
		
		// Orange zone (15m - 25m)
		if (d >= R_RED && d < R_ORANGE) {
			final_color = mix(final_color, vec3(0.95, 0.5, 0.1), 0.18);
		}
		// Orange/Yellow boundary ring
		float orange_edge = abs(d - R_ORANGE);
		if (orange_edge < 0.6) {
			float intensity = 1.0 - smoothstep(0.0, 0.6, orange_edge);
			emission_color += vec3(1.0, 0.55, 0.1) * intensity * 0.8;
		}
		
		// Yellow zone (25m - 35m)
		if (d >= R_ORANGE && d < R_YELLOW) {
			final_color = mix(final_color, vec3(0.9, 0.85, 0.2), 0.12);
		}
		// Yellow/Green boundary ring
		float yellow_edge = abs(d - R_YELLOW);
		if (yellow_edge < 0.6) {
			float intensity = 1.0 - smoothstep(0.0, 0.6, yellow_edge);
			emission_color += vec3(0.95, 0.9, 0.1) * intensity * 0.8;
		}
	}
	
	ALBEDO = final_color;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
	EMISSION = emission_color;
}

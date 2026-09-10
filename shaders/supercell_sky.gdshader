shader_type sky;

uniform vec3 sky_dark : source_color = vec3(0.08, 0.12, 0.11);     // Bruised storm charcoal
uniform vec3 sky_green_hail : source_color = vec3(0.11, 0.18, 0.13); // Infamous green hail-core
uniform vec3 horizon_glow : source_color = vec3(0.72, 0.52, 0.22);  // Low prairie sun beneath cloud deck
uniform float lightning_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float wind_time = 0.0;

// Simple 2D hash for cloud turbulence
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = rot * p * 2.0;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float altitude = clamp(dir.y, 0.0, 1.0);
	
	// Cylindrical mapping for clouds
	vec2 uv = vec2(atan(dir.z, dir.x), dir.y / (max(0.01, dir.y) + 0.3));
	uv.x += TIME * 0.03 + wind_time * 0.02;
	uv.y += TIME * 0.01;
	
	// Multi-octave swirling mesocyclone clouds
	float storm_clouds = fbm(uv * 3.5);
	float cloud_detail = fbm(uv * 8.0);
	
	// Base sky color transition: horizon warm amber -> menacing green hail core -> charcoal zenith
	vec3 col = mix(horizon_glow, sky_green_hail, smoothstep(0.0, 0.25, altitude));
	col = mix(col, sky_dark, smoothstep(0.2, 0.8, altitude));
	
	// Dark heavy cloud masses
	col *= mix(0.7, 1.3, storm_clouds);
	col += vec3(cloud_detail * 0.08);
	
	// Lightning illumination bursts
	if (lightning_intensity > 0.01) {
		vec3 lightning_color = vec3(0.9, 0.95, 1.0);
		float flash = lightning_intensity * (0.6 + 0.4 * storm_clouds);
		col = mix(col, lightning_color, flash * 0.75);
	}
	
	COLOR = col;
}

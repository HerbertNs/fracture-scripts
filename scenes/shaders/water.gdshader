shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec4 water_color : source_color;
uniform sampler2D wave_noise : repeat_enable;
uniform float ripple_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float ripple_frequency : hint_range(0.0, 20.0) = 5.0;
uniform float ripple_speed : hint_range(0.0, 2.0) = 0.5;

void fragment() {
	// Base water wave distortion
	vec2 water_wave = (texture(wave_noise, UV + TIME * 0.02).rg - 0.5) * 0.02;
	
	// Multi-frequency ripple effect for more natural look
	float ripple_mask = 1.0 - smoothstep(0.0, 0.3, UV.y); // Effect strongest at top, fades downward
	
	// First ripple frequency
	float ripple1 = sin(UV.x * ripple_frequency + TIME * ripple_speed) * ripple_intensity;
	
	// Second ripple frequency (slightly different)
	float ripple2 = cos(UV.x * (ripple_frequency * 0.7) + TIME * (ripple_speed * 1.3)) * ripple_intensity * 0.7;
	
	// Third ripple frequency (even smaller)
	float ripple3 = sin(UV.x * (ripple_frequency * 1.5) + TIME * (ripple_speed * 0.7)) * ripple_intensity * 0.5;
	
	// Combine ripples with mask
	float combined_ripple = (ripple1 + ripple2 + ripple3) * ripple_mask;
	
	// Combine both distortions
	vec2 distortion = water_wave + vec2(0.0, combined_ripple);
	
	vec2 uv = vec2(SCREEN_UV.x, SCREEN_UV.y - UV.y) + distortion;
	vec4 color = texture(screen_texture, uv);
	float mix_value = 1.0 - UV.y;
	
	float avg_color = (color.r + color.g + color.b) / 3.0;
	avg_color = pow(avg_color, 1.4);
	
	mix_value += avg_color;
	mix_value = clamp(mix_value, 0.0, 0.7);
	
	COLOR = mix(water_color, color, mix_value);
}
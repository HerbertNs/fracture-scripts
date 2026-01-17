shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Scanline parameters
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float scanline_thickness : hint_range(0.1, 2.0) = 1.0;

// Phosphor/Gamma parameters
uniform float gamma : hint_range(0.5, 3.0) = 2.2;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

// Bloom/Glow parameters
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.4;
uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float bloom_radius : hint_range(0.5, 4.0) = 1.5;

// Noise parameters
uniform float noise_intensity : hint_range(0.0, 0.1) = 0.02;

// Automatically gets the screen resolution
const vec2 screen_resolution = vec2(160.0, 120.0);

// Random function for noise
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Adjust saturation
vec3 adjust_saturation(vec3 color, float sat) {
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(luminance), color, sat);
}

// Gaussian blur sample for bloom using SCREEN_TEXTURE
vec3 sample_bloom(vec2 uv, vec2 direction) {
    vec3 color = vec3(0.0);
    
    // 5-tap gaussian blur
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    
    for (int i = 0; i < 5; i++) {
        vec2 offset = direction * float(i) / screen_resolution * bloom_radius;
        color += texture(SCREEN_TEXTURE, uv + offset).rgb * weights[i];
        if (i != 0) {
            color += texture(SCREEN_TEXTURE, uv - offset).rgb * weights[i];
        }
    }
    
    return color;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 original_color = texture(SCREEN_TEXTURE, uv).rgb;
    
    // Apply gamma correction (phosphor response)
    vec3 gamma_color = pow(original_color, vec3(1.0 / gamma));
    gamma_color = pow(gamma_color * contrast, vec3(gamma));
    
    // Apply saturation adjustment
    gamma_color = adjust_saturation(gamma_color, saturation);
    
    // Scanlines effect
    float scanline = sin(uv.y * screen_resolution.y * 3.14159 * scanline_thickness);
    scanline = 1.0 - (scanline * 0.5 + 0.5) * scanline_intensity;
    
    vec3 scanlined_color = gamma_color * scanline;
    
    // Create bloom mask (bright areas)
    float brightness = dot(original_color, vec3(0.299, 0.587, 0.114));
    float bloom_mask = smoothstep(bloom_threshold - 0.1, bloom_threshold + 0.1, brightness);
    
    // Sample bloom (horizontal and vertical blur)
    vec3 bloom_h = sample_bloom(uv, vec2(1.0, 0.0));
    vec3 bloom_v = sample_bloom(uv, vec2(0.0, 1.0));
    vec3 bloom = (bloom_h + bloom_v) * 0.5;
    
    // Apply bloom threshold
    bloom *= bloom_mask;
    
    // Add bloom to the final color
    vec3 final_color = scanlined_color + bloom * bloom_intensity;
    
    // Add subtle noise
    float noise = random(uv + TIME * 0.1) * 2.0 - 1.0;
    final_color += noise * noise_intensity;
    
    // Subtle vignette for that CRT feel
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.3;
    final_color *= vignette;
    
    // Clamp to prevent over-brightness
    final_color = clamp(final_color, 0.0, 1.0);
    
    COLOR = vec4(final_color, 1.0);
}
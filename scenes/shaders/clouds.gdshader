shader_type canvas_item;


// Global
global uniform vec4  WORLD_LIGHT:          source_color;
global uniform vec4  WORLD_HORIZON_COLOUR: source_color;
global uniform vec4  WORLD_SKY_COLOUR:     source_color;
global uniform float WORLD_CLOUD_ENERGY;
global uniform float WORLD_CLOUD_VIBRANCY;

// Universal
uniform float wind_offset;
uniform vec3  sun_position = vec3(-1.0, 5.0, 1.0);

// Shape
uniform float noise_2D_factor_slope:  hint_range(0.0, 1.0) = 0.25;
uniform float noise_2D_factor_detail: hint_range(0.0, 1.0) = 0.6;
uniform float wind_sheer_1D:          hint_range(0.0, 1.0) = 0.5;   // With how much resistance the 1D cloud features move with the rest of the cloud.
uniform float wind_sheer_2D:          hint_range(0.0, 1.0) = 0.5;   // With how much resistance the 2D cloud features move with the rest of the cloud.

// Base
uniform bool draw_cloud_base = false;

// Texture
uniform float wind_sheer_texture_detail: hint_range(0.0, 1.0) = 0.0;   // This is entirely based off of the prior wind sheer values.
uniform float wind_sheer_texture_normal: hint_range(0.0, 1.0) = 0.0;
uniform float cloud_sky_influence:       hint_range(0.0, 1.0) = 0.0;
uniform float height_shade_factor:       hint_range(0.0, 1.0) = 0.5;
uniform float occlusion_strength:        hint_range(0.0, 1.0) = 0.2;

uniform int steps = 200;

// Samplers
uniform sampler2D weather_coverage:  filter_linear; // Should be a curve texture. These graphs must range between 0-1 otherwise there will be problems with texturing the clouds.
uniform sampler2D weather_stability: filter_linear; // Should be a curve texture. These graphs must range between 0-1 otherwise there will be problems with texturing the clouds.
uniform sampler2D map_height:        filter_linear;
uniform sampler2D map_detail:        filter_linear;
uniform sampler2D map_normals:       filter_linear;

// Constants
const float STABILITY_COEFF  = 0.33; // We multiple the stability curve with 1/3 so that a stable cloud scape is a third of the size of an unstable one.
const float MAX_DETAIL_SCALE = 0.2;
const float MIN_DETAIL_SCALE = 0.1;
const float MAX_BASE_SIZE    = 0.1;  // What is the maximum cloud base size used for the largest clouds.

struct Curve {
	float height;
	float height_static;   // Used for texturing.
	float coverage;
	float stability;
};


// Colour Enforcement - Juice56 Palette
vec3 colour_enforce(vec3 tex_colour) {
	vec3 palette[56];

	palette[0] = vec3(1.0, 1.0, 1.0);
	palette[1] = vec3(1.0, 1.0, 1.0);
	palette[2] = vec3(0.784, 0.882, 0.922);
	palette[3] = vec3(0.647, 0.745, 0.804);
	palette[4] = vec3(0.471, 0.569, 0.647);
	palette[5] = vec3(0.333, 0.392, 0.49);
	palette[6] = vec3(0.216, 0.255, 0.353);
	palette[7] = vec3(0.098, 0.118, 0.235);
	palette[8] = vec3(0.078, 0.275, 0.353);
	palette[9] = vec3(0.059, 0.451, 0.451);

	palette[10] = vec3(0.059, 0.647, 0.412);
	palette[11] = vec3(0.255, 0.804, 0.451);
	palette[12] = vec3(0.451, 1.0, 0.451);
	palette[13] = vec3(0.863, 0.608, 0.471);
	palette[14] = vec3(0.698, 0.384, 0.278);
	palette[15] = vec3(0.549, 0.235, 0.196);
	palette[16] = vec3(0.353, 0.078, 0.137);
	palette[17] = vec3(0.216, 0.039, 0.078);
	palette[18] = vec3(1.0, 0.824, 0.647);
	palette[19] = vec3(0.961, 0.647, 0.431);

	palette[20] = vec3(0.902, 0.431, 0.275);
	palette[21] = vec3(0.765, 0.255, 0.176);
	palette[22] = vec3(0.549, 0.137, 0.137);
	palette[23] = vec3(0.255, 0.0, 0.255);
	palette[24] = vec3(0.49, 0.0, 0.255);
	palette[25] = vec3(0.667, 0.078, 0.235);
	palette[26] = vec3(0.843, 0.176, 0.176);
	palette[27] = vec3(0.941, 0.412, 0.137);
	palette[28] = vec3(1.0, 0.667, 0.196);
	palette[29] = vec3(1.0, 0.902, 0.353);

	palette[30] = vec3(0.745, 0.843, 0.176);
	palette[31] = vec3(0.392, 0.647, 0.118);
	palette[32] = vec3(0.137, 0.49, 0.078);
	palette[33] = vec3(0.059, 0.333, 0.098);
	palette[34] = vec3(0.059, 0.196, 0.137);
	palette[35] = vec3(0.51, 1.0, 0.882);
	palette[36] = vec3(0.255, 0.843, 0.843);
	palette[37] = vec3(0.078, 0.627, 0.804);
	palette[38] = vec3(0.078, 0.412, 0.765);
	palette[39] = vec3(0.059, 0.216, 0.608);

	palette[40] = vec3(0.059, 0.059, 0.412);
	palette[41] = vec3(0.235, 0.118, 0.549);
	palette[42] = vec3(0.392, 0.176, 0.706);
	palette[43] = vec3(0.627, 0.255, 0.843);
	palette[44] = vec3(0.902, 0.353, 0.902);
	palette[45] = vec3(1.0, 0.549, 0.784);
	palette[46] = vec3(0.294, 0.078, 0.235);
	palette[47] = vec3(0.51, 0.039, 0.392);
	palette[48] = vec3(0.706, 0.137, 0.431);
	palette[49] = vec3(0.902, 0.314, 0.471);

	palette[50] = vec3(1.0, 0.549, 0.549);
	palette[51] = vec3(1.0, 0.804, 0.706);
	palette[52] = vec3(0.902, 0.608, 0.588);
	palette[53] = vec3(0.745, 0.412, 0.451);
	palette[54] = vec3(0.588, 0.275, 0.373);
	palette[55] = vec3(0.431, 0.157, 0.314);


	float min_diff   = 1000.0;
	vec3  min_colour = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < palette.length(); i++) {

		float curr_dist = distance(palette[i], tex_colour);
		if (curr_dist < min_diff) {
			min_diff   = curr_dist;
			min_colour = palette[i];
		}
	}

	return min_colour;
}

// Calculates the normals of a given position.
// This can be used for additional shading effects.
vec3 get_normal(vec2 pos, vec2 pixel_size) {
	const float H = 200.0;

	// Convert the pixel size 2D vector to a 3D vector for ease of operations.
	// Whenever we index from the 'z' value, we just index a 0 at that position.
	vec3 pix = vec3(pixel_size, 0.0);

	float left  = H * texture(map_normals, pos - pix.xz).r;
	float right = H * texture(map_normals, pos + pix.xz).r;

	float down = H * texture(map_normals, pos - pix.zy).r;
	float up   = H * texture(map_normals, pos + pix.zy).r;

	return normalize(vec3(left - right, down - up, 1.0));
}

// Used to generate the base heightmap of the clouds along with the derivative.
// This heightmap is technically 2D since it allows the extrusion of heightmaps.
Curve gen_curve(vec2 uv, vec2 uv_absolute, vec2 pixel_size) {

	// Sample the current pixel at the heightmap.
	float n = mix(
		texture(map_height, fract(vec2(uv.x, 0.0))).r,
		texture(map_height, fract(uv)).r,
		noise_2D_factor_slope   // We may wish to sample 2D noise instead of 1D noise to include overhangs.
	);

	// Sample the coverage and stability values.
	float coverage  = texture(weather_coverage,  vec2(uv_absolute.x, 0.0)).r;
	float stability = texture(weather_stability, vec2(uv_absolute.x, 0.0)).r;

	// Create two graphs that describe different cloudscapes; one for an unstable atmosphere and another for a stable atmosphere.
	// Let these be known as Gu, and Gs respectively.
	float gu = pow(n, 5.0);
	float gs = STABILITY_COEFF * mix(2.0, 1.0, n) * (n + mix(0.0, 0.1, coverage));

	// Define a final graph and subtract the inverse coverage from it.
	float height_base = mix(gu, gs, stability);
	float height      = clamp(height_base - (1.0 - coverage), -MAX_DETAIL_SCALE, 1.0);   // Clamp it to the negated version of the max detail scale. We clamp it to zero later.

	return Curve(height, height, coverage, stability);
}

// Creates the cloud shape itself.
Curve shape_cloud(vec2 uv, vec2 pixel_size) {

	// Create a set of UV maps which will be used throughout the function.
	vec2 uv_with_wind    = uv + vec2(wind_offset, 0.0);
	vec2 uv_detail_1D    = vec2(mix(uv_with_wind, uv, wind_sheer_1D).x, 0.0);
	vec2 uv_detail_2D    = mix(uv_with_wind, uv, wind_sheer_2D);
	vec2 uv_detail_1D_ww = vec2(uv_with_wind.x, 0.0);   // With Wind
	vec2 uv_detail_2D_ww = uv_with_wind;                // With Wind

	Curve base_cloud = gen_curve(uv_with_wind, uv, pixel_size);

	// Add some detail to the cloud's heightmap.
	float detail_scale = mix(MAX_DETAIL_SCALE, MIN_DETAIL_SCALE, base_cloud.stability);

	float detail_y1    = texture(map_detail, fract(uv_detail_1D)).r;
	float detail_xy    = texture(map_detail, fract(uv_detail_2D)).r;
	float detail_y1_ww = texture(map_detail, fract(uv_detail_1D_ww)).r;   // With Wind
	float detail_xy_ww = texture(map_detail, fract(uv_detail_2D_ww)).r;   // With Wind

	float detail    = mix(detail_y1,    detail_xy,    noise_2D_factor_detail) * detail_scale;
	float detail_ww = mix(detail_y1_ww, detail_xy_ww, noise_2D_factor_detail) * detail_scale;   // With Wind

	if (base_cloud.height > -detail_scale) {   // Clamping this to zero would've removed necessary detail around the base of the cloud.
		base_cloud.height        += detail;
		base_cloud.height_static += detail_ww;
	}
	base_cloud.height        = max(base_cloud.height,        0.0);   // Clamp it to zero now hat we've dealt with the cloud details.
	base_cloud.height_static = max(base_cloud.height_static, 0.0);

	return base_cloud;
}

// Shades and colours the cloud.
vec4 shade_cloud(Curve curve, vec2 uv, vec2 pixel_size) {
	vec2  uv_with_wind = uv + vec2(wind_offset, 0.0);
	float occlusion   = 0.0;

	// Raycast to procedurally shade the clouds.
	float bump_occlusion    = texture(map_normals, fract(mix(uv_with_wind, uv, wind_sheer_texture_detail))).r;
	vec3  ray_pos_occlusion = vec3(uv_with_wind.x, bump_occlusion, uv_with_wind.y);
	vec3  ray_dir_occlusion = (sun_position - ray_pos_occlusion) / float(steps);

	for (int i = 0; i < steps; i++) {
		ray_pos_occlusion += ray_dir_occlusion;  // Step towards the sun.

		// Check the height at the new location.
		float height = texture(map_normals, fract(ray_pos_occlusion.xz)).r;
		if (height > ray_pos_occlusion.y) {
			occlusion = 1.0;   // We are inside of a shadow.
			break;
		}
		if (ray_pos_occlusion.y > 1.0)
			break;
	}

	// Calculate the diffuse lighting factor based on the normal and direction vectors
	// We have to compute the ray position/direction again because we're using a different wind sheer variable.
	float bump_diffuse    = texture(map_normals, fract(mix(uv_with_wind, uv, wind_sheer_texture_normal))).r;
	vec3  ray_pos_diffuse = vec3(uv_with_wind.x, bump_diffuse, uv_with_wind.y);
	vec3  ray_dir_diffuse = (sun_position - ray_pos_diffuse) / float(steps);

	float diffuse = clamp(dot(get_normal(fract(mix(uv_with_wind, uv, wind_sheer_texture_normal)), pixel_size), 1.0 - ray_dir_diffuse), 0.0, 1.0);

	// As it turns out, using the height actually provides a good base shade value due to the noise textures.
	// We also normalize this value by clamping it within the current graph's range (meaning that small clouds will be as dynamic as big clouds).
	// Explanations:
	// A: Block out diffuse lighting towards the base to prevent oversaturated texturing.
	// B: Ensure that a good amount of the cloud gets textured with the height offset on the interpolation graph.
	// C: Ensure that all clouds big or small get diffuse lighting.
	vec3 base_shade  = vec3(mix(curve.height_static, curve.height, wind_sheer_texture_normal) * mix(mix(6.0, 14.0, curve.stability), 1.0, curve.coverage)) - occlusion * occlusion_strength;
	     base_shade *= mix(1.0, 1.0 - uv.y, height_shade_factor);
	     base_shade += (1.0 - diffuse) * mix(-0.2, 0.0 /* A */, min(max(uv.y - (0.5 /* B */ * mix(3.0, 1.0, curve.coverage) /* C */), 0.0) * 10.0, 1.0));   // An equation that tries to balance the diffuse and base lighting models.

	// Draw the clouds with a base if required.
	if (draw_cloud_base) {

		// Determine the region that we are to draw the cloud base for.
		// This is relient on the height of the curve, with the stability coefficient in the stability graph partially cancelled out.
		// We also add a buffer to prevent the base from clipping out of bounds. This may need to change if the way that the width is calculated changes.
		float height               = 1.0 - uv.y;
		float cloud_base_threshold = MAX_BASE_SIZE + 0.02;   // Buffer added here.
		float cloud_base_width     = mix(0.0, MAX_BASE_SIZE, mix(curve.height, curve.height / (STABILITY_COEFF * 1.5), texture(weather_stability, uv).r));
		if (height < cloud_base_threshold) {
			vec3 old_base_shade = base_shade;

			// Add two swaths of the detail texture to the top of the base's rim and the bottom.
			float detail_scale = mix(MAX_DETAIL_SCALE, MIN_DETAIL_SCALE, curve.stability);

			float detail_y1 = texture(map_detail, fract(vec2(uv_with_wind.x, 0.0))).r;
			float detail_xy = texture(map_detail, fract(uv_with_wind)).r;
			float detail    = mix(detail_y1, detail_xy, noise_2D_factor_detail) * detail_scale;

			// Draw the two main swaths across the base, and two smaller swathes in the actual base as highlights.
			float base_start = cloud_base_threshold - (detail * 0.15);
			if (height >= base_start)  // Swath 1 Start
				base_shade = base_shade;
			else if (height >= cloud_base_threshold - (cloud_base_width * 0.1) - (detail * 0.05))  // Swath 1 End - Swath 2 Start
				base_shade = vec3(0.0);
			else if (height >= cloud_base_threshold - (cloud_base_width * 0.25) - (detail * 0.15))   // Highlight Swath 1 Start
				base_shade = vec3(0.3);
			else if (height >= cloud_base_threshold - (cloud_base_width * 0.75) - (detail * 0.05))   // Highlight Swath 1 End
				base_shade = vec3(0.0);
			else if (height >= cloud_base_threshold - cloud_base_width - (detail * 0.05))   // Highlight Swath 2 Start
				base_shade = vec3(0.3);
			else if (height >= cloud_base_threshold - cloud_base_width - (detail * 0.1))   // Highlight Swath 1 End
				base_shade = vec3(0.0);
			else  // Swath 2 End
				return vec4(0.0);

			base_shade -= (1.0 - diffuse) * 0.1;   // Make the swathes look a little more organic by adding some texture to them.
			base_shade = mix(base_shade, old_base_shade, clamp((height - base_start) / (cloud_base_threshold - base_start), 0.0, 1.0));   // Blend the base with the rest of the cloud.
		}
	}

	base_shade   = colour_enforce(base_shade);
	float factor = ((base_shade.r + base_shade.g + base_shade.b) / 3.0);

	base_shade.rgb = mix(
		WORLD_HORIZON_COLOUR,
		mix(WORLD_LIGHT, WORLD_SKY_COLOUR, cloud_sky_influence),
		factor
	).rgb * (WORLD_CLOUD_ENERGY + WORLD_CLOUD_VIBRANCY);

	return vec4(base_shade, 1.0);
}

// Called for every pixel the material is visible on.
void fragment() {
	float height = 1.0 - UV.y;
	Curve curve  = shape_cloud(UV, SCREEN_PIXEL_SIZE);
	if (height > curve.height)
		COLOR = vec4(0.0);
	else {
		COLOR = shade_cloud(curve, UV, SCREEN_PIXEL_SIZE);
	}

	// SATURATION
	// positive = more saturation
	// negative = less saturation
	// 0.0 = unchanged
	// -1.0 = grayscale
	// < -1.0 = color inversion
	float saturation_scale = WORLD_CLOUD_VIBRANCY;
	float average = (COLOR.x + COLOR.y + COLOR.z) / 3.0;
	float xd = average - COLOR.r;
    float yd = average - COLOR.g;
    float zd = average - COLOR.b;
    COLOR.r += xd * -saturation_scale;
    COLOR.g += yd * -saturation_scale;
    COLOR.b += zd * -saturation_scale;
}

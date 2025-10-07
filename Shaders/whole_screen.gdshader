shader_type canvas_item;

// 0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset, 1 = midnight
uniform float time_of_day : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// Night gets slightly darker and cooler; keep <= 1.0 to avoid clipping
uniform vec3 night_mul = vec3(0.80, 0.84, 1.00);
// Dusk/dawn get a subtle warm bias (also <= 1.0)
uniform vec3 dawn_mul  = vec3(1.00, 0.95, 0.92);

// Night-only shaping (mild, to preserve palette)
uniform float contrast_night : hint_range(0.5, 1.5) = 1.02; // around 0.5
uniform float gamma_night    : hint_range(0.5, 1.5) = 1.06; // >1 darkens

// Optional stable dithering to reduce banding in large flats (0 disables)
uniform float dither_strength : hint_range(0.0, 1.0) = 0.0; // ~0.3 is subtle

// Curves: day peaks at noon; dusk/dawn peaks at sunrise/sunset
float day_curve(float t) { return 0.5 - 0.5 * cos(6.28318530718 * t); }
float dusk_dawn_curve(float t) { return abs(sin(6.28318530718 * t)); }

// Simple, stable hash per screen pixel
float hash12(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 col = texture(SCREEN_TEXTURE, uv).rgb;

    float day   = day_curve(time_of_day);
    float night = 1.0 - day;
    float dusk  = dusk_dawn_curve(time_of_day);

    // Multiplicative tint: identity at noon, cool at night, warm at dusk/dawn
    vec3 mul = mix(vec3(1.0), night_mul, night);
    mul = mix(mul, dawn_mul, dusk * (1.0 - night)); // warm only around dawn/sunset
    col *= mul;

    // Night-only shaping (kept mild to preserve pixel colors)
    if (night > 0.0) {
        // Contrast around mid-grey
        col = clamp((col - 0.5) * mix(1.0, contrast_night, night) + 0.5, 0.0, 1.0);
        // Gamma >1 darkens; blend by night amount
        float g = mix(1.0, gamma_night, night);
        col = pow(max(col, 0.0), vec3(g));
    }

    // Optional stable dithering (screen-space fixed; avoids shimmer)
    if (dither_strength > 0.0) {
        vec2 pix = floor(SCREEN_UV / SCREEN_PIXEL_SIZE); // integer pixel coords
        float n  = hash12(pix) - 0.5;
        col += n * (dither_strength / 255.0);
        col = clamp(col, 0.0, 1.0);
    }

    COLOR = vec4(col, 1.0);
}

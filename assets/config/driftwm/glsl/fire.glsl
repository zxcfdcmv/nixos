// Iridescent pearl silk — cosine palette over warped FBM, zero thresholds.
precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;

float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash1(i);
    float b = hash1(i + vec2(1.0, 0.0));
    float c = hash1(i + vec2(0.0, 1.0));
    float d = hash1(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Cosine palette: color is a pure wave in t — no steps, no smoothstep
// thresholds, the gradient is mathematically continuous everywhere.
// Tuned to champagne / pearl / lavender / mint iridescence.
vec3 pearlPalette(float t) {
    vec3 a = vec3(0.56, 0.52, 0.56);   // base — soft pearl grey
    vec3 b = vec3(0.36, 0.30, 0.34);   // amplitude
    vec3 c = vec3(1.00, 1.00, 1.00);   // frequency
    vec3 d = vec3(0.00, 0.22, 0.42);   // phase shift between channels
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 canvas = (v_coords * size + u_camera) * 0.0022;

    // Single domain warp: bends the flow without nesting artifacts.
    vec2 warp = vec2(fbm(canvas + vec2(3.1, 7.7)),
                     fbm(canvas + vec2(8.4, 2.9)));
    float f = fbm(canvas + 1.8 * warp);

    // Remap: fbm output hugs the middle, stretch it across the full [0,1]
    // so the palette wave travels through all its hues, not just one slope.
    float t = clamp((f - 0.25) * 2.2, 0.0, 1.0);

    // Fine silk grain: high-frequency fbm nudges the palette coordinate,
    // giving the surface woven texture instead of flat color areas.
    t += (fbm(canvas * 6.0) - 0.5) * 0.06;

    vec3 col = pearlPalette(t);

    // Sheen: ridged fbm as soft specular highlights drifting across the silk.
    float sheen = fbm(canvas * 2.5 + warp * 3.0);
    sheen = pow(1.0 - abs(sheen * 2.0 - 1.0), 3.0);
    col += vec3(0.18) * sheen;

    // Dithering: sub-perceptual hash noise masks 8-bit color banding,
    // this is what finally kills any residual visible gradient steps.
    col += (hash1(gl_FragCoord.xy) - 0.5) * (2.0 / 255.0);

    gl_FragColor = vec4(col, 1.0);
}

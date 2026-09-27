// Stacked Liquid Chrome — 双层重叠晶流（高雅明亮空间感）
#extension GL_OES_standard_derivatives : enable
precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;

float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash1(i), hash1(i + vec2(1.0, 0.0)), f.x), 
               mix(hash1(i + vec2(0.0, 1.0)), hash1(i + vec2(1.0, 1.0)), f.x), f.y);
}

// 分形噪声，优化了旋转矩阵以减少人造感
float fbm(vec2 p) {
    float v = 0.0; float a = 0.5;
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p); p = rot * p * 2.2; a *= 0.48;
    }
    return v;
}

// 沿用原版最棒的调色盘，但增加一个亮度系数控制
vec3 chromePalette(float t, float brightness) {
    vec3 a = vec3(0.65, 0.65, 0.68) * brightness; 
    vec3 b = vec3(0.35, 0.35, 0.32) * brightness; 
    vec3 c = vec3(1.20, 1.10, 1.00); 
    vec3 d = vec3(0.10, 0.25, 0.45); 
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    // 基础画布缩放
    vec2 canvas = (v_coords * size + u_camera) * 0.0025;

    vec2 canvasBase = canvas * 0.7; 
    vec2 w1_b = vec2(fbm(canvasBase), fbm(canvasBase + vec2(3.1, 1.7)));
    vec2 w2_b = vec2(fbm(canvasBase + w1_b * 2.0), fbm(canvasBase + w1_b * 2.0));
    float hBase = fbm(canvasBase + w2_b * 1.8);
    
    // 底层法线与偏暗的白金色彩
    float e = 0.005;
    float hx_b = fbm(canvasBase + w2_b * 1.8 + vec2(e, 0.0));
    float hy_b = fbm(canvasBase + w2_b * 1.8 + vec2(0.0, e));
    vec2 gradBase = vec2(hx_b - hBase, hy_b - hBase) / e;
    
    // 底层亮度稍低(0.85)，拉开与顶层的对比
    vec3 colBase = chromePalette(hBase + length(gradBase) * 0.04, 0.85);
    colBase += vec3(0.25) * pow(smoothstep(0.0, 6.0, length(gradBase)), 2.0); // 柔和高光
    colBase -= vec3(0.15) * smoothstep(3.0, 0.0, length(gradBase));         // 柔和暗部

    vec2 canvasTop = canvas * 1.3 + vec2(5.5, 2.8);
    vec2 w1_t = vec2(fbm(canvasTop), fbm(canvasTop + vec2(4.2, 2.1)));
    vec2 w2_t = vec2(fbm(canvasTop + w1_t * 2.5 + vec2(1.7, 5.8)), 
                     fbm(canvasTop + w1_t * 2.5 + vec2(9.3, 3.4)));
    float hTop = fbm(canvasTop + w2_t * 2.0);

    // 顶层法线与明亮的电镀色彩
    float hx_t = fbm(canvasTop + w2_t * 2.0 + vec2(e, 0.0));
    float hy_t = fbm(canvasTop + w2_t * 2.0 + vec2(0.0, e));
    vec2 gradTop = vec2(hx_t - hTop, hy_t - hTop) / e;
    
    // 顶层非常明亮洁净(1.1)
    vec3 colTop = chromePalette(hTop + length(gradTop) * 0.05, 1.1);
    
    // 顶层极尖锐的镜面高光 (Specular Highlight)
    float specTop = pow(smoothstep(0.0, 8.0, length(gradTop)), 2.5);
    colTop += vec3(0.5) * specTop;                         
    colTop -= vec3(0.2) * smoothstep(4.0, 0.0, length(gradTop)); 
    colTop += vec3(0.2) * step(0.78, fract(hTop * 3.0 + length(gradTop) * 0.2));

    float topMask = smoothstep(0.42, 0.48, hTop);

    // 【厚度边缘高光】利用屏幕导数或法线变化率，在顶层镂空的边缘产生一条“晶莹剔透”的立体厚度边
    float edge = fwidth(topMask);
    float edgeGlow = smoothstep(0.0, 0.15, edge) * (1.0 - smoothstep(0.15, 0.3, edge));
    colTop += vec3(0.4) * edgeGlow; // 在边缘叠加上极亮的白金反光，使其看起来是有厚度的固体薄膜

    vec2 shadowOffset = vec2(0.08, 0.12) + gradTop * 0.005;
    float shadowMask = smoothstep(0.42, 0.52, fbm(canvasTop - shadowOffset + w2_t * 2.0));
    
    // 阴影使底层的白金液面在被遮挡处柔和变暗 35%
    colBase = mix(colBase, colBase * 0.65, shadowMask * (1.0 - topMask));

    vec3 finalCol = mix(colBase, colTop, topMask);

    // 消灭色彩断层
    finalCol += (hash1(gl_FragCoord.xy) - 0.5) * (1.5 / 255.0);

    gl_FragColor = vec4(finalCol, 1.0);
}

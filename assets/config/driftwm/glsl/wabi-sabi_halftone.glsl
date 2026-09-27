// Wabi-Sabi Retro — Organic desaturated tones with hard-edged tactile printing halftones.
precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;

float hash1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash1(i), hash1(i+vec2(1.0,0.0)), f.x), mix(hash1(i+vec2(0.0,1.0)), hash1(i+vec2(1.0,1.0)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0; float a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * noise(p); p = p * 2.0; a *= 0.5; }
    return v;
}

// 侘寂寂静调色盘：粗糙砂纸、枯木、苔藓、朱砂、深夜
const vec3 WASH_PAPER = vec3(0.89, 0.86, 0.81); // #e3dad0 粗糙和纸灰
const vec3 SUMI_BLACK = vec3(0.16, 0.17, 0.18); // #292b2e 浓墨
const vec3 MOSS_GREEN = vec3(0.42, 0.46, 0.38); // #6a7560 苔藓绿
const vec3 DRY_WOOD  = vec3(0.60, 0.53, 0.45); // #998773 枯木褐
const vec3 CINLABAR   = vec3(0.73, 0.29, 0.24); // #ba4a3d 朱砂红

void main() {
    // 基础空间坐标
    vec2 worldPos = v_coords * size + u_camera;
    vec2 canvas = worldPos * 0.0025;
    
    // 生成底层的有机波形
    float f = fbm(canvas);
    
    // --- 核心改动：生成复古半调网点 (Halftone Grid) ---
    // 将屏幕强行划分成像素级的圆点矩阵
    vec2 dotGrid = fract(worldPos * 0.12); // 控制网点密度
    float distToDotCenter = length(dotGrid - 0.5);
    
    // 动态网点大小：波形值 f 越大的地方，黑点/网点就越粗
    float halftoneThreshold = 0.65 - f * 0.5; 
    float isDot = step(distToDotCenter, halftoneThreshold * 0.4);
    
    // 色彩阶梯分配（粗颗粒版画感）
    vec3 col = WASH_PAPER;
    col = mix(col, DRY_WOOD,  step(0.35, f));
    col = mix(col, MOSS_GREEN, step(0.52, f));
    col = mix(col, CINLABAR,   step(0.68, f));
    
    // 将印刷半调黑网点强行混合进去（只在特定密度区间显现，模拟漏印效果）
    if (f > 0.2 && f < 0.75) {
        col = mix(col, SUMI_BLACK, isDot * 0.85); // 0.85 保持一点半透明的纸张颗粒感
    }
    
    // 强制部分极高值区域为纯浓墨块
    col = mix(col, SUMI_BLACK, step(0.82, f));

    gl_FragColor = vec4(col, 1.0);
}

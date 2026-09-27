// Liquid chrome & mercury — analytical gradients for metallic specular reflections.
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
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// 奢华水银炫彩：白金基底上折射出极淡的香槟金、薄荷绿和罗兰紫
vec3 chromePalette(float t) {
    vec3 a = vec3(0.65, 0.65, 0.68); // 白金高亮基色
    vec3 b = vec3(0.35, 0.35, 0.32); // 反差振幅
    vec3 c = vec3(1.20, 1.10, 1.00); 
    vec3 d = vec3(0.10, 0.25, 0.45); // 通道错开，形成油画般的彩色反光
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 canvas = (v_coords * size + u_camera) * 0.0025;

    // 强力的双重域扭曲，模拟粘稠液体搅拌的效果
    vec2 w1 = vec2(fbm(canvas), fbm(canvas + vec2(4.2, 2.1)));
    vec2 w2 = vec2(fbm(canvas + w1 * 2.5 + vec2(1.7, 5.8)), 
                   fbm(canvas + w1 * 2.5 + vec2(9.3, 3.4)));
    
    // 计算金属表面高度场
    float h = fbm(canvas + w2 * 2.0);

    // 数值法线计算 (Pseudo Normal) — 找到高度的变化率来做光照
    float e = 0.005;
    float hx = fbm(canvas + w2 * 2.0 + vec2(e, 0.0));
    float hy = fbm(canvas + w2 * 2.0 + vec2(0.0, e));
    vec2 grad = vec2(hx - h, hy - h) / e;

    // 基础电镀彩色折射
    vec3 col = chromePalette(h + length(grad) * 0.05);

    // 核心：模拟金属高光 (Specular Highlight) 与环境遮蔽 (Shadow)
    float spec = smoothstep(0.0, 8.0, length(grad)); // 坡度越陡反射越强
    spec = pow(spec, 2.0);
    
    // 叠加铬金属明暗面：一侧反射白光，一侧陷入深色阴影
    col += vec3(0.45) * spec;                         // 极亮白金高光
    col -= vec3(0.25) * smoothstep(4.0, 0.0, length(grad)); // 深色褶皱阴影

    // 极细的高反差亮边，突显液态水银的反光锐度
    col += vec3(0.15) * step(0.75, fract(h * 3.0 + length(grad) * 0.2));

    // 消灭色彩断层
    col += (hash1(gl_FragCoord.xy) - 0.5) * (1.5 / 255.0);

    gl_FragColor = vec4(col, 1.0);
}

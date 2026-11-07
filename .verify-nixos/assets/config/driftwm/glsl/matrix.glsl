// Compensated Bauhaus Matrix — Terracotta & Prussian Blue
precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 p = v_coords * size + u_camera;
    
    // 【复古陶土色板】
    vec3 cWhite    = vec3(0.97, 0.94, 0.88); // 温暖燕麦白
    vec3 cClay     = vec3(0.78, 0.24, 0.18); // 陶土砖红
    vec3 cPrussian = vec3(0.12, 0.22, 0.38); // 普鲁士深蓝
    vec3 cOcher    = vec3(0.88, 0.62, 0.16); // 赭石深黄
    vec3 cCharcoal = vec3(0.10, 0.10, 0.12); // 炭黑线框

    vec2 grid1 = floor(p / 130.0);
    float h1 = hash(grid1);
    vec2 finalGrid = grid1;
    if (h1 > 0.4) { finalGrid = floor(p / 65.0); }
    
    float h = hash(finalGrid);
    vec2 st = fract(p / (h1 > 0.4 ? 65.0 : 130.0));

    vec3 col = cWhite; 
    if (h < 0.08) { col = cClay; } 
    else if (h < 0.18) { col = cPrussian; } 
    else if (h < 0.28) { col = cOcher; } 
    else if (h < 0.36) { col = cCharcoal; }

    vec2 edge = step(vec2(0.482), abs(st - 0.5));
    float gridLine = max(edge.x, edge.y);
    col = mix(col, cCharcoal, gridLine);

    // 色彩非线性补偿
    if (col == cWhite) {
        col = pow(col, vec3(0.48)) * 1.15;
    } else if (col != cCharcoal) {
        col = pow(col, vec3(0.62)) * 1.05;
    }

    gl_FragColor = vec4(col, 1.0);
}

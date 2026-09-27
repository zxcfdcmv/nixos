// Parallax Bauhaus Relief — 错速视差悬浮包豪斯（强空间感版）
#extension GL_OES_standard_derivatives : enable
precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    // 基础屏幕物理坐标
    vec2 p = v_coords * size + u_camera;
    
    vec3 cWhite    = vec3(0.97, 0.94, 0.88); // 温暖燕麦白
    vec3 cClay     = vec3(0.78, 0.24, 0.18); // 陶土砖红
    vec3 cPrussian = vec3(0.12, 0.22, 0.38); // 普鲁士深蓝
    vec3 cOcher    = vec3(0.88, 0.62, 0.16); // 赭石深黄
    vec3 cCharcoal = vec3(0.10, 0.10, 0.12); // 炭黑线框
    
    // 色彩非线性补偿
    cWhite    = pow(cWhite, vec3(0.48)) * 1.15;
    cClay     = pow(cClay, vec3(0.62)) * 1.05;
    cPrussian = pow(cPrussian, vec3(0.62)) * 1.05;
    cOcher    = pow(cOcher, vec3(0.62)) * 1.05;

    vec2 pBase = p;
    vec2 gridBase = floor(pBase / 130.0);
    float hBase1 = hash(gridBase);
    vec2 finalGridBase = gridBase;
    float sizeDivBase = 130.0;
    if (hBase1 > 0.4) { finalGridBase = floor(pBase / 65.0); sizeDivBase = 65.0; }
    
    vec2 stBase = fract(pBase / sizeDivBase);
    vec3 colBase = cWhite;
    // 底层的基本结构线框
    float baseGridLine = step(0.482, max(abs(stBase - 0.5).x, abs(stBase - 0.5).y));
    colBase = mix(colBase, cCharcoal, baseGridLine);

    vec2 parallaxOffset = vec2(25.0, 18.0); 
    vec2 pTop = p + parallaxOffset;

    vec2 gridTop = floor(pTop / 130.0);
    float hTop1 = hash(gridTop);
    vec2 finalGridTop = gridTop;
    float sizeDivTop = 130.0;
    if (hTop1 > 0.4) { finalGridTop = floor(pTop / 65.0); sizeDivTop = 65.0; }
    
    float hTop = hash(finalGridTop);
    vec2 stTop = fract(pTop / sizeDivTop);

    // 计算顶层色块原始颜色
    vec3 tileCol = cWhite; 
    float isColored = 1.0;
    if (hTop < 0.08)       { tileCol = cClay; } 
    else if (hTop < 0.18)  { tileCol = cPrussian; } 
    else if (hTop < 0.28)  { tileCol = cOcher; } 
    else if (hTop < 0.36)  { tileCol = cCharcoal; }
    else                   { isColored = 0.0; } // 白色部分不悬浮，直接剥离

    // 计算顶层的二值掩膜和细腻的高光倒角
    vec2 borderDistTop = abs(stTop - 0.5);
    float inTileTop = step(max(borderDistTop.x, borderDistTop.y), 0.475); // 稍微收缩，露出精致的边缘
    float topMask = isColored * inTileTop;

    // 顶层色块增加高级的哑光工业材质微渐变
    float surfaceShade = dot(stTop - vec2(0.2), vec2(0.4)) * 0.06;
    vec3 colTop = tileCol - vec3(surfaceShade);

    // 挤出顶层陶瓷般的立体亮边
    float edgeWidth = fwidth(max(borderDistTop.x, borderDistTop.y)) * 2.0;
    float edgeGlow = smoothstep(0.475 - edgeWidth, 0.475, max(borderDistTop.x, borderDistTop.y)) * inTileTop;
    colTop += vec3(0.22) * edgeGlow * isColored;

    vec2 shadowP = pTop - vec2(12.0, 16.0); // 增大阴影偏移，拉高悬浮高度
    
    vec2 s_grid = floor(shadowP / 130.0);
    float s_h1 = hash(s_grid);
    vec2 s_finalGrid = s_grid; float s_sizeDiv = 130.0;
    if (s_h1 > 0.4) { s_finalGrid = floor(shadowP / 65.0); s_sizeDiv = 65.0; }
    
    float s_h = hash(s_finalGrid);
    vec2 s_st = fract(shadowP / s_sizeDiv);
    float s_isColored = (s_h < 0.36) ? 1.0 : 0.0;
    
    // 边缘软化阴影：用 smoothstep 代替 step，制造更高级、更真实扩散的软阴影 (Soft Shadow)
    float s_dist = max(abs(s_st - 0.5).x, abs(s_st - 0.5).y);
    float shadowMask = s_isColored * smoothstep(0.49, 0.45, s_dist);

    colBase = mix(colBase, colBase * 0.70 + cCharcoal * 0.05, shadowMask * (1.0 - topMask));

    // 将发生了“错位视差”的顶层块，缝合到原位底层上
    vec3 finalCol = mix(colBase, colTop, topMask);

    // 纸张复古微观噪点
    finalCol += (hash(gl_FragCoord.xy) - 0.5) * (1.2 / 255.0);

    gl_FragColor = vec4(finalCol, 1.0);
}

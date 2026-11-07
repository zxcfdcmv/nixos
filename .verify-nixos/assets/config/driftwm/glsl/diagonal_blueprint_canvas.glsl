#extension GL_OES_standard_derivatives : enable
precision highp float;

varying vec2 v_coords; 
uniform vec2 size;     // 实时的窗口/画布像素大小
uniform vec2 u_camera; // 关键： driftwm 的相机平移世界坐标

float hash(vec2 p) { 
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); 
}

void main() {
    vec2 canvas = (v_coords * size + u_camera) * 0.0035;
    
    float diagX = canvas.x + canvas.y;
    float diagY = canvas.x - canvas.y;
    
    vec2 tileID = floor(vec2(diagX, diagY));
    vec2 localUV = fract(vec2(diagX, diagY));

    float mask = step(0.12, localUV.x) * step(0.12, localUV.y) *
                 step(localUV.x, 0.88) * step(localUV.y, 0.88);

    // 包豪斯硬核重工业色板
    vec3 cWhite    = vec3(0.97, 0.94, 0.88); 
    vec3 cClay     = vec3(0.78, 0.24, 0.18); 
    vec3 cPrussian = vec3(0.12, 0.22, 0.38); 
    vec3 cOcher    = vec3(0.88, 0.62, 0.16); 
    vec3 cCharcoal = vec3(0.12, 0.12, 0.14); 

    float h = hash(tileID);
    vec3 slatColor = cWhite;
    if (h < 0.20)      { slatColor = cClay; } 
    else if (h < 0.40) { slatColor = cPrussian; } 
    else if (h < 0.60) { slatColor = cOcher; }
    else if (h < 0.75) { slatColor = cCharcoal; }

    vec3 col = cCharcoal * 0.35; // 底层虚空的斜向阴影基色
    if (mask > 0.5) {
        // 卡出45度板材侧边的立体折角受光面
        if (localUV.x < 0.18 || localUV.y > 0.82) {
            col = slatColor * 1.15; // 迎光亮切面
        } else {
            col = slatColor * 0.70; // 背光暗切面
        }
    }

    // 4. 消灭色彩断层的高级噪点
    col += (hash(v_coords) - 0.5) * (1.2 / 255.0);

    gl_FragColor = vec4(col, 1.0);
}

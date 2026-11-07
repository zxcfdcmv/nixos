#extension GL_OES_standard_derivatives : enable
precision highp float;

varying vec2 v_coords; 
uniform vec2 size;     // 实时的窗口/画布像素大小
uniform vec2 u_camera; // 关键： driftwm 的相机平移世界坐标

float hash(vec2 p) { 
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); 
}

void main() {
    vec2 canvas = (v_coords * size + u_camera) * 0.0045;
    
    // 2. 纯平面非对称网格划分（无回廊 Z 轴，永不一黑到底）
    vec2 tileID = floor(canvas);
    vec2 localUV = fract(canvas);

    // 利用哈希让部分方块产生包豪斯经典的非对称“拼贴合并”
    float randX = hash(vec2(tileID.x, 11.4));
    float randY = hash(vec2(tileID.y, 45.1));
    vec2 finalTileID = tileID + vec2(step(0.75, randX), step(0.75, randY));

    // 包豪斯/蒙德里安高级平整色板
    vec3 cWhite    = vec3(0.97, 0.94, 0.88); 
    vec3 cClay     = vec3(0.78, 0.24, 0.18); 
    vec3 cPrussian = vec3(0.12, 0.22, 0.38); 
    vec3 cOcher    = vec3(0.88, 0.62, 0.16); 
    vec3 cCharcoal = vec3(0.12, 0.12, 0.14); 

    float h = hash(finalTileID);
    vec3 blockColor = cWhite;
    if (h < 0.12)      { blockColor = cClay; } 
    else if (h < 0.25) { blockColor = cPrussian; } 
    else if (h < 0.38) { blockColor = cOcher; }
    else if (h < 0.55) { blockColor = cCharcoal; }

    float mask = step(0.10, localUV.x) * step(0.10, localUV.y) *
                 step(localUV.x, 0.90) * step(localUV.y, 0.90);

    vec3 col = cCharcoal * 0.4; // 缝隙里深邃的底衬色
    if (mask > 0.5) {
        // 卡出每个独立面板左上微亮、右下微暗的极简平面立体硬边界（无任何多余拉丝与软雾）
        if (localUV.x < 0.16 || localUV.y > 0.84) {
            col = blockColor * 1.12; 
        } else if (localUV.x > 0.84 || localUV.y < 0.16) {
            col = blockColor * 0.75;
        } else {
            col = blockColor;
        }
    }

    // 4. 消灭色彩断层的高级噪点
    col += (hash(v_coords) - 0.5) * (1.2 / 255.0);

    gl_FragColor = vec4(col, 1.0);
}

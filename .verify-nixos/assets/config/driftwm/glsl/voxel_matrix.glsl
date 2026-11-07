#extension GL_OES_standard_derivatives : enable
precision highp float;

varying vec2 v_coords; 

float hash(vec2 p) { 
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); 
}

void main() {
    vec2 p = v_coords - 0.5;

    // 清爽明亮的包豪斯高级色板（完全平整纯色）
    vec3 cWhite    = vec3(0.97, 0.94, 0.88); 
    vec3 cClay     = vec3(0.78, 0.24, 0.18); 
    vec3 cPrussian = vec3(0.12, 0.22, 0.38); 
    vec3 cOcher    = vec3(0.88, 0.62, 0.16); 
    vec3 cCharcoal = vec3(0.12, 0.12, 0.14); 

    // 高清色彩非线性提亮补偿
    cWhite    = pow(cWhite, vec3(0.48)) * 1.15;
    cClay     = pow(cClay, vec3(0.50)) * 1.10;
    cPrussian = pow(cPrussian, vec3(0.52)) * 1.08;
    cOcher    = pow(cOcher, vec3(0.50)) * 1.10;

    float d = max(abs(p.x), abs(p.y)); 
    float z = 1.0 / max(d, 0.0001); 
    float angle = atan(p.y, p.x);
    float normAngle = angle * 1.27323; // 四周映射为 0.0 - 4.0

    vec2 bgTunnelUV = vec2(normAngle, z * 0.09); // 最底层收缩最慢，极度稳定
    vec2 bgScale = vec2(2.0, 2.5);
    float bgHash = hash(floor(bgTunnelUV * bgScale));
    vec3 bgColor = (bgHash < 0.5) ? (cPrussian * 0.42) : (cCharcoal * 0.52);

    float stripDensity = 6.0; // 四周肢解出 24 条独立滑动长轨
    float stripID = floor(normAngle * stripDensity);
    float stripSpeed = 0.14 + hash(vec2(stripID, 2.71)) * 0.12;
    float stripOffset = hash(vec2(stripID, 8.13)) * 4.0;

    // 预估网格位置，计算非对称长短变形
    vec2 estID = floor(vec2(normAngle * stripDensity, (z * stripSpeed + stripOffset) * 4.0));
    float blockRand = hash(estID);
    float yLengthMultiplier = (blockRand > 0.75) ? 2.0 : ((blockRand < 0.20) ? 0.6 : 1.0);
    
    vec2 fgScale = vec2(stripDensity, 5.0 / yLengthMultiplier);
    
    // 为每一个独立积木块算出一前一后的“立体阶梯突起/深陷”值
    float voxelElevation = (hash(estID + vec2(5.67, 8.91)) - 0.5) * 4.8;
    
    // 精确渲染包含终极多重错位的 3D 前景投影坐标
    vec2 fgTunnelUV = vec2(normAngle, z * stripSpeed + stripOffset + voxelElevation * 0.05);
    vec2 fgTileID = floor(vec2(fgTunnelUV.x * fgScale.x, fgTunnelUV.y * fgScale.y));
    vec2 fgLocalUV = fract(vec2(fgTunnelUV.x * fgScale.x, fgTunnelUV.y * fgScale.y));

    // 前景核心正面遮罩（保留 12% 的干净物理悬浮大裂缝）
    float frontMask = step(0.12, fgLocalUV.x) * step(0.12, fgLocalUV.y) *
                      step(fgLocalUV.x, 0.88) * step(fgLocalUV.y, 0.88);

    // 包含侧翼厚度的积木总占位遮罩
    float totalBlockMask = step(0.05, fgLocalUV.x) * step(0.05, fgLocalUV.y) *
                           step(fgLocalUV.x, 0.95) * step(fgLocalUV.y, 0.95);

    // 严谨干净的包豪斯前景纯色划分
    float fgHash = hash(fgTileID);
    vec3 fgColor = cWhite;
    if (fgHash < 0.22)       { fgColor = cClay; } 
    else if (fgHash < 0.42)  { fgColor = cPrussian; } 
    else if (fgHash < 0.62)  { fgColor = cOcher; } 
    else if (fgHash < 0.76)  { fgColor = cCharcoal; }

    // 【纯几何多面立体折角】：突出块与深陷坑洞呈现对立明暗，纯色碰撞挤出物理厚度
    vec3 finalVoxelColor = fgColor;
    if (frontMask < 0.5) {
        if (voxelElevation > 0.0) {
            finalVoxelColor = (fgLocalUV.x < 0.12 || fgLocalUV.y > 0.88) ? (fgColor * 1.15) : (fgColor * 0.68);
        } else {
            finalVoxelColor = (fgLocalUV.x < 0.12 || fgLocalUV.y > 0.88) ? (fgColor * 0.55) : (fgColor * 1.05);
        }
    }

    float shadowOffset = 0.13 + abs(voxelElevation) * 0.015;
    float shadowMask = step(shadowOffset, fgLocalUV.x) * step(shadowOffset, fgLocalUV.y) *
                       step(fgLocalUV.x, 1.0 - shadowOffset) * step(fgLocalUV.y, 1.0 - shadowOffset);
    float hardShadow = (1.0 - totalBlockMask) * shadowMask;

    vec3 col = mix(bgColor, cCharcoal * 0.18, hardShadow * 0.92);
    col = mix(col, finalVoxelColor, totalBlockMask);

    float centerBlack = smoothstep(85.0, 30.0, z);
    col = mix(cCharcoal * 0.4, col, centerBlack);

    // 细腻的去断层高级噪点
    col += (hash(v_coords) - 0.5) * (1.2 / 255.0);

    gl_FragColor = vec4(col, 1.0);
}

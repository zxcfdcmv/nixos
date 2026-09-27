// Bauhaus / De Stijl abstract — Mondrian-inspired asymmetric structural grid.
precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;

// 1维伪随机，用于随机打碎网格
float hash1(float n) {
    return fract(sin(n) * 43758.5453);
}

// 包豪斯经典调色盘：经典红、蓝、黄、碳黑、工业灰、画布白
const vec3 CANVAS = vec3(0.961, 0.949, 0.918); // #f5f2ea 略带温度的画布白
const vec3 RED    = vec3(0.851, 0.176, 0.141); // #d92d24 饱满红
const vec3 BLUE   = vec3(0.114, 0.314, 0.627); // #1d50a0 深邃蓝
const vec3 YELLOW = vec3(0.957, 0.745, 0.169); // #f4be2b 芥末黄
const vec3 BLACK  = vec3(0.106, 0.114, 0.125); // #1b1d20 结构碳黑
const vec3 GRAY   = vec3(0.667, 0.690, 0.702); // #aab0b3 现代工业灰

void main() {
    // 缩放空间并叠加上相机位移，形成世界坐标
    vec2 st = (v_coords * size + u_camera) * 0.003;
    
    // 建立硬核网格：分割空间
    vec2 grid1 = floor(st * 1.5);
    vec2 grid2 = floor(st * 3.5); // 次级网格
    
    // 利用随机数决定当前区域的分割倾向，产生非对称设计感
    float randX = hash1(grid1.x + 13.0);
    float randY = hash1(grid1.y + 47.0);
    float cellRand = hash1(grid2.x * 11.0 + grid2.y * 93.0);
    
    // 计算线条区域（硬边缘）
    // 通过 thickness 控制黑色“蒙德里安线条”的粗细
    vec2 f1 = fract(st * 1.5);
    vec2 f2 = fract(st * 3.5);
    
    float lineThickness = 0.04;
    float isLine = step(1.0 - lineThickness, f1.x) + step(1.0 - lineThickness, f1.y);
    
    // 在部分区域引入更细的次级结构线
    if (randX > 0.4) {
        isLine += step(1.0 - lineThickness * 0.6, f2.x) * step(0.5, randY);
    }
    if (randY > 0.4) {
        isLine += step(1.0 - lineThickness * 0.6, f2.y) * step(0.5, randX);
    }
    
    // 颜色填充逻辑（纯色块，无渐变）
    vec3 col = CANVAS;
    
    // 依据随机性在网格中填入大面积色块，保留大部分留白
    if (cellRand > 0.94) {
        col = RED;
    } else if (cellRand > 0.88) {
        col = BLUE;
    } else if (cellRand > 0.82) {
        col = YELLOW;
    } else if (cellRand > 0.74) {
        col = GRAY;
    } else if (cellRand > 0.68) {
        col = BLACK;
    }
    
    // 强制将线条覆盖在色块之上
    col = mix(col, BLACK, step(0.1, isLine));
    
    gl_FragColor = vec4(col, 1.0);
}

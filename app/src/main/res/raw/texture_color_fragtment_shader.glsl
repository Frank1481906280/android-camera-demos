#version 300 es
precision mediump float;

in vec2 v_texCoord;
out vec4 outColor;
uniform sampler2D s_texture;
uniform sampler2D textureLUT;

uniform int colorFlag;//滤镜类型

//rgb转hsl
vec3 rgb2hsl(vec3 color){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(color.bg, K.wz), vec4(color.gb, K.xy), step(color.b, color.g));
    vec4 q = mix(vec4(p.xyw, color.r), vec4(color.r, p.yzx), step(p.x, color.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//hsl转rgb
vec3 hsl2rgb(vec3 color){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(color.xxx + K.xyz) * 6.0 - K.www);
    return color.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y);
}

//灰度
void grey(inout vec4 color){
    float weightMean = color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
    color.r = color.g = color.b = weightMean;
}

//黑白
void blackAndWhite(inout vec4 color){
    float threshold = 0.5;
    float mean = (color.r + color.g + color.b) / 3.0;
    color.r = color.g = color.b = mean >= threshold ? 1.0 : 0.0;
}

//反向
void reverse(inout vec4 color){
    color.r = 1.0 - color.r;
    color.g = 1.0 - color.g;
    color.b = 1.0 - color.b;
}

//亮度
void light(inout vec4 color){
    vec3 hslColor = vec3(rgb2hsl(color.rgb));
    hslColor.z += 0.15;
    color = vec4(hsl2rgb(hslColor), color.a);
}

void light2(inout vec4 color){
    color.r += 0.15;
    color.g += 0.15;
    color.b += 0.15;
}

//查找表滤镜
vec4 lookupTable(vec4 color){
    float blueColor = color.b * 63.0;

    vec2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
    vec2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);

    vec2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.g);
    vec2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.g);
    vec4 newColor1 = texture(textureLUT, texPos1);
    vec4 newColor2 = texture(textureLUT, texPos2);
    vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return vec4(newColor.rgb, color.w);
}

void main(){
    vec4 tmpColor = texture(s_texture, v_texCoord);
    if (colorFlag == 1){ //灰度
        grey(tmpColor);
    } else if (colorFlag == 2){ //黑白
        blackAndWhite(tmpColor);
    } else if (colorFlag == 3){ //反向
        reverse(tmpColor);
    } else if (colorFlag == 4){ //亮度
        light(tmpColor);
    } else if(colorFlag == 5){ //亮度2
        light2(tmpColor);
    } else if(colorFlag == 6){//lut
        outColor = lookupTable(tmpColor);
        return;
    }

    outColor = tmpColor;
}

//将颜色值约束在[0.0-1.0] 之间
void checkColor(vec4 color){
    color.r=max(min(color.r, 1.0), 0.0);
    color.g=max(min(color.g, 1.0), 0.0);
    color.b=max(min(color.b, 1.0), 0.0);
    color.a=max(min(color.a, 1.0), 0.0);
}
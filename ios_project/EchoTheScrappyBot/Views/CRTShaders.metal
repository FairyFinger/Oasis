//
//  CRTShaders.metal
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Metal Shading Language (MSL) Shaders for Trinitron CRT Barrel Curvature,
//  Phosphor Scanlines, and Dynamic Chromatic Aberration during damage/glitches.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 crtBarrelDistortion(float2 position, float2 size, float curvature) {
    float2 uv = position / size;
    float2 centered = uv - float2(0.5, 0.5);
    float dist = dot(centered, centered);
    float factor = 1.0 + dist * curvature;
    float2 curvedUV = centered * factor + float2(0.5, 0.5);
    return curvedUV * size;
}

[[ stitchable ]] half4 crtScanlineEffect(float2 position, half4 color, float scanlineIntensity, float time) {
    float scanline = sin(position.y * 1.85 + time * 6.0);
    half scanMod = half(1.0 - scanlineIntensity * (0.5 + 0.5 * scanline));
    return half4(color.rgb * scanMod, color.a);
}

[[ stitchable ]] half4 crtChromaticAberration(float2 position, half4 color, float glitchIntensity) {
    // Slight channel offset based on glitch intensity
    if (glitchIntensity <= 0.01) {
        return color;
    }
    half shift = half(glitchIntensity * 0.015);
    half r = color.r + shift;
    half b = color.b - shift;
    return half4(r, color.g, b, color.a);
}

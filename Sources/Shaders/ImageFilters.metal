//
//  ImageFilters.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 8/5/26.
//

#include <metal_stdlib>
using namespace metal;

// Guard against out-of-bounds.
template <class T, access A>
bool isOutOfBounds(thread const texture2d<T, A>& texture, uint2 gid) {
    return gid.x >= texture.get_width() ||
           gid.y >= texture.get_height();
}

template <class T, class T3>
T luminanceRec601(T3 colorRGB) {
    return dot(colorRGB, T3(0.299f, 0.587f, 0.114f));
}


// MARK: - Grayscale Compute Kernel
kernel void grayscale(texture2d<half, access::read> inputTexture [[texture(0)]],
                      texture2d<half, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half gray = luminanceRec601<half>(colorValue.rgb);
    outputTexture.write(half4(gray, gray, gray, colorValue.a), gid);
}

// MARK: - Sepia Compute Kernel
kernel void sepia(texture2d<half, access::read> inputTexture [[texture(0)]],
                  texture2d<half, access::write> outputTexture [[texture(1)]],
                  uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half dotR = dot(colorValue.rgb, half3(0.393, 0.769, 0.189));
    half dotG = dot(colorValue.rgb, half3(0.349,0.686,0.168));
    half dotB = dot(colorValue.rgb, half3(0.272,0.534,0.131));
    half3 out = saturate(half3(dotR, dotG, dotB));
    
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Invert Compute Kernel
kernel void invert(texture2d<half, access::read> inputTexture [[texture(0)]],
                   texture2d<half, access::write> outputTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 out = 1 - colorValue.rgb;
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Brightness Compute Kernel
kernel void brightness(texture2d<half, access::read> inputTexture [[texture(0)]],
                       texture2d<half, access::write> outputTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]],
                       constant float& brightness [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 out = saturate(colorValue.rgb + half3(brightness));
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Contrast Compute Kernel
kernel void contrast(texture2d<half, access::read> inputTexture [[texture(0)]],
                     texture2d<half, access::write> outputTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]],
                     constant float& contrast [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 pointFive = half3(0.5);
    half3 out = saturate(((colorValue.rgb - pointFive) * contrast) + pointFive);
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Threshold Compute Kernel
kernel void threshold(texture2d<half, access::read> inputTexture [[texture(0)]],
                     texture2d<half, access::write> outputTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]],
                     constant float& factor [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half gray = luminanceRec601<half>(colorValue.rgb);
    half color = gray >= factor ? 1.0 : 0.0;
    outputTexture.write(half4(color, color, color, colorValue.a), gid);
}

// MARK: - Box Blur Compute Kernel
// Standard implementation of Box Blur with O((2r + 1)^2)
// Noticeably laggy as radius increases, especially > 10.
kernel void boxBlur(texture2d<half, access::read> inputTexture [[texture(0)]],
                    texture2d<half, access::write> outputTexture [[texture(1)]],
                    uint2 gid [[thread_position_in_grid]],
                    constant uint& radius [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    half3 colorTotal = half3(0);
    int sampleCount = 0;
    
    const int radiusInt = (int)radius;
    const int2 base = (int2)gid;
    const int2 size = int2((int)inputTexture.get_width() - 1, (int)inputTexture.get_height() - 1);
    
    for (int i = -radiusInt; i <= radiusInt; i++) {
        for (int j = -radiusInt; j <= radiusInt; j++) {
            const int2 pixelPos = clamp(base + int2(i, j), int2(0), size);
            colorTotal += inputTexture.read((uint2)pixelPos).rgb;
            sampleCount++;
        }
    }
    
    half3 avg = colorTotal / half(sampleCount);
    outputTexture.write(half4(avg, 1.0), gid);
}

// MARK: - Box Blur Two-Pass Compute Kernels
// Two-pass version of the Box Blur with O(2(2r + 1))
// The first pass only averages the colors horizontally, then its output
// is passed to the second pass which averages the colors vertically.
kernel void boxBlurTwoPassHorizontal(texture2d<half, access::read> inputTexture [[texture(0)]],
                                     texture2d<half, access::write> outputTexture [[texture(1)]],
                                     uint2 gid [[thread_position_in_grid]],
                                     constant uint& radius [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    half3 colorTotal = half3(0);
    int sampleCount = 0;
    
    const int radiusInt = (int)radius;
    const int baseX = (int)gid.x;
    const int width = (int)inputTexture.get_width() - 1;
    
    for (int x = -radiusInt; x <= radiusInt; x++) {
        const uint pixelX = uint(clamp(baseX + x, 0, width));
        colorTotal += inputTexture.read(uint2(pixelX, gid.y)).rgb;
        sampleCount++;
    }
    
    half3 avg = colorTotal / half(sampleCount);
    outputTexture.write(half4(avg, 1.0), gid);
}

kernel void boxBlurTwoPassVertical(texture2d<half, access::read> inputTexture [[texture(0)]],
                                   texture2d<half, access::write> outputTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]],
                                   constant uint& radius [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    half3 colorTotal = half3(0);
    int sampleCount = 0;
    
    const int radiusInt = (int)radius;
    const int baseY = (int)gid.y;
    const int height = (int)inputTexture.get_height() - 1;
    
    for (int y = -radiusInt; y <= radiusInt; y++) {
        const uint pixelY = uint(clamp(baseY + y, 0, height));
        colorTotal += inputTexture.read(uint2(gid.x, pixelY)).rgb;
        sampleCount++;
    }
    
    half3 avg = colorTotal / half(sampleCount);
    outputTexture.write(half4(avg, 1.0), gid);
}

// MARK: - Gaussian Blur Compute Kernel
// Standard implementation of Gaussian Blur.
kernel void gaussianBlur(texture2d<half, access::read> inputTexture [[texture(0)]],
                         texture2d<half, access::write> outputTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]],
                         constant uint& radius [[buffer(0)]],
                         constant float& strength [[buffer(1)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    if (strength <= 0.0f) {
        half4 color = inputTexture.read(gid);
        outputTexture.write(color, gid);
        return;
    }
    
    half3 colorTotal = half3(0);
    half weightTotal = 0.0f;
    
    const int radiusInt = (int)radius;
    const int2 base = (int2)gid;
    const int2 size = int2((int)inputTexture.get_width() - 1, (int)inputTexture.get_height() - 1);
    const half twoSigmaSquared = (2.0f * (strength * strength));
    
    for (int i = -radiusInt; i <= radiusInt; i++) {
        for (int j = -radiusInt; j <= radiusInt; j++) {
            const int2 offset = int2(i, j);
            const int2 pixelPos = clamp(base + offset, int2(0), size);
            
            const half numerator = (half)((i * i) + (j * j));
            const half g = exp(-numerator / twoSigmaSquared);
            
            colorTotal += inputTexture.read((uint2)pixelPos).rgb * g;
            weightTotal += g;
        }
    }
    
    half3 avg = colorTotal / half(weightTotal);
    outputTexture.write(half4(avg, 1.0), gid);
}

// MARK: - Gaussian Blur Two Pass Compute Kernel
// Two-pass version of the Gaussian Blur with O(2(2r + 1))
// The first pass only averages the colors horizontally, then its output
// is passed to the second pass which averages the colors vertically.
kernel void gaussianBlurTwoPassHorizontal(texture2d<half, access::read> inputTexture [[texture(0)]],
                                          texture2d<half, access::write> outputTexture [[texture(1)]],
                                          uint2 gid [[thread_position_in_grid]],
                                          constant uint& radius [[buffer(0)]],
                                          constant float& strength [[buffer(1)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    if (strength <= 0.0f) {
        half4 color = inputTexture.read(gid);
        outputTexture.write(color, gid);
        return;
    }
    
    half3 colorTotal = half3(0);
    half weightTotal = 0.0f;
    
    const int radiusInt = (int)radius;
    const int baseX = (int)gid.x;
    const int width = (int)inputTexture.get_width() - 1;
    const half twoSigmaSquared = (2.0f * (strength * strength));
    
    for (int x = -radiusInt; x <= radiusInt; x++) {
        const uint2 pixelPos = uint2(clamp(baseX + x, 0, width), gid.y);
        const half numerator = (half)(x * x);
        const half g = exp(-numerator / twoSigmaSquared);
        
        colorTotal += inputTexture.read(pixelPos).rgb * g;
        weightTotal += g;
    }
    
    half3 avg = colorTotal / half(weightTotal);
    outputTexture.write(half4(avg, 1.0), gid);
}

kernel void gaussianBlurTwoPassVertical(texture2d<half, access::read> inputTexture [[texture(0)]],
                                        texture2d<half, access::write> outputTexture [[texture(1)]],
                                        uint2 gid [[thread_position_in_grid]],
                                        constant uint& radius [[buffer(0)]],
                                        constant float& strength [[buffer(1)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    if (strength <= 0.0f) {
        half4 color = inputTexture.read(gid);
        outputTexture.write(color, gid);
        return;
    }
    
    half3 colorTotal = half3(0);
    half weightTotal = 0.0f;
    
    const int radiusInt = (int)radius;
    const int baseY = (int)gid.y;
    const int height = (int)inputTexture.get_height() - 1;
    const half twoSigmaSquared = (2.0f * (strength * strength));
    
    for (int y = -radiusInt; y <= radiusInt; y++) {
        const uint2 pixelPos = uint2(gid.x, clamp(baseY + y, 0, height));
        const half numerator = (half)(y * y);
        const half g = exp(-numerator / twoSigmaSquared);
        
        colorTotal += inputTexture.read(pixelPos).rgb * g;
        weightTotal += g;
    }
    
    half3 avg = colorTotal / half(weightTotal);
    outputTexture.write(half4(avg, 1.0), gid);
}


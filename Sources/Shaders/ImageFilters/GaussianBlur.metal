//
//  GaussianBlur.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
// Gaussian Blur
// Like Box Blur, except nearby pixels contribute more weight than far pixels.
//
// See GaussianBlur.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "Helpers.h"

// MARK: Compute Kernels

// Standard implementation of Gaussian Blur. O((2r + 1)^2)
// Noticeably laggy as radius increases, especially > 10.
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

// MARK: Two-Pass Compute Kernels
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

//
//  BoxBlur.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
// Box Blur
// Smooths an image by replacing each pixel with the average of its surrounding neighboring pixels inside a fixed-size square region.
//
// See BoxBlur.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "Helpers.h"

// MARK: Compute Kernels

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

// MARK: Two-Pass Compute Kernels
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

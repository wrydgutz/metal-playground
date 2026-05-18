//
//  Threshold.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
//
// Threshold
// Converts an image into a binary-style image by setting pixels above a chosen brightness
// value to one color (usually white) and pixels below it to another (usually black).
//
// See Threshold.md for full notes.

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"


// MARK: Compute Kernels

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

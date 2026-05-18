//
//  Contrast.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
//
// Contrast
// Shifts colors away from or toward the midpoint gray (0.5).
//
// See Contrast.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"


// MARK: Compute Kernels

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

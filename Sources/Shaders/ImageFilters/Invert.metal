//
//  Invert.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
//
// Invert
// Produces a photographic negative effect by replacing each pixel’s color with its opposite value.
//
// See Invert.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"


// MARK: Compute Kernels

kernel void invert(texture2d<half, access::read> inputTexture [[texture(0)]],
                   texture2d<half, access::write> outputTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 out = 1 - colorValue.rgb;
    outputTexture.write(half4(out, colorValue.a), gid);
}

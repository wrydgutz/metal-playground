//
//  Brightness.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
// Brightness
// Adjusts how light or dark an image appears by adding or subtracting a constant value from each pixel’s color channels.
//
// See Brightness.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"


// MARK: Compute Kernels

kernel void brightness(texture2d<half, access::read> inputTexture [[texture(0)]],
                       texture2d<half, access::write> outputTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]],
                       constant float& brightness [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 out = saturate(colorValue.rgb + half3(brightness));
    outputTexture.write(half4(out, colorValue.a), gid);
}

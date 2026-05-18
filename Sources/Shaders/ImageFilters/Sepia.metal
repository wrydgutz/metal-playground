//
//  Sepia.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
//
// Sepia
// Gives an image a warm brown vintage look by remapping its colors
// using weighted mixes of the original red, green, and blue channels.
//
// See Sepia.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"


// MARK: Compute Kernels

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

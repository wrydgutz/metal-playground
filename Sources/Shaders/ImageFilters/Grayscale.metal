//
//  Grayscale.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
//
// Grayscale
// Removes color from an image by converting each pixel into a single luminance value representing its brightness.
//
// See Grayscale.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"


// MARK: Compute Kernels

kernel void grayscale(texture2d<half, access::read> inputTexture [[texture(0)]],
                      texture2d<half, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half gray = luminanceRec601<half>(colorValue.rgb);
    outputTexture.write(half4(gray, gray, gray, colorValue.a), gid);
}

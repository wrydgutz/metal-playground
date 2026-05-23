//
//  UnsharpMask.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//
//
// Unsharp Mask
// Sharpening technique that blurs the image, extracts the lost detail, then adds that detail back to the original image to enhance edges.
//
// See UnsharpMask.md for full notes.

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"

kernel void unsharpMask(texture2d<half, access::read> inputTexture [[texture(0)]],
                        texture2d<half, access::read> blurredTexture [[texture(1)]],
                        texture2d<half, access::write> outputTexture [[texture(2)]],
                        uint2 gid [[thread_position_in_grid]],
                        constant float& amount [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    const half4 inputColor = inputTexture.read(gid);
    const half4 blurredColor = blurredTexture.read(gid);
    const half3 maskedColor = inputColor.rgb - blurredColor.rgb;
    const half3 out = saturate(inputColor.rgb + (amount * maskedColor.rgb));
    outputTexture.write(half4(out, inputColor.a), gid);
}

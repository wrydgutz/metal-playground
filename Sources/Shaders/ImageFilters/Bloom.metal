//
//  Bloom.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 21/5/26.
//
//
// Bloom
// A multipass effect that creates a soft glow around bright areas by extracting highlights, blurring them, then combining them back with the original image.
//
// See Bloom.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"

kernel void bloomBright(texture2d<half, access::read> inputTexture [[texture(0)]],
                        texture2d<half, access::write> outputTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]],
                        constant float& threshold [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    const half4 inputColor = inputTexture.read(gid);
    const half luma = luminanceRec601<half>(inputColor.rgb);
    const half3 out = inputColor.rgb * step((half)threshold, luma);
    outputTexture.write(half4(out, inputColor.a), gid);
}

kernel void bloomCombine(texture2d<half, access::read> inputTexture [[texture(0)]],
                         texture2d<half, access::read> brightBlurredTexture [[texture(1)]],
                         texture2d<half, access::write> outputTexture [[texture(2)]],
                         uint2 gid [[thread_position_in_grid]],
                         constant float& intensity [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    const half4 inputColor = inputTexture.read(gid);
    const half3 out = saturate(inputColor.rgb + (intensity * brightBlurredTexture.read(gid).rgb));
    outputTexture.write(half4(out, inputColor.a), gid);
}

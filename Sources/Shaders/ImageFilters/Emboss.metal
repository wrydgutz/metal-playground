//
//  Emboss.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
//
// Emboss
// Emboss highlights directional intensity changes to create a raised or engraved 3D-like relief effect.
//
// See Emboss.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"

// K = [ -2, -1,  0 ]
//     [ -1,  0,  1 ]
//     [  0,  1,  2 ]
template <class T>
inline T embossKernelNoDirection(const int2 offset) {
    return T(offset.x + offset.y);
}

kernel void emboss(texture2d<half, access::read> inputTexture [[texture(0)]],
                   texture2d<half, access::write> outputTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    half3 colorSum = half3(0);
    
    const int2 base = (int2)gid;
    const int2 size = int2((int)inputTexture.get_width() - 1, (int)inputTexture.get_height() - 1);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            const int2 offset = int2(i, j);
            const int2 pixelPos = clamp(base + offset, int2(0), size);
            colorSum += luminanceRec601<half>(inputTexture.read((uint2)pixelPos).rgb) * embossKernelNoDirection<half>(offset);
        }
    }
    
    colorSum = clamp(colorSum, half3(0.0h), half3(1.0h));
    
    outputTexture.write(half4(colorSum, 1.0), gid);
}


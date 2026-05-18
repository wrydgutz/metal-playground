//
//  Sharpen.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
// Sharpen
// Enhances edges and fine details by increasing the contrast between neighboring pixels.
//
// See Sharpen.md for full notes.

#include <metal_stdlib>
using namespace metal;

#include "Helpers.h"

// K = [ 0,   -a,    0  ]
//     [ -a, 1 + 4a, -a ]
//     [ 0,   -a,    0  ]
template <class T>
inline T sharpenKernel(const T strength, const int2 offset) {
    if (offset.x == 0 && offset.y == 0) return T(1) + (T(4) * strength);
    else if (abs(offset.x) + abs(offset.y) == 1) return -strength;
    else return T(0);
}

// MARK: Compute Kernels

kernel void sharpen(texture2d<half, access::read> inputTexture [[texture(0)]],
                    texture2d<half, access::write> outputTexture [[texture(1)]],
                    uint2 gid [[thread_position_in_grid]],
                    constant float& strength [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    if (strength <= 0.0f) {
        half4 color = inputTexture.read(gid);
        outputTexture.write(color, gid);
        return;
    }
    
    half3 colorTotal = half3(0);
    
    const half halfTypeStrength = strength;
    const int2 base = (int2)gid;
    const int2 size = int2((int)inputTexture.get_width() - 1, (int)inputTexture.get_height() - 1);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            const int2 offset = int2(i, j);
            const int2 pixelPos = clamp(base + offset, int2(0), size);
            colorTotal += inputTexture.read((uint2)pixelPos).rgb * sharpenKernel(halfTypeStrength, offset);
        }
    }
    
    const half3 out = saturate(colorTotal);
    outputTexture.write(half4(out, 1.0), gid);
}

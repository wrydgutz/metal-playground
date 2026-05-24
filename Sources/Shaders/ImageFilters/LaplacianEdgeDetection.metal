//
//  LaplacianEdgeDetection.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 24/5/26.
//
//
// Laplacian Edge Detection
// Highlights regions where image intensity changes rapidly using the second derivative of the image.
//

#include <metal_stdlib>
using namespace metal;

#include "../Helpers.h"

// K = [  0, -1,  0 ]
//     [ -1,  4, -1 ]
//     [  0, -1,  0 ]
template <class T>
inline T laplacianKernel(const int2 offset) {
    if (offset.x == 0 && offset.y == 0) return T(4);
    else if (abs(offset.x) + abs(offset.y) == 1) return T(-1);
    else return T(0);
}

kernel void laplacianEdgeDetection(texture2d<half, access::read> inputTexture [[texture(0)]],
                                   texture2d<half, access::write> outputTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]],
                                   constant float& gain [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    
    half lap = 0.0h;
    
    const int2 base = (int2)gid;
    const int2 size = int2((int)inputTexture.get_width() - 1, (int)inputTexture.get_height() - 1);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            const int2 offset = int2(i, j);
            const int2 pixelPos = clamp(base + offset, int2(0), size);
            lap += luminanceRec601<half>(inputTexture.read((uint2)pixelPos).rgb) * laplacianKernel<half>(offset);
        }
    }
    
    const half3 out = saturate(lap * gain);
    outputTexture.write(half4(out.rgb, 1.0h), gid);
}

kernel void laplacianSharpen(texture2d<half, access::read> inputTexture [[texture(0)]],
                             texture2d<half, access::read> laplacianTexture [[texture(1)]],
                             texture2d<half, access::write> outputTexture [[texture(2)]],
                             uint2 gid [[thread_position_in_grid]],
                             constant float& amount [[buffer(0)]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    const half4 inputColor = inputTexture.read(gid);
    const half lapColor = laplacianTexture.read(gid).r;
    const half3 out = saturate(inputColor.rgb - (amount * lapColor));
    outputTexture.write(half4(out, inputColor.a), gid);
}

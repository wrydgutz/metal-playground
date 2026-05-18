//
//  Sobel.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//
// Sobel Edge Detection
//
// Detects edges by measuring how rapidly pixel intensity changes horizontally and vertically.
// The image is first converted to grayscale, then two convolution kernels are applied.
//
// See Sobel.md for full notes.
//

#include <metal_stdlib>
using namespace metal;

#include "Helpers.h"

// K = [ -1, 0, 1 ]
//     [ -2, 0, 2 ]
//     [ -1, 0, 1 ]
template <class T>
inline T sobelEdgeDetectionHorizontalKernel(const int2 offset) {
    if (offset.x == 0) return T(0);
    else {
        if (offset.y == 0) return offset.x < 0 ? T(-2) : T(2);
        else return offset.x < 0 ? T(-1) : T(1);
    }
}

// K = [ -1, -2, -1 ]
//     [  0,  0,  0 ]
//     [  1,  2,  1 ]
template <class T>
inline T sobelEdgeDetectionVerticalKernel(const int2 offset) {
    if (offset.y == 0) return T(0);
    else {
        if (offset.x == 0) return offset.y < 0 ? T(-2) : T(2);
        else return offset.y < 0 ? T(-1) : T(1);
    }
}


// MARK: Compute Kernels
kernel void sobelEdgeDetection(texture2d<half, access::read> inputTexture [[texture(0)]],
                               texture2d<half, access::write> outputTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    
    if (isOutOfBounds(outputTexture, gid)) return;
    
    half3 colorSumHorizontal = half3(0);
    half3 colorSumVertical = half3(0);
    
    const int2 base = (int2)gid;
    const int2 size = int2((int)inputTexture.get_width() - 1, (int)inputTexture.get_height() - 1);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            const int2 offset = int2(i, j);
            const int2 pixelPos = clamp(base + offset, int2(0), size);
            const half3 gray = luminanceRec601<half>(inputTexture.read((uint2)pixelPos).rgb);
            colorSumHorizontal += gray * sobelEdgeDetectionHorizontalKernel<half>(offset);
            colorSumVertical += gray * sobelEdgeDetectionVerticalKernel<half>(offset);
        }
    }
    
    const half3 colorSumHSquared = colorSumHorizontal * colorSumHorizontal;
    const half3 colorSumVSquared = colorSumVertical * colorSumVertical;
    const half3 out = sqrt(colorSumHSquared + colorSumVSquared);
    
    outputTexture.write(half4(out, 1.0), gid);
}

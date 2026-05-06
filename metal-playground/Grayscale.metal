//
//  Grayscale.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Grayscale Compute Kernel
kernel void grayscale(texture2d<half, access::read> inputTexture [[texture(0)]],
                      texture2d<half, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {

    // Guard against out-of-bounds writes.
    if (gid.x >= outputTexture.get_width() ||
        gid.y >= outputTexture.get_height()) {
        return;
    }
    
    half4 colorValue = inputTexture.read(gid);
    half gray = dot(colorValue.rgb, half3(0.299f, 0.587f, 0.114f)); // Rec.601
    outputTexture.write(half4(gray, gray, gray, colorValue.a), gid);
}

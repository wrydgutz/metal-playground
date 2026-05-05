//
//  grayscale.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

#include <metal_stdlib>
using namespace metal;

kernel void grayscale(texture2d<float, access::read> inputTexture [[texture(0)]],
                      texture2d<float, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outputTexture.get_width() ||
        gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 colorValue = inputTexture.read(gid);
    float gray = colorValue.r * 0.299 + colorValue.g * 0.587 + colorValue.b * 0.114;
    outputTexture.write(float4(gray, gray, gray, 1.0f), gid);
}

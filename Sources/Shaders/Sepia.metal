//
//  Sepia.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 7/5/26.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Sepia Compute Kernel
kernel void sepia(texture2d<half, access::read> inputTexture [[texture(0)]],
                  texture2d<half, access::write> outputTexture [[texture(1)]],
                  uint2 gid [[thread_position_in_grid]]) {

    // Guard against out-of-bounds writes.
    if (gid.x >= outputTexture.get_width() ||
        gid.y >= outputTexture.get_height()) {
        return;
    }
    
    half4 colorValue = inputTexture.read(gid);
    half dotR = dot(colorValue.rgb, half3(0.393, 0.769, 0.189));
    half dotG = dot(colorValue.rgb, half3(0.349,0.686,0.168));
    half dotB = dot(colorValue.rgb, half3(0.272,0.534,0.131));
    half3 out = saturate(half3(dotR, dotG, dotB));
    
    outputTexture.write(half4(out, colorValue.a), gid);
}

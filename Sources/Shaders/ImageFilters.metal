//
//  ImageFilters.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 8/5/26.
//

#include <metal_stdlib>
using namespace metal;

#include "Helpers.h"

// MARK: - Grayscale Compute Kernel
kernel void grayscale(texture2d<half, access::read> inputTexture [[texture(0)]],
                      texture2d<half, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half gray = luminanceRec601<half>(colorValue.rgb);
    outputTexture.write(half4(gray, gray, gray, colorValue.a), gid);
}

// MARK: - Sepia Compute Kernel
kernel void sepia(texture2d<half, access::read> inputTexture [[texture(0)]],
                  texture2d<half, access::write> outputTexture [[texture(1)]],
                  uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half dotR = dot(colorValue.rgb, half3(0.393, 0.769, 0.189));
    half dotG = dot(colorValue.rgb, half3(0.349,0.686,0.168));
    half dotB = dot(colorValue.rgb, half3(0.272,0.534,0.131));
    half3 out = saturate(half3(dotR, dotG, dotB));
    
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Invert Compute Kernel
kernel void invert(texture2d<half, access::read> inputTexture [[texture(0)]],
                   texture2d<half, access::write> outputTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 out = 1 - colorValue.rgb;
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Brightness Compute Kernel
kernel void brightness(texture2d<half, access::read> inputTexture [[texture(0)]],
                       texture2d<half, access::write> outputTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]],
                       constant float& brightness [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 out = saturate(colorValue.rgb + half3(brightness));
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Contrast Compute Kernel
kernel void contrast(texture2d<half, access::read> inputTexture [[texture(0)]],
                     texture2d<half, access::write> outputTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]],
                     constant float& contrast [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half3 pointFive = half3(0.5);
    half3 out = saturate(((colorValue.rgb - pointFive) * contrast) + pointFive);
    outputTexture.write(half4(out, colorValue.a), gid);
}

// MARK: - Threshold Compute Kernel
kernel void threshold(texture2d<half, access::read> inputTexture [[texture(0)]],
                     texture2d<half, access::write> outputTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]],
                     constant float& factor [[buffer(0)]]) {

    if (isOutOfBounds(outputTexture, gid)) return;
    
    half4 colorValue = inputTexture.read(gid);
    half gray = luminanceRec601<half>(colorValue.rgb);
    half color = gray >= factor ? 1.0 : 0.0;
    outputTexture.write(half4(color, color, color, colorValue.a), gid);
}

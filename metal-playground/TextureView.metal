//
//  textureView.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 6/5/26.
//

#include <metal_stdlib>
using namespace metal;

struct VertexData {
    vector_float2 positionPixels;
    vector_float2 textureCoordinate;
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut textureViewVertex(const device VertexData* vertices [[buffer(0)]],
                                   constant vector_uint2& viewportSize [[buffer(1)]],
                                   uint vertexID [[vertex_id]]) {
    VertexOut out;
    float2 pixelPos = vertices[vertexID].positionPixels.xy;
    out.position = float4(pixelPos / (float2(viewportSize) / 2.0f), 0.0f, 1.0f);
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    return out;
}

fragment float4 textureViewFragment(VertexOut in [[stage_in]],
                                    texture2d<half> sourceTexture [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 sample = sourceTexture.sample(textureSampler, in.textureCoordinate);
    return float4(sample);
}

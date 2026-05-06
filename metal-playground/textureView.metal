//
//  textureView.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 6/5/26.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    // Positions in pixel space. A value of 100 indicates 100 pixels from the origin/center.
    vector_float2 position;

    // 2D texture coordinate
    vector_float2 textureCoordinate;
} VertexData;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut textureView_vertex(
    const device VertexData* vertices [[buffer(0)]],
    const device vector_uint2* viewportSize [[buffer(1)]],
    uint vertexID [[vertex_id]]
) {
    VertexOut out;
    float2 pixelPos = vertices[vertexID].position.xy;
    float2 viewportSizeFloat = float2(*viewportSize);
    out.position = vector_float4(0.0f, 0.0f, 0.0f, 1.0f);
    out.position.xy = pixelPos / (viewportSizeFloat / 2.0f);
    out.texCoord = vertices[vertexID].textureCoordinate;
    return out;
}

fragment float4 textureView_fragment(
    VertexOut in [[stage_in]],
    texture2d<half> texture [[texture(0)]]
) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    const half4 sample = texture.sample(textureSampler, in.texCoord);
    return float4(sample);
}

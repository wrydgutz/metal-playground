//
//  TextureView.metal
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 6/5/26.
//
//
// This file implements a minimal "textured quad" pipeline:
// - The CPU supplies a list of vertices (position in pixels + UV coordinates).
// - The vertex shader converts pixel coordinates into clip space (NDC).
// - The fragment shader samples a texture using the interpolated UVs.

#include <metal_stdlib>
using namespace metal;

// MARK: - Data Types

struct VertexData {
    // Position in pixel space, centered at the drawable's center.
    vector_float2 positionPixels;

    // Normalized texture coordinates (UV) in the range [0,1].
    vector_float2 textureCoordinate;
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

// MARK: - Vertex Shader
// Converts a list of per-vertex inputs into clip space (NDC).
vertex VertexOut textureViewVertex(const device VertexData* vertices [[buffer(0)]],
                                   constant vector_uint2& viewportSize [[buffer(1)]],
                                   uint vertexID [[vertex_id]]) {
    VertexOut out;

    // Read the CPU-provided pixel-space position for this vertex.
    float2 pixelPos = vertices[vertexID].positionPixels.xy;

    // Convert from pixel space to Normalized Device Coordinates (NDC).
    //
    // If viewportSize is (W,H):
    // - Pixel x = +/- (W/2) maps to NDC x = +/- 1
    // - Pixel y = +/- (H/2) maps to NDC y = +/- 1
    //
    // Because our pixel coordinate system is centered, we just divide by (viewport/2).
    float2 ndc = pixelPos / (float2(viewportSize) / 2.0f);
    out.position = float4(ndc, 0.0f, 1.0f);

    // Forward the per-vertex UV to the fragment shader (interpolated).
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    return out;
}

// MARK: - Fragment Shader
// Samples a 2D texture using normalized UVs.
fragment float4 textureViewFragment(VertexOut in [[stage_in]],
                                    texture2d<half> sourceTexture [[texture(0)]]) {
    // Compile-time sampler state.
    // - mag_filter::linear: smooth when scaling up
    // - min_filter::linear: smooth when scaling down (without mipmaps)
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);

    // Sample the texture at the interpolated UV coordinate.
    const half4 sample = sourceTexture.sample(textureSampler, in.textureCoordinate);
    return float4(sample);
}

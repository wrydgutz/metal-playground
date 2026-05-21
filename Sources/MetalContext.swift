//
//  MetalContext.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import Metal

enum ComputeKernel: String {
    case original
    case grayscale
    case sepia
    case invert
    case brightness
    case contrast
    case threshold
    case boxBlur
    case boxBlurTwoPassHorizontal
    case boxBlurTwoPassVertical
    case gaussianBlur
    case gaussianBlurTwoPassHorizontal
    case gaussianBlurTwoPassVertical
    case sharpen
    case sobelEdgeDetection
    case emboss
}

enum RenderKernel: String {
    case textureView
}

final class MetalContext {
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    
    private var computePipelineStates = [ComputeKernel:MTLComputePipelineState]()
    private var renderPipelineStates = [RenderKernel:MTLRenderPipelineState]()
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default library")
        }

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }
        
        self.device = device
        self.library = library
        self.commandQueue = commandQueue
    }
    
    func computePipelineState(for kernel: ComputeKernel) throws -> MTLComputePipelineState {
        if let pso = computePipelineStates[kernel] { return pso }
        
        guard let function = library.makeFunction(name: kernel.rawValue) else {
            fatalError("Could not load function '\(kernel.rawValue)'")
        }
        
        let pso = try device.makeComputePipelineState(function: function)
        computePipelineStates[kernel] = pso
        return pso
    }
    
    func renderPipelineState(for kernel: RenderKernel) throws -> MTLRenderPipelineState {
        if let pso = renderPipelineStates[kernel] { return pso }
        
        guard let vertexFunction = library.makeFunction(name: "\(kernel.rawValue)Vertex") else {
            fatalError("Could not vertex function for \(kernel.rawValue)")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "\(kernel.rawValue)Fragment") else {
            fatalError("Could not fragment function for \(kernel.rawValue)")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let pso = try device.makeRenderPipelineState(descriptor: descriptor)
        renderPipelineStates[kernel] = pso
        return pso
    }
    
    static func encodeComputePass(pipelineState: MTLComputePipelineState,
                                  commandBuffer: MTLCommandBuffer,
                                  threadgroupsPerGrid: MTLSize,
                                  threadsPerThreadgroup: MTLSize,
                                  setArgs: (MTLComputeCommandEncoder) -> Void) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(pipelineState)
        setArgs(computeEncoder)
        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
    }
    
    static let defaultThreadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
    
    static func threadgroupsPerGridForFullCoverage(inputTexture: MTLTexture,
                                                   threadsPerThreadgroup: MTLSize = MetalContext.defaultThreadsPerThreadgroup) -> MTLSize {
        MTLSize(
            width: (inputTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: (inputTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
            depth: 1
        )
    }
}

extension MetalContext {
    
    /// Mirrors `TextureView.metal`'s `VertexData`.
    struct TextureViewVertexData {
        let positionPixels: SIMD2<Float>
        let textureCoordinate: SIMD2<Float>
    }
}

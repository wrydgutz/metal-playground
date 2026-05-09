//
//  MetalContext.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import Metal

final class MetalContext {
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    
    lazy var pipelineStateObjects: PipelineStateObjects = {
        PipelineStateObjects(device: device, library: library)
    }()
    
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
}

extension MetalContext {
    
    final class PipelineStateObjects {
        
        let device: MTLDevice
        let library: MTLLibrary
        
        init(device: MTLDevice, library: MTLLibrary) {
            self.device = device
            self.library = library
        }
        
        // MARK: Compute Pipelines
        private var cachedGrayscale: MTLComputePipelineState?
        func grayscale() throws -> MTLComputePipelineState {
            try computePSO(cached: &cachedGrayscale, name: "grayscale")
        }
        
        private var cachedSepia: MTLComputePipelineState?
        func sepia() throws -> MTLComputePipelineState {
            try computePSO(cached: &cachedSepia, name: "sepia")
        }
        
        private var cachedInvert: MTLComputePipelineState?
        func invert() throws -> MTLComputePipelineState {
            try computePSO(cached: &cachedInvert, name: "invert")
        }
        
        private var cachedBrightness: MTLComputePipelineState?
        func brightness() throws -> MTLComputePipelineState {
            try computePSO(cached: &cachedBrightness, name: "brightness")
        }
        
        private func computePSO(
            cached: inout MTLComputePipelineState?,
            name: String
        ) throws -> MTLComputePipelineState {
            if let cached = cached { return cached }
            
            guard let function = library.makeFunction(name: name) else {
                fatalError("Could not load function '\(name)'")
            }
            
            let pso = try device.makeComputePipelineState(function: function)
            cached = pso
            return pso
        }
        
        
        // MARK: Render Pipelines
        private var cachedTextureView: MTLRenderPipelineState?
        func textureView() throws -> MTLRenderPipelineState {
            if let cachedTextureView = cachedTextureView { return cachedTextureView }
            
            guard let vertexFunction = library.makeFunction(name: "textureViewVertex"),
                  let fragmentFunction = library.makeFunction(name: "textureViewFragment") else {
                fatalError("Could not load functions for texture view")
            }
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            let textureView = try device.makeRenderPipelineState(descriptor: descriptor)
            cachedTextureView = textureView
            return textureView
        }
    }
    
    /// Mirrors `TextureView.metal`'s `VertexData`.
    struct TextureViewVertexData {
        let positionPixels: SIMD2<Float>
        let textureCoordinate: SIMD2<Float>
    }
}

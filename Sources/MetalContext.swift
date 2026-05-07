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
            if let cachedGrayscale = cachedGrayscale { return cachedGrayscale }
            
            guard let function = library.makeFunction(name: "grayscale") else {
                fatalError("Could not load function 'grayscale'")
            }
            
            let grayscale = try device.makeComputePipelineState(function: function)
            cachedGrayscale = grayscale
            return grayscale
        }
        
        private var cachedSepia: MTLComputePipelineState?
        func sepia() throws -> MTLComputePipelineState {
            if let cachedSepia = cachedSepia { return cachedSepia }
            
            guard let function = library.makeFunction(name: "sepia") else {
                fatalError("Could not load function 'sepia'")
            }
            
            let sepia = try device.makeComputePipelineState(function: function)
            cachedSepia = sepia
            return sepia
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

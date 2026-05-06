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
    
    var pipelineStateObjects: PipelineStateObjects {
        .init(metalContext: self)
    }
    
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
        
        let metalContext: MetalContext
        
        init(metalContext: MetalContext) {
            self.metalContext = metalContext
        }
        
        var grayscale: MTLComputePipelineState {
            get throws {
                guard let function = metalContext.library.makeFunction(name: "grayscale") else {
                    fatalError("Could not load function 'grayscale'")
                }
                
                return try metalContext.device.makeComputePipelineState(function: function)
            }
        }
        
        var textureView: MTLRenderPipelineState {
            get throws {
                guard let vertexFunction = metalContext.library.makeFunction(name: "textureViewVertex"),
                      let fragmentFunction = metalContext.library.makeFunction(name: "textureViewFragment") else {
                    fatalError("Could not load functions for texture view")
                }
                
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = vertexFunction
                descriptor.fragmentFunction = fragmentFunction
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                
                return try metalContext.device.makeRenderPipelineState(descriptor: descriptor)
            }
        }
    }
    
    /// Mirrors `TextureView.metal`'s `VertexData`.
    struct TextureViewVertexData {
        let positionPixels: SIMD2<Float>
        let textureCoordinate: SIMD2<Float>
    }
}
